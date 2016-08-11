xquery version "1.0-ml";

module namespace walker = "http://marklogic.com/ns/json-tree-walker";

declare option xdmp:mapping "false";

declare %private function walker:_walk-json($nodes as node()*, $o as json:object?, $visitor-func as function(*)) {

  (:
   :  This closure handles some of the boilerplate of calling the visitor
   :  It merely exists to keep the rest of this function cleaner
   :)
  let $call-visitor := function($key, $value) {
    let $response-map := map:new((
      map:entry("key", $key),
      map:entry("value", $value)
    ))
    let $_ := $visitor-func($key, $value, $response-map)
    return $response-map
  }

  for $n in $nodes
  (: if this node has a name then turn it into a string. This is the json key.
   : We use the ! operator to conditionally assign the string. If no node name exists
   : then $key will be the empty sequence
   : See https://developer.marklogic.com/blog/simple-mapping-operator for more details on !
   :)
  let $key := fn:node-name($n) ! fn:string(.)
  return
    typeswitch($n)
      case document-node() return
        (: if it's a document node then start with the root node :)
        walker:_walk-json($n/node(), $o, $visitor-func)
      case object-node() return
        (: create an in-memory json object :)
        let $oo := json:object()

        (: recursively walk every child of this object and put
           them into our json object :)
        let $_ := walker:_walk-json($n/node(), $oo, $visitor-func)

        (: give our visitor function a chance to alter the key or value :)
        let $r := $call-visitor($key, $oo)
        let $key := map:get($r, "key")
        let $value := map:get($r, "value")
        return
          (: any non-root object will have a name :)
          if ($key and fn:exists($o) and fn:exists($value)) then
            ( map:put($o, $key, $value), $o )
          (: return the new object :)
          else
            $value
      case array-node() return
        (: create an in-memory json array to hold the values :)
        let $aa := json:to-array(walker:_walk-json($n/node(), (), $visitor-func))

        (: give our visitor function a chance to alter the key or value :)
        let $r := $call-visitor($key, $aa)
        let $key := map:get($r, "key")
        let $value := map:get($r, "value")
        return
          if (fn:exists($o) and fn:exists($value)) then
            ( map:put($o, $key, $value), $o )
          else
            $value
      case number-node() |
           boolean-node() |
           null-node() |
           text() return

        (: give our visitor function a chance to alter the key or value :)
        let $r := $call-visitor($key, $n)
        let $key := map:get($r, "key")
        let $value := map:get($r, "value")
        return
          if (fn:exists($o) and fn:exists($value)) then
            ( map:put($o, $key, $value), $o )
          else
            $value
      (: this is our failsafe in case we missed something :)
      default return
        $n
};

(:~
 : The public entry point for this library
 :
 : @param $nodes - the nodes to walk
 : @param $visitor-func - a closure to call when a node is visited
 :
 : @return - the transformed json
 :)
declare function walker:walk-json($nodes as node()*, $visitor-func as function(*))
{
  walker:_walk-json($nodes, (), $visitor-func)
};

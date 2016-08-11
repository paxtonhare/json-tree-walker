# JSON Tree Walker

For more information see the [blog post about this library](https://developer.marklogic.com/blog/walking-among-the-json-trees).

This library provides a function to walk a JSON tree. You simply provide the JSON object and a visitor callback function matching this signature:

```xquery
  (:
   : The visitor function signature
   : @param $key - the key of the visited JSON node or () if no key
   : @param $value - the value of the visited JSON node or () if no value
   : @param $output - a map object that contains 2 keys: "key" and "value"
   :
   : This method is called for each node on the JSON tree as it is visited.
   : Simply populate the $output map with any modifications you wish to make
   : to the key or value
   :)
  function($key, $value, $output)
```

# Example Usages

An Example no-op. This simply makes a copy of the JSON tree.

```xquery
import module namespace walker = "http://marklogic.com/ns/json-tree-walker"
  at "/path/to/tree-walker.xqy";

let $doc := fn:doc('/path/to/some.json')
return
  walker:walk-json($doc, function($key, $value, $output) {
    ()
  })
```

Another no-op. This time with stubs to determine node types.

```xquery
import module namespace walker = "http://marklogic.com/ns/json-tree-walker"
  at "/path/to/tree-walker.xqy";

let $doc := fn:doc('/path/to/some.json')
return
  walker:walk-json($doc, function($key, $value, $output) {
    if ($value instance of json:object) then
      ()
    else if ($value instance of json:array) then
      ()
    else if ($value instance of number-node()) then
      ()
    else if ($value instance of boolean-node()) then
      ()
    else if ($value instance of null-node()) then
      ()
    else
      ()
  })
```

An implementation that alters many parts.

```xquery
import module namespace walker = "http://marklogic.com/ns/json-tree-walker"
  at "/path/to/tree-walker.xqy";

let $doc := fn:doc('/path/to/some.json')
return
  walker:walk-json($doc, function($key, $value, $output) {
    if ($value instance of json:object) then
      (: upcase all object keys :)
      map:put($output, "key", fn:upper-case($key))
    else if ($value instance of json:array) then
      (: reverse every array :)
      map:put($output, "value", json:to-array(fn:reverse(json:array-values($value))))
    else if ($value instance of number-node()) then
      (: negate any number :)
      map:put($output, "value", -$value)
    else if ($value instance of boolean-node()) then
      (: invert any boolean :)
      map:put($output, "value", fn:not(xs:boolean($value)))
    else if ($value instance of null-node()) then
      (: omit nulls by returning the empty sequence for the value :)
      map:put($output, "value", ())
    else
      map:put($output, "value", $value)
  })
```

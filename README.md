# jmespath - A JMESPath implementation in dart

jmespath is a dart implementation of JMESPath,
which is a query language for JSON.  It will take a JSON
document and transform it into another JSON document
through a JMESPath expression.

This project is derived from the go port of the JMESPATH,
[go-jmespath](https://github.com/jmespath/go-jmespath)

Using go-jmespath is really easy.  There's a single function
you use, `jmespath.search`:

```dart
> import 'package:jmespath/jmespath.dart';
>
> var jsondata = r'{"foo": {"bar": {"baz": [0, 1, 2, 3, 4]}}}';
> var data = json.decode(jsondata);
> var search_string = 'foo.bar.baz[2]';
> var result = search(search_string, data);
> print('example1 search $search_string , result = $result');
example1 search foo.bar.baz[2] , result = 2
```

In the example we gave the ``search`` function input data of
`{"foo": {"bar": {"baz": [0, 1, 2, 3, 4]}}}` as well as the JMESPath
expression `foo.bar.baz[2]`, and the `search` function evaluated
the expression against the input data to produce the result ``2``.

The JMESPath language can do a lot more than select an element
from a list.  Here are a few more examples:

```dart
> var jsondata = r'{"foo": {"bar": {"baz": [0, 1, 2, 3, 4]}}}';
> var data = json.decode(jsondata);
> var search_string = 'foo.bar';
> var result = search(search_string, data);
> print('example2 search $search_string , result = $result');
example2 search foo.bar , result = {baz: [0, 1, 2, 3, 4]}


> var jsondata =
>     r'{"foo": [{"first": "a", "last": "b"}, {"first": "c", "last": "d"}]}';
> var data = json.decode(jsondata);
> var search_string = 'foo[*].first';
> var result = search(search_string, data);
> print('example3 search $search_string , result = $result');
example3 search foo[*].first , result = [a, c]


> var jsondata =
>     r'{"foo": [{"age": 20}, {"age": 25}, {"age": 30}, {"age": 35}, {"age": 40}]}';
> var data = json.decode(jsondata);
> var search_string = 'foo[?age > `30`]';
> var result = search(search_string, data);
> print('example4 search $search_string , result = $result');
example4 search foo[?age > `30`] , result = [{age: 35}, {age: 40}]
```

You can also pre-compile your query. This is usefull if
you are going to run multiple searches with it:

```dart
> var search_string = 'foo.bar';
> var jmespath = Jmespath.compile('foo.bar');

> var jsondata1 = r'{"foo": {"bar": "hello"}}';
> var data1 = json.decode(jsondata1);
> var result1 = jmespath.search(data1);
> print('example5 search $search_string , result for data1 = $result1');
example5 search foo.bar , result for data1 = hello

> var jsondata2 = r'{"foo": {"bar": "world"}}';
> var data2 = json.decode(jsondata2);
> var result2 = jmespath.search(data2);
> print('example5 search $search_string , result for data2 = $result2');
example5 search foo.bar , result for data2 = world
```

## Exception Handling

All the functions in the library throw exception whose base class
is ``JmesException``. You can handle errors as follows :

```dart
> var jsondata = r'{"foo": {"bar": "hello"}}';
> var data = json.decode(jsondata);
> var search_string = 'avg(foo.bar)';
> try {
>   var result = search(search_string, data);
>   print('example6 search $search_string , result = $result');
> } on JmesException catch (e) {
>   print('example6 search $search_string , got exception ${e.message}');
> }
example6 search avg(foo.bar) , got exception Invalid type for hello, expected [jpType.jpArrayNumber]
```

## More Resources

The example above only show a small amount of what
a JMESPath expression can do.  If you want to take a
tour of the language, the *best* place to go is the
[JMESPath Tutorial](http://jmespath.org/tutorial.html).

One of the best things about JMESPath is that it is
implemented in many different programming languages including
python, ruby, php, lua, etc.  To see a complete list of libraries,
check out the [JMESPath libraries page](http://jmespath.org/libraries.html).

And finally, the full JMESPath specification can be found
on the [JMESPath site](http://jmespath.org/specification.html).

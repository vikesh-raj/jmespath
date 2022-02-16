import 'package:jmespath/jmespath.dart';
import 'dart:convert';

void main() {
  example1();
  example2();
  example3();
  example4();
  example5();
  example6();
}

void example1() {
  var jsondata = r'{"foo": {"bar": {"baz": [0, 1, 2, 3, 4]}}}';
  var data = json.decode(jsondata);
  var searchString = 'foo.bar.baz[2]';
  var result = search(searchString, data);
  print('example1 search $searchString , result = $result');
}

void example2() {
  var jsondata = r'{"foo": {"bar": {"baz": [0, 1, 2, 3, 4]}}}';
  var data = json.decode(jsondata);
  var searchString = 'foo.bar';
  var result = search(searchString, data);
  print('example2 search $searchString , result = $result');
}

void example3() {
  var jsondata =
      r'{"foo": [{"first": "a", "last": "b"}, {"first": "c", "last": "d"}]}';
  var data = json.decode(jsondata);
  var searchString = 'foo[*].first';
  var result = search(searchString, data);
  print('example3 search $searchString , result = $result');
}

void example4() {
  var jsondata =
      r'{"foo": [{"age": 20}, {"age": 25}, {"age": 30}, {"age": 35}, {"age": 40}]}';
  var data = json.decode(jsondata);
  var searchString = 'foo[?age > `30`]';
  var result = search(searchString, data);
  print('example4 search $searchString , result = $result');
}

void example5() {
  // Precompile the search string.
  var searchString = 'foo.bar';
  var jmespath = Jmespath.compile('foo.bar');

  var jsondata1 = r'{"foo": {"bar": "hello"}}';
  var data1 = json.decode(jsondata1);
  var result1 = jmespath.search(data1);
  print('example5 search $searchString , result for data1 = $result1');

  var jsondata2 = r'{"foo": {"bar": "world"}}';
  var data2 = json.decode(jsondata2);
  var result2 = jmespath.search(data2);
  print('example5 search $searchString , result for data2 = $result2');
}

void example6() {
  var jsondata = r'{"foo": {"bar": "hello"}}';
  var data = json.decode(jsondata);
  var searchString = 'avg(foo.bar)';
  try {
    var result = search(searchString, data);
    print('example6 search $searchString , result = $result');
  } on JmesException catch (e) {
    print('example6 search $searchString , got exception ${e.message}');
  }
}

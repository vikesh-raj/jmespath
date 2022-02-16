import 'package:jmespath/src/api.dart';
import 'package:test/test.dart';
import 'dart:convert';


void main() {

  test('basic test', () {
    var jsondata = r'{"foo": {"bar": {"baz": [0, 1, 2, 3, 4]}}}';
    var data = json.decode(jsondata);
    var searchString = 'foo.bar.baz[2]';
    var result = search(searchString, data);
    expect(result, 2);
  });

  test('compile test', () {
    var jsondata1 = r'{"foo": {"bar": {"baz": [0, 1, 2, 3, 4]}}}';
    var jsondata2 = r'{"foo": {"bar": {"baz": [4, 5, 6]}}}';
    var data1 = json.decode(jsondata1);
    var data2 = json.decode(jsondata2);
    var jms = Jmespath.compile('foo.bar.baz[2]');
    expect(jms.search(data1), 2);
    expect(jms.search(data2), 6);
  });
}

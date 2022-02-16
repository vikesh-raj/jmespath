import 'package:jmespath/src/parser.dart';
import 'package:test/test.dart';

class TestCase {
  String expression;
  String pretty;

  TestCase(this.expression, this.pretty);
}

void main() {
  var tests = [
    TestCase('foo', 'ast.field { value:foo }'),
    TestCase(
        'foo.bar',
        'ast.subexpression {'
            '  children : {'
            '    ast.field { value:foo }'
            '    ast.field { value:bar }'
            '}'),
  ];
  test('parser tests', () {
    for (var it in tests) {
      var ast = parse(it.expression);
      var toStr = ast.toString().replaceAll('\n', '').replaceAll(' ', '');
      var exp = it.pretty.replaceAll('\n', '').replaceAll(' ', '');
      expect(toStr, equals(exp));
    }
  });
}

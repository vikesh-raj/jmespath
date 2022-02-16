import 'package:jmespath/src/errors.dart';
import 'package:test/test.dart';


void main() {

  test('check to string', () {
    var exp = JmesException('Got Error');
    expect(exp.toString(), 'JmesException: Got Error');
  });

  test('syntax exception', () {
    var exp = SyntaxException(message: 'Syntax Error', expression: '^^^', offset: 1);
    expect(exp.toString(), 'SyntaxException: Error while parsing ^^^ at 1 : Syntax Error');
  });
}

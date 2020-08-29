import 'package:jmespath/src/util.dart';
import 'package:test/test.dart';

void main() {
  test('is value false', () {
    expect(isValueFalse(null), true);
    expect(isValueFalse(''), true);
    expect(isValueFalse(0), false);
    expect(isValueFalse(0.0), false);
    expect(isValueFalse(false), true);
    expect(isValueFalse(true), false);
    expect(isValueFalse(1), false);
    expect(isValueFalse([]), true);
    expect(isValueFalse([1]), false);
    expect(isValueFalse(<String, dynamic>{}), true);
    expect(isValueFalse(<String, dynamic>{'hello': 1}), false);
  });
}

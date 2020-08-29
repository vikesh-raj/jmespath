import 'package:jmespath/src/lex.dart';
import 'package:test/test.dart';

class testcase {
  String expression;
  List<token> tokens;

  testcase(this.expression, this.tokens);
}

void main() {
  var tests = [
    testcase('*', [token(tt.tStar, '*', 0)]),
    testcase('.', [token(tt.tDot, '.', 0)]),
    testcase('[?', [token(tt.tFilter, '[?', 0)]),
    testcase('[]', [token(tt.tFlatten, '[]', 0)]),
    testcase('(', [token(tt.tLparen, '(', 0)]),
    testcase(')', [token(tt.tRparen, ')', 0)]),
    testcase('[', [token(tt.tLbracket, '[', 0)]),
    testcase(']', [token(tt.tRbracket, ']', 0)]),
    testcase('{', [token(tt.tLbrace, '{', 0)]),
    testcase('}', [token(tt.tRbrace, '}', 0)]),
    testcase('||', [token(tt.tOr, '||', 0)]),
    testcase('|', [token(tt.tPipe, '|', 0)]),
    testcase('29', [token(tt.tNumber, '29', 0)]),
    testcase('2', [token(tt.tNumber, '2', 0)]),
    testcase('0', [token(tt.tNumber, '0', 0)]),
    testcase('-20', [token(tt.tNumber, '-20', 0)]),
    testcase('foo', [token(tt.tUnquotedIdentifier, 'foo', 0)]),
    testcase('"bar"', [token(tt.tQuotedIdentifier, 'bar', 0)]),
    // Escaping the delimiter
    testcase(r'"bar\"baz"', [token(tt.tQuotedIdentifier, 'bar"baz', 0)]),
    testcase(',', [token(tt.tComma, ',', 0)]),
    testcase(':', [token(tt.tColon, ':', 0)]),
    testcase('<', [token(tt.tLT, '<', 0)]),
    testcase('<=', [token(tt.tLTE, '<=', 0)]),
    testcase('>', [token(tt.tGT, '>', 0)]),
    testcase('>=', [token(tt.tGTE, '>=', 0)]),
    testcase('==', [token(tt.tEQ, '==', 0)]),
    testcase('!=', [token(tt.tNE, '!=', 0)]),
    testcase(r'`[0, 1, 2]`', [token(tt.tJSONLiteral, '[0, 1, 2]', 1)]),
    testcase(r"'foo'", [token(tt.tStringLiteral, 'foo', 1)]),
    testcase(r"'a'", [token(tt.tStringLiteral, 'a', 1)]),
    testcase(r"'foo\'bar'", [token(tt.tStringLiteral, "foo'bar", 1)]),
    testcase('@', [token(tt.tCurrent, '@', 0)]),
    testcase('&', [token(tt.tExpref, '&', 0)]),
    testcase('"\u2713"', [token(tt.tQuotedIdentifier, '✓', 0)]),
    testcase(r"'\\u03a6'", [token(tt.tStringLiteral, r'\\u03a6', 1)]),
    // Quoted identifier unicode escape sequences
    testcase(r'"\\"', [token(tt.tQuotedIdentifier, r'\', 0)]),
    // Combinations of tokens.
    testcase('foo.bar', [
      token(tt.tUnquotedIdentifier, 'foo', 0),
      token(tt.tDot, '.', 3),
      token(tt.tUnquotedIdentifier, 'bar', 4)
    ]),
    testcase('foo[0]', [
      token(tt.tUnquotedIdentifier, 'foo', 0),
      token(tt.tLbracket, '[', 3),
      token(tt.tNumber, '0', 4),
      token(tt.tRbracket, ']', 5),
    ]),
    testcase('foo[?a<b]', [
      token(tt.tUnquotedIdentifier, 'foo', 0),
      token(tt.tFilter, '[?', 3),
      token(tt.tUnquotedIdentifier, 'a', 5),
      token(tt.tLT, '<', 6),
      token(tt.tUnquotedIdentifier, 'b', 7),
      token(tt.tRbracket, ']', 8),
    ]),
    testcase('foo."1"[0]', [
      token(tt.tUnquotedIdentifier, 'foo', 0),
      token(tt.tDot, '.', 3),
      token(tt.tQuotedIdentifier, '1', 4),
      token(tt.tLbracket, '[', 7),
      token(tt.tNumber, '0', 8),
      token(tt.tRbracket, ']', 9),
    ])
  ];
  test('lex tests', () {
    for (var it in tests) {
      var tokens = tokenize(it.expression);
      it.tokens.add(token(tt.tEOF, '', it.expression.length));
      expect(tokens, equals(it.tokens));
    }
  });
}

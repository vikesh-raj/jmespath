import 'package:jmespath/src/lex.dart';
import 'package:test/test.dart';

class TestCase {
  String expression;
  List<Token> tokens;

  TestCase(this.expression, this.tokens);
}

void main() {
  var tests = [
    TestCase('*', [Token(tt.tStar, '*', 0)]),
    TestCase('.', [Token(tt.tDot, '.', 0)]),
    TestCase('[?', [Token(tt.tFilter, '[?', 0)]),
    TestCase('[]', [Token(tt.tFlatten, '[]', 0)]),
    TestCase('(', [Token(tt.tLparen, '(', 0)]),
    TestCase(')', [Token(tt.tRparen, ')', 0)]),
    TestCase('[', [Token(tt.tLbracket, '[', 0)]),
    TestCase(']', [Token(tt.tRbracket, ']', 0)]),
    TestCase('{', [Token(tt.tLbrace, '{', 0)]),
    TestCase('}', [Token(tt.tRbrace, '}', 0)]),
    TestCase('||', [Token(tt.tOr, '||', 0)]),
    TestCase('|', [Token(tt.tPipe, '|', 0)]),
    TestCase('29', [Token(tt.tNumber, '29', 0)]),
    TestCase('2', [Token(tt.tNumber, '2', 0)]),
    TestCase('0', [Token(tt.tNumber, '0', 0)]),
    TestCase('-20', [Token(tt.tNumber, '-20', 0)]),
    TestCase('foo', [Token(tt.tUnquotedIdentifier, 'foo', 0)]),
    TestCase('"bar"', [Token(tt.tQuotedIdentifier, 'bar', 0)]),
    // Escaping the delimiter
    TestCase(r'"bar\"baz"', [Token(tt.tQuotedIdentifier, 'bar"baz', 0)]),
    TestCase(',', [Token(tt.tComma, ',', 0)]),
    TestCase(':', [Token(tt.tColon, ':', 0)]),
    TestCase('<', [Token(tt.tLT, '<', 0)]),
    TestCase('<=', [Token(tt.tLTE, '<=', 0)]),
    TestCase('>', [Token(tt.tGT, '>', 0)]),
    TestCase('>=', [Token(tt.tGTE, '>=', 0)]),
    TestCase('==', [Token(tt.tEQ, '==', 0)]),
    TestCase('!=', [Token(tt.tNE, '!=', 0)]),
    TestCase(r'`[0, 1, 2]`', [Token(tt.tJSONLiteral, '[0, 1, 2]', 1)]),
    TestCase(r"'foo'", [Token(tt.tStringLiteral, 'foo', 1)]),
    TestCase(r"'a'", [Token(tt.tStringLiteral, 'a', 1)]),
    TestCase(r"'foo\'bar'", [Token(tt.tStringLiteral, "foo'bar", 1)]),
    TestCase('@', [Token(tt.tCurrent, '@', 0)]),
    TestCase('&', [Token(tt.tExpref, '&', 0)]),
    TestCase('"\u2713"', [Token(tt.tQuotedIdentifier, '✓', 0)]),
    TestCase(r"'\\u03a6'", [Token(tt.tStringLiteral, r'\\u03a6', 1)]),
    // Quoted identifier unicode escape sequences
    TestCase(r'"\\"', [Token(tt.tQuotedIdentifier, r'\', 0)]),
    // Combinations of tokens.
    TestCase('foo.bar', [
      Token(tt.tUnquotedIdentifier, 'foo', 0),
      Token(tt.tDot, '.', 3),
      Token(tt.tUnquotedIdentifier, 'bar', 4)
    ]),
    TestCase('foo[0]', [
      Token(tt.tUnquotedIdentifier, 'foo', 0),
      Token(tt.tLbracket, '[', 3),
      Token(tt.tNumber, '0', 4),
      Token(tt.tRbracket, ']', 5),
    ]),
    TestCase('foo[?a<b]', [
      Token(tt.tUnquotedIdentifier, 'foo', 0),
      Token(tt.tFilter, '[?', 3),
      Token(tt.tUnquotedIdentifier, 'a', 5),
      Token(tt.tLT, '<', 6),
      Token(tt.tUnquotedIdentifier, 'b', 7),
      Token(tt.tRbracket, ']', 8),
    ]),
    TestCase('foo."1"[0]', [
      Token(tt.tUnquotedIdentifier, 'foo', 0),
      Token(tt.tDot, '.', 3),
      Token(tt.tQuotedIdentifier, '1', 4),
      Token(tt.tLbracket, '[', 7),
      Token(tt.tNumber, '0', 8),
      Token(tt.tRbracket, ']', 9),
    ])
  ];
  test('lex tests', () {
    for (var it in tests) {
      var tokens = tokenize(it.expression);
      it.tokens.add(Token(tt.tEOF, '', it.expression.length));
      expect(tokens, equals(it.tokens));
    }
  });
}

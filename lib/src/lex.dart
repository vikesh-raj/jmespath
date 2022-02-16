import 'dart:convert';
import 'package:charcode/ascii.dart';

import 'errors.dart';

enum tt {
  tUnknown,
  tStar,
  tDot,
  tFilter,
  tFlatten,
  tLparen,
  tRparen,
  tLbracket,
  tRbracket,
  tLbrace,
  tRbrace,
  tOr,
  tPipe,
  tNumber,
  tUnquotedIdentifier,
  tQuotedIdentifier,
  tComma,
  tColon,
  tLT,
  tLTE,
  tGT,
  tGTE,
  tEQ,
  tNE,
  tJSONLiteral,
  tStringLiteral,
  tCurrent,
  tExpref,
  tAnd,
  tNot,
  tEOF,
}

class Token {
  final tt tokType;
  final String value;
  final int position;
  final int length;

  Token(this.tokType, this.value, this.position) : length = value.length;

  @override
  bool operator ==(other) =>
      other is Token &&
      other.tokType == tokType &&
      other.value == value &&
      other.position == position &&
      other.length == length;

  @override
  int get hashCode =>
      tokType.hashCode ^ value.hashCode ^ position.hashCode ^ length.hashCode;

  @override
  String toString() => '$tokType : $value, pos : $position, len $length';
}

List<Token> tokenize(String expression) {
  return _Lexer(expression).tokenize();
}

final _basicTokens = {
  $dot: tt.tDot,
  $asterisk: tt.tStar,
  $comma: tt.tComma,
  $colon: tt.tColon,
  $lbrace: tt.tLbrace,
  $rbrace: tt.tRbrace,
  $rbracket: tt.tRbracket, // tLbracket not included because it could be "[]"
  $lparen: tt.tLparen,
  $rparen: tt.tRparen,
  $at: tt.tCurrent,
};

final _whiteSpace = {$space, $tab, $lf, $cr};

bool _isAlpha(int ch) {
  return (ch >= $a && ch <= $z) ||
      (ch >= $A && ch <= $Z) ||
      (ch == $underscore);
}

bool _isNum(int ch) {
  return (ch >= $0 && ch <= $9) || ch == $dash;
}

bool _isAlphaNum(int ch) {
  return (ch >= $a && ch <= $z) ||
      (ch >= $A && ch <= $Z) ||
      (ch >= $0 && ch <= $9) ||
      (ch == $underscore);
}

class _Lexer {
  String expression;
  late RuneIterator iterator;
  int get length => expression.length;
  int get position => iterator.rawIndex;
  int get current => iterator.current;
  bool next() => iterator.moveNext();
  bool back() => iterator.movePrevious();

  _Lexer(this.expression);

  List<Token> tokenize() {
    iterator = expression.runes.iterator;

    var tokens = <Token>[];
    while (next()) {
      var ch = current;
      if (_isAlpha(ch)) {
        tokens.add(consumeUnquotedIdentifier());
      } else if (_basicTokens.containsKey(ch)) {
        tokens.add(Token(_basicTokens[ch]!, String.fromCharCode(ch), position));
      } else if (_isNum(ch)) {
        tokens.add(consumeNumber());
      } else if (ch == $lbracket) {
        tokens.add(consumeLBracket());
      } else if (ch == $quote) {
        tokens.add(consumeQuotedIdentifier());
      } else if (ch == $single_quote) {
        tokens.add(consumeRawStringLiteral());
      } else if (ch == $backquote) {
        tokens.add(consumeLiteral());
      } else if (ch == $pipe) {
        tokens.add(matchOrElse(ch, $pipe, tt.tOr, tt.tPipe));
      } else if (ch == $less_than) {
        tokens.add(matchOrElse(ch, $equal, tt.tLTE, tt.tLT));
      } else if (ch == $greater_than) {
        tokens.add(matchOrElse(ch, $equal, tt.tGTE, tt.tGT));
      } else if (ch == $exclamation) {
        tokens.add(matchOrElse(ch, $equal, tt.tNE, tt.tNot));
      } else if (ch == $equal) {
        tokens.add(matchOrElse(ch, $equal, tt.tEQ, tt.tUnknown));
      } else if (ch == $ampersand) {
        tokens.add(matchOrElse(ch, $ampersand, tt.tAnd, tt.tExpref));
      } else if (_whiteSpace.contains(ch)) {
        //Ignore whitespace
      } else {
        throw SyntaxException(
            offset: position,
            expression: expression,
            message: 'Unknown char: ' + String.fromCharCode(ch));
      }
    }
    var eofToken = Token(tt.tEOF, '', length);
    tokens.add(eofToken);
    return tokens;
  }

  Token consumeUnquotedIdentifier() {
    return consumeTill(tt.tUnquotedIdentifier, _isAlphaNum);
  }

  Token consumeNumber() {
    return consumeTill(tt.tNumber, _isNum);
  }

  Token consumeLBracket() {
    var pos = position;
    var ok = next();
    if (ok) {
      switch (current) {
        case $question:
          return Token(tt.tFilter, '[?', pos);
        case $rbracket:
          return Token(tt.tFlatten, '[]', pos);
      }
    }
    back();
    return Token(tt.tLbracket, '[', pos);
  }

  Token consumeRawStringLiteral() {
    var pos = position + 1;
    var codes = <int>[];
    var found = false;
    while (next()) {
      if ($single_quote == current) {
        found = true;
        break;
      }
      if (current == $backslash) {
        next();
        if (current != $single_quote) {
          codes.add($backslash);
        }
      }
      codes.add(current);
    }
    if (!found) {
      throw SyntaxException(
          offset: length,
          expression: expression,
          message: 'Unclosed delimiter: \'');
    }
    var str = String.fromCharCodes(codes);
    return Token(tt.tStringLiteral, str, pos);
  }

  Token consumeQuotedIdentifier() {
    var pos = position;
    var str = consumeUntil($quote);
    dynamic s;
    try {
      s = json.decode('"$str"');
      if (s is String) {
        return Token(tt.tQuotedIdentifier, s, pos);
      }
    } on FormatException {
      throw SyntaxException(
          offset: pos,
          expression: expression,
          message: 'Unable to parse to quoted identifier');
    }
    throw SyntaxException(
        offset: pos,
        expression: expression,
        message: 'Unable to parse to quoted identifier : $s');
  }

  Token consumeLiteral() {
    var pos = position + 1;
    var str = consumeUntil($backquote);
    str = str.replaceAll('\\`', '`');
    return Token(tt.tJSONLiteral, str, pos);
  }

  Token consumeTill(tt tokType, bool Function(int) match) {
    var codes = [current];
    var pos = position;
    while (next()) {
      if (!match(current)) {
        back();
        break;
      }
      codes.add(current);
    }
    return Token(tokType, String.fromCharCodes(codes), pos);
  }

  Token matchOrElse(int first, int second, tt matchedType, tt singleCharType) {
    var pos = position;
    var ok = next();
    if (ok) {
      var next = current;
      if (next == second) {
        return Token(matchedType, String.fromCharCodes([first, second]), pos);
      } else {
        iterator.movePrevious();
      }
    }
    return Token(singleCharType, String.fromCharCode(first), pos);
  }

  String consumeUntil(int ch) {
    var codes = <int>[];
    var found = false;
    while (next()) {
      if (ch == current) {
        found = true;
        break;
      }
      if (current == $backslash) {
        codes.add(current);
        next();
      }
      codes.add(current);
    }
    if (!found) {
      throw SyntaxException(
          offset: length,
          expression: expression,
          message: 'Unclosed delimiter: ' + String.fromCharCode(ch));
    }
    return String.fromCharCodes(codes);
  }
}

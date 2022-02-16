import 'dart:convert';
import 'lex.dart';
import 'util.dart';
import 'errors.dart';

enum ast {
  empty,
  comparator,
  currentNode,
  expRef,
  functionExpression,
  field,
  filterProjection,
  flatten,
  identity,
  indexValue,
  indexExpression,
  keyValPair,
  literal,
  multiSelectHash,
  multiSelectList,
  orExpression,
  andExpression,
  notExpression,
  pipe,
  projection,
  subexpression,
  slice,
  valueProjection,
}

class AstNode {
  final ast type;
  final dynamic value;
  final List<AstNode> children;

  AstNode(this.type, this.value, [this.children = const []]);

  @override
  String toString() {
    var sb = StringBuffer();
    prettyPrint(sb, this, 0);
    return sb.toString();
  }

  void prettyPrint(StringBuffer sb, AstNode node, int indent) {
    var spaces = repeat(' ', indent);
    sb.writeln('$spaces${node.type} {');
    var nextIndent = indent + 2;
    var nextSpaces = repeat(' ', nextIndent);
    if (node.value != null) {
      sb.writeln('${nextSpaces}value: ${node.value}');
    }
    if (node.children.isNotEmpty) {
      sb.writeln('${nextSpaces}children : {');
      var childIndent = nextIndent + 2;
      for (var elem in children) {
        prettyPrint(sb, elem, childIndent);
      }
    }
    sb.writeln('$spaces}');
  }
}

var _bindingPowers = <tt, int>{
  tt.tEOF: 0,
  tt.tUnquotedIdentifier: 0,
  tt.tQuotedIdentifier: 0,
  tt.tRbracket: 0,
  tt.tRparen: 0,
  tt.tComma: 0,
  tt.tRbrace: 0,
  tt.tNumber: 0,
  tt.tCurrent: 0,
  tt.tExpref: 0,
  tt.tColon: 0,
  tt.tPipe: 1,
  tt.tOr: 2,
  tt.tAnd: 3,
  tt.tEQ: 5,
  tt.tLT: 5,
  tt.tLTE: 5,
  tt.tGT: 5,
  tt.tGTE: 5,
  tt.tNE: 5,
  tt.tFlatten: 9,
  tt.tStar: 20,
  tt.tFilter: 21,
  tt.tDot: 40,
  tt.tNot: 45,
  tt.tLbrace: 50,
  tt.tLbracket: 55,
  tt.tLparen: 60,
};

AstNode parse(String expression) {
  return _Parser(expression).parse();
}

class _Parser {
  String expression;
  late List<Token> tokens;
  late int index;

  _Parser(this.expression) {
    index = 0;
    tokens = tokenize(expression);
  }

  AstNode parse() {
    var root = parseExpression(0);
    if (current != tt.tEOF) {
      throw syntaxError(
          'Unexpected token at the end of the expresssion: $current');
    }
    return root;
  }

  AstNode parseExpression(int bindingPower) {
    var leftToken = lookaheadToken(0);
    advance();
    var leftastNode = nud(leftToken);
    var currentToken = current;
    while (bindingPower < _bindingPowers[currentToken]!) {
      advance();
      leftastNode = led(currentToken, leftastNode);
      currentToken = current;
    }
    return leftastNode;
  }

  AstNode parseIndexExpression() {
    if (lookahead(0) == tt.tColon || lookahead(1) == tt.tColon) {
      return parseSliceExpression();
    }
    var indexStr = lookaheadToken(0).value;
    var parsedInt = int.parse(indexStr);
    var indexastNode = AstNode(ast.indexValue, parsedInt);
    advance();
    match(tt.tRbracket);
    return indexastNode;
  }

  AstNode parseSliceExpression() {
    var parts = <int?>[null, null, null];
    var partIndex = 0;
    while (current != tt.tRbracket && partIndex < 3) {
      if (current == tt.tColon) {
        partIndex++;
        advance();
      } else if (current == tt.tNumber) {
        var parsedInt = int.parse(lookaheadToken(0).value);
        parts[partIndex] = parsedInt;
        advance();
      } else {
        throw syntaxError('Expected tColon or tNumber, received: $current');
      }
    }
    match(tt.tRbracket);
    return AstNode(ast.slice, parts);
  }

  void match(tt tokenType) {
    if (current == tokenType) {
      advance();
      return;
    }
    throw syntaxError('Expected $tokenType, received: $current');
  }

  void match2(tt t1, tt t2) {
    if (current == t1 || current == t2) {
      advance();
      return;
    }
    throw syntaxError('Expected $t1 or $t2, received: $current');
  }

  AstNode idastNode() => AstNode(ast.identity, null);

  AstNode led(tt tokenType, AstNode node) {
    switch (tokenType) {
      case tt.tDot:
        if (current != tt.tStar) {
          var right = parseDotRHS(_bindingPowers[tt.tDot]!);
          return AstNode(ast.subexpression, null, [node, right]);
        }
        advance();
        var right = parseProjectionRHS(_bindingPowers[tt.tDot]!);
        return AstNode(ast.valueProjection, null, [node, right]);
      case tt.tPipe:
        var right = parseExpression(_bindingPowers[tt.tPipe]!);
        return AstNode(ast.pipe, null, [node, right]);
      case tt.tOr:
        var right = parseExpression(_bindingPowers[tt.tOr]!);
        return AstNode(ast.orExpression, null, [node, right]);
      case tt.tAnd:
        var right = parseExpression(_bindingPowers[tt.tAnd]!);
        return AstNode(ast.andExpression, null, [node, right]);
      case tt.tLparen:
        var name = node.value;
        var args = <AstNode>[];
        while (current != tt.tRparen) {
          var expression = parseExpression(0);
          if (current == tt.tComma) {
            match(tt.tComma);
          }
          args.add(expression);
        }
        match(tt.tRparen);
        return AstNode(ast.functionExpression, name, args);
      case tt.tFilter:
        return parseFilter(node);
      case tt.tFlatten:
        var left = AstNode(ast.flatten, null, [node]);
        var right = parseProjectionRHS(_bindingPowers[tt.tFlatten]!);
        return AstNode(ast.projection, null, [left, right]);
      case tt.tEQ:
      case tt.tNE:
      case tt.tGT:
      case tt.tGTE:
      case tt.tLT:
      case tt.tLTE:
        var right = parseExpression(_bindingPowers[tokenType]!);
        return AstNode(ast.comparator, tokenType, [node, right]);
      case tt.tLbracket:
        var tokenType = current;
        if (tokenType == tt.tNumber || tokenType == tt.tColon) {
          var right = parseIndexExpression();
          return projectIfSlice(node, right);
        }
        // Otherwise this is a projection.
        match(tt.tStar);
        match(tt.tRbracket);
        var right = parseProjectionRHS(_bindingPowers[tt.tStar]!);
        return AstNode(ast.projection, null, [node, right]);
      default:
        throw syntaxError('Unexpected token: $tokenType');
    }
  }

  AstNode nud(Token token) {
    switch (token.tokType) {
      case tt.tJSONLiteral:
        return AstNode(ast.literal, json.decode(token.value));
      case tt.tStringLiteral:
        return AstNode(ast.literal, token.value);
      case tt.tUnquotedIdentifier:
        return AstNode(ast.field, token.value);
      case tt.tQuotedIdentifier:
        var n = AstNode(ast.field, token.value);
        if (current == tt.tLparen) {
          throw syntaxErrorToken(
              'Can\'t have quoted identifier as function name.', token);
        }
        return n;
      case tt.tStar:
        if (current == tt.tRbracket) {
          return AstNode(ast.valueProjection, null, [idastNode(), idastNode()]);
        }
        var right = parseProjectionRHS(_bindingPowers[tt.tStar]!);
        return AstNode(ast.valueProjection, null, [idastNode(), right]);
      case tt.tFilter:
        return parseFilter(idastNode());
      case tt.tLbrace:
        return parseMultiSelectHash();
      case tt.tFlatten:
        var left = AstNode(ast.flatten, null, [idastNode()]);
        var right = parseProjectionRHS(_bindingPowers[tt.tFlatten]!);
        return AstNode(ast.projection, null, [left, right]);
      case tt.tLbracket:
        var tokenType = current;
        //var right ASTastNode
        if (tokenType == tt.tNumber || tokenType == tt.tColon) {
          var right = parseIndexExpression();
          return projectIfSlice(idastNode(), right);
        } else if (tokenType == tt.tStar && lookahead(1) == tt.tRbracket) {
          advance();
          advance();
          var right = parseProjectionRHS(_bindingPowers[tt.tStar]!);
          return AstNode(ast.projection, null, [idastNode(), right]);
        }
        return parseMultiSelectList();
      case tt.tCurrent:
        return AstNode(ast.currentNode, null);
      case tt.tExpref:
        var expression = parseExpression(_bindingPowers[tt.tExpref]!);
        return AstNode(ast.expRef, null, [expression]);
      case tt.tNot:
        var expression = parseExpression(_bindingPowers[tt.tNot]!);
        return AstNode(ast.notExpression, null, [expression]);
      case tt.tLparen:
        var expression = parseExpression(0);
        match(tt.tRparen);
        return expression;
      case tt.tEOF:
        throw syntaxErrorToken('Incomplete expression', token);
      default:
        throw syntaxErrorToken('Invalid token: ${token.tokType}', token);
    }
  }

  AstNode parseMultiSelectList() {
    var expressions = <AstNode>[];
    while (true) {
      var expression = parseExpression(0);
      expressions.add(expression);
      if (current == tt.tRbracket) {
        break;
      }
      match(tt.tComma);
    }
    match(tt.tRbracket);
    return AstNode(ast.multiSelectList, null, expressions);
  }

  AstNode parseMultiSelectHash() {
    var children = <AstNode>[];
    while (true) {
      var keyToken = lookaheadToken(0);
      match2(tt.tUnquotedIdentifier, tt.tQuotedIdentifier);
      var keyName = keyToken.value;
      match(tt.tColon);
      var value = parseExpression(0);
      var n = AstNode(ast.keyValPair, keyName, [value]);
      children.add(n);
      if (current == tt.tComma) {
        match(tt.tComma);
      } else if (current == tt.tRbrace) {
        match(tt.tRbrace);
        break;
      }
    }
    return AstNode(ast.multiSelectHash, null, children);
  }

  AstNode projectIfSlice(AstNode left, AstNode right) {
    var indexExpr = AstNode(ast.indexExpression, null, [left, right]);
    if (right.type == ast.slice) {
      var right = parseProjectionRHS(_bindingPowers[tt.tStar]!);
      return AstNode(ast.projection, null, [indexExpr, right]);
    }
    return indexExpr;
  }

  AstNode parseFilter(AstNode node) {
    var right = idastNode();
    var condition = parseExpression(0);
    match(tt.tRbracket);
    if (current != tt.tFlatten) {
      right = parseProjectionRHS(_bindingPowers[tt.tFilter]!);
    }
    return AstNode(ast.filterProjection, null, [node, right, condition]);
  }

  AstNode parseDotRHS(int bindingPower) {
    var lookahead = current;
    if (tokensOneOf(
        [tt.tQuotedIdentifier, tt.tUnquotedIdentifier, tt.tStar], lookahead)) {
      return parseExpression(bindingPower);
    } else if (lookahead == tt.tLbracket) {
      match(tt.tLbracket);
      return parseMultiSelectList();
    } else if (lookahead == tt.tLbrace) {
      match(tt.tLbrace);
      return parseMultiSelectHash();
    }
    throw syntaxError('Expected identifier, lbracket, or lbrace');
  }

  AstNode parseProjectionRHS(int bindingPower) {
    if (_bindingPowers[current]! < 10) {
      return idastNode();
    } else if (current == tt.tLbracket) {
      return parseExpression(bindingPower);
    } else if (current == tt.tFilter) {
      return parseExpression(bindingPower);
    } else if (current == tt.tDot) {
      match(tt.tDot);
      return parseDotRHS(bindingPower);
    }
    throw syntaxError('Error in parsing projection $current');
  }

  tt lookahead(int number) => lookaheadToken(number).tokType;
  tt get current => lookahead(0);
  Token lookaheadToken(int number) => tokens[index + number];
  bool tokensOneOf(List<tt> elements, tt tokType) => elements.contains(tokType);

  void advance() => index++;

  SyntaxException syntaxError(String msg) => SyntaxException(
      message: msg, expression: expression, offset: lookaheadToken(0).position);

  SyntaxException syntaxErrorToken(String msg, Token t) =>
      SyntaxException(message: msg, expression: expression, offset: t.position);
}

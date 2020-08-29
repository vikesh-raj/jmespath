import 'dart:convert';
import 'lex.dart';
import 'util.dart';
import 'errors.dart';

enum ast {
  Empty,
  Comparator,
  CurrentNode,
  ExpRef,
  FunctionExpression,
  Field,
  FilterProjection,
  Flatten,
  Identity,
  Index,
  IndexExpression,
  KeyValPair,
  Literal,
  MultiSelectHash,
  MultiSelectList,
  OrExpression,
  AndExpression,
  NotExpression,
  Pipe,
  Projection,
  Subexpression,
  Slice,
  ValueProjection,
}

class astNode {
  final ast type;
  final dynamic value;
  final List<astNode> children;

  astNode(this.type, this.value, [this.children]);

  @override
  String toString() {
    var sb = StringBuffer();
    prettyPrint(sb, this, 0);
    return sb.toString();
  }

  void prettyPrint(StringBuffer sb, astNode node, int indent) {
    var sb = StringBuffer();
    var spaces = repeat(' ', indent);
    sb.write('$spaces${node.type} {\n');
    var nextIndent = indent + 2;
    var nextSpaces = repeat(' ', nextIndent);
    if (value != null) {
      sb.write('${nextSpaces}value: ${node.value.toString()}\n');
    }
    if (node.children != null && node.children.isNotEmpty) {
      sb.write('${nextSpaces}children : {\n');
      var childIndent = nextIndent + 2;
      for (var elem in children) {
        prettyPrint(sb, elem, childIndent);
      }
    }
    sb.write('${spaces}}\n');
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

astNode parse(String expression) {
  return _Parser(expression).parse();
}

class _Parser {
  String expression;
  List<token> tokens;
  int index;

  _Parser(this.expression) {
    index = 0;
    tokens = tokenize(expression);
  }

  astNode parse() {
    var root = parseExpression(0);
    if (current != tt.tEOF) {
      throw syntaxError(
          'Unexpected token at the end of the expresssion: $current');
    }
    return root;
  }

  astNode parseExpression(int bindingPower) {
    var leftToken = lookaheadToken(0);
    advance();
    var leftastNode = nud(leftToken);
    var currentToken = current;
    while (bindingPower < _bindingPowers[currentToken]) {
      advance();
      leftastNode = led(currentToken, leftastNode);
      currentToken = current;
    }
    return leftastNode;
  }

  astNode parseIndexExpression() {
    if (lookahead(0) == tt.tColon || lookahead(1) == tt.tColon) {
      return parseSliceExpression();
    }
    var indexStr = lookaheadToken(0).value;
    var parsedInt = int.parse(indexStr);
    var indexastNode = astNode(ast.Index, parsedInt);
    advance();
    match(tt.tRbracket);
    return indexastNode;
  }

  astNode parseSliceExpression() {
    var parts = <int>[null, null, null];
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
    return astNode(ast.Slice, parts);
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

  astNode idastNode() => astNode(ast.Identity, null);

  astNode led(tt tokenType, astNode node) {
    switch (tokenType) {
      case tt.tDot:
        if (current != tt.tStar) {
          var right = parseDotRHS(_bindingPowers[tt.tDot]);
          return astNode(ast.Subexpression, null, [node, right]);
        }
        advance();
        var right = parseProjectionRHS(_bindingPowers[tt.tDot]);
        return astNode(ast.ValueProjection, null, [node, right]);
      case tt.tPipe:
        var right = parseExpression(_bindingPowers[tt.tPipe]);
        return astNode(ast.Pipe, null, [node, right]);
      case tt.tOr:
        var right = parseExpression(_bindingPowers[tt.tOr]);
        return astNode(ast.OrExpression, null, [node, right]);
      case tt.tAnd:
        var right = parseExpression(_bindingPowers[tt.tAnd]);
        return astNode(ast.AndExpression, null, [node, right]);
      case tt.tLparen:
        var name = node.value;
        var args = <astNode>[];
        while (current != tt.tRparen) {
          var expression = parseExpression(0);
          if (current == tt.tComma) {
            match(tt.tComma);
          }
          args.add(expression);
        }
        match(tt.tRparen);
        return astNode(ast.FunctionExpression, name, args);
      case tt.tFilter:
        return parseFilter(node);
      case tt.tFlatten:
        var left = astNode(ast.Flatten, null, [node]);
        var right = parseProjectionRHS(_bindingPowers[tt.tFlatten]);
        return astNode(ast.Projection, null, [left, right]);
      case tt.tEQ:
      case tt.tNE:
      case tt.tGT:
      case tt.tGTE:
      case tt.tLT:
      case tt.tLTE:
        var right = parseExpression(_bindingPowers[tokenType]);
        return astNode(ast.Comparator, tokenType, [node, right]);
      case tt.tLbracket:
        var tokenType = current;
        if (tokenType == tt.tNumber || tokenType == tt.tColon) {
          var right = parseIndexExpression();
          return projectIfSlice(node, right);
        }
        // Otherwise this is a projection.
        match(tt.tStar);
        match(tt.tRbracket);
        var right = parseProjectionRHS(_bindingPowers[tt.tStar]);
        return astNode(ast.Projection, null, [node, right]);
      default:
        throw syntaxError('Unexpected token: $tokenType');
    }
  }

  astNode nud(token token) {
    switch (token.tokType) {
      case tt.tJSONLiteral:
        return astNode(ast.Literal, json.decode(token.value));
      case tt.tStringLiteral:
        return astNode(ast.Literal, token.value);
      case tt.tUnquotedIdentifier:
        return astNode(ast.Field, token.value);
      case tt.tQuotedIdentifier:
        var n = astNode(ast.Field, token.value);
        if (current == tt.tLparen) {
          throw syntaxErrorToken(
              'Can\'t have quoted identifier as function name.', token);
        }
        return n;
      case tt.tStar:
        if (current == tt.tRbracket) {
          return astNode(ast.ValueProjection, null, [idastNode(), idastNode()]);
        }
        var right = parseProjectionRHS(_bindingPowers[tt.tStar]);
        return astNode(ast.ValueProjection, null, [idastNode(), right]);
      case tt.tFilter:
        return parseFilter(idastNode());
      case tt.tLbrace:
        return parseMultiSelectHash();
      case tt.tFlatten:
        var left = astNode(ast.Flatten, null, [idastNode()]);
        var right = parseProjectionRHS(_bindingPowers[tt.tFlatten]);
        return astNode(ast.Projection, null, [left, right]);
      case tt.tLbracket:
        var tokenType = current;
        //var right ASTastNode
        if (tokenType == tt.tNumber || tokenType == tt.tColon) {
          var right = parseIndexExpression();
          return projectIfSlice(idastNode(), right);
        } else if (tokenType == tt.tStar && lookahead(1) == tt.tRbracket) {
          advance();
          advance();
          var right = parseProjectionRHS(_bindingPowers[tt.tStar]);
          return astNode(ast.Projection, null, [idastNode(), right]);
        }
        return parseMultiSelectList();
      case tt.tCurrent:
        return astNode(ast.CurrentNode, null);
      case tt.tExpref:
        var expression = parseExpression(_bindingPowers[tt.tExpref]);
        return astNode(ast.ExpRef, null, [expression]);
      case tt.tNot:
        var expression = parseExpression(_bindingPowers[tt.tNot]);
        return astNode(ast.NotExpression, null, [expression]);
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

  astNode parseMultiSelectList() {
    var expressions = <astNode>[];
    while (true) {
      var expression = parseExpression(0);
      expressions.add(expression);
      if (current == tt.tRbracket) {
        break;
      }
      match(tt.tComma);
    }
    match(tt.tRbracket);
    return astNode(ast.MultiSelectList, null, expressions);
  }

  astNode parseMultiSelectHash() {
    var children = <astNode>[];
    while (true) {
      var keyToken = lookaheadToken(0);
      match2(tt.tUnquotedIdentifier, tt.tQuotedIdentifier);
      var keyName = keyToken.value;
      match(tt.tColon);
      var value = parseExpression(0);
      var n = astNode(ast.KeyValPair, keyName, [value]);
      children.add(n);
      if (current == tt.tComma) {
        match(tt.tComma);
      } else if (current == tt.tRbrace) {
        match(tt.tRbrace);
        break;
      }
    }
    return astNode(ast.MultiSelectHash, null, children);
  }

  astNode projectIfSlice(astNode left, astNode right) {
    var indexExpr = astNode(ast.IndexExpression, null, [left, right]);
    if (right.type == ast.Slice) {
      var right = parseProjectionRHS(_bindingPowers[tt.tStar]);
      return astNode(ast.Projection, null, [indexExpr, right]);
    }
    return indexExpr;
  }

  astNode parseFilter(astNode node) {
    var right = idastNode();
    var condition = parseExpression(0);
    match(tt.tRbracket);
    if (current != tt.tFlatten) {
      right = parseProjectionRHS(_bindingPowers[tt.tFilter]);
    }
    return astNode(ast.FilterProjection, null, [node, right, condition]);
  }

  astNode parseDotRHS(int bindingPower) {
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

  astNode parseProjectionRHS(int bindingPower) {
    if (_bindingPowers[current] < 10) {
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
  token lookaheadToken(int number) => tokens[index + number];
  bool tokensOneOf(List<tt> elements, tt tokType) => elements.contains(tokType);

  void advance() => index++;

  SyntaxException syntaxError(String msg) => SyntaxException(
      message: msg, expression: expression, offset: lookaheadToken(0).position);

  SyntaxException syntaxErrorToken(String msg, token t) =>
      SyntaxException(message: msg, expression: expression, offset: t.position);
}

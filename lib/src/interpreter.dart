import 'function.dart';
import 'parser.dart';
import 'lex.dart';
import 'util.dart';
import 'errors.dart';

class treeInterpreter {
  functionCaller fCall;

  treeInterpreter(this.fCall);

  dynamic callFunction(String name, List arguments) {
    if (!fCall.functionTable.containsKey(name)) {
      throw UnknownFunctionException('Unknown function : $name');
    }
    var entry = fCall.functionTable[name];
    var resolvedArgs = entry.resolveArgs(arguments);
    if (entry.hasExpRef) {
      resolvedArgs.insert(0, this);
    }
    return entry.handler(resolvedArgs);
  }

  dynamic execute(astNode node, dynamic value) {
    switch (node.type) {
      case ast.Comparator:
        var left = execute(node.children[0], value);
        var right = execute(node.children[1], value);
        switch (node.value) {
          case tt.tEQ:
            return objsEqual(left, right);
          case tt.tNE:
            return !objsEqual(left, right);
        }
        if (left is num && right is num) {
          switch (node.value) {
            case tt.tGT:
              return left > right;
            case tt.tGTE:
              return left >= right;
            case tt.tLT:
              return left < right;
            case tt.tLTE:
              return left <= right;
          }
        }
        return null;
      case ast.ExpRef:
        return expRef(node.children[0]);
      case ast.FunctionExpression:
        var resolvedArgs = <dynamic>[];
        for (var arg in node.children) {
          var current = execute(arg, value);
          resolvedArgs.add(current);
        }
        var function = node.value;
        if (function is String) {
          return callFunction(function, resolvedArgs);
        }
        throw JmesException(
            'Unkown funtion type ${function.runtimeType}, $function');
      case ast.Field:
        if (node.value is String) {
          if (value is Map<String, dynamic>) {
            return value[node.value];
          }
          return null;
        }
        throw JmesException('Expecting string ${node.value}');
      case ast.FilterProjection:
        var left = execute(node.children[0], value);
        if (left is List) {
          var collected = <dynamic>[];
          var compareNode = node.children[2];
          for (var element in left) {
            var result = execute(compareNode, element);
            if (!isValueFalse(result)) {
              var current = execute(node.children[1], element);
              if (current != null) {
                collected.add(current);
              }
            }
          }
          return collected;
        }
        return null;
      case ast.Flatten:
        var left = execute(node.children[0], value);
        if (left is List) {
          var flattened = <dynamic>[];
          for (var element in left) {
            if (element is List) {
              flattened.addAll(element);
            } else {
              flattened.add(element);
            }
          }
          return flattened;
        }
        return null;
      case ast.Identity:
      case ast.CurrentNode:
        return value;
      case ast.Index:
        if (value is List) {
          if (node.value is int) {
            int index = node.value;
            if (index < 0) {
              index += value.length;
            }
            if (index < value.length && index >= 0) {
              return value[index];
            }
          }
        }
        return null;
      case ast.KeyValPair:
        return execute(node.children[0], value);
      case ast.Literal:
        return node.value;
      case ast.MultiSelectHash:
        if (value == null) {
          return null;
        }
        var collected = <String, dynamic>{};
        for (var child in node.children) {
          var current = execute(child, value);
          if (child.value is String) {
            String key = child.value;
            collected[key] = current;
          }
        }
        return collected;
      case ast.MultiSelectList:
        if (value == null) {
          return null;
        }
        var collected = <dynamic>[];
        for (var child in node.children) {
          var current = execute(child, value);
          collected.add(current);
        }
        return collected;
      case ast.OrExpression:
        var matched = execute(node.children[0], value);
        if (isValueFalse(matched)) {
          matched = execute(node.children[1], value);
        }
        return matched;
      case ast.AndExpression:
        var matched = execute(node.children[0], value);
        if (isValueFalse(matched)) {
          return matched;
        }
        return execute(node.children[1], value);
      case ast.NotExpression:
        var matched = execute(node.children[0], value);
        return isValueFalse(matched);
      case ast.Pipe:
        var result = value;
        for (var child in node.children) {
          result = execute(child, result);
        }
        return result;
      case ast.Projection:
        var left = execute(node.children[0], value);
        if (left is List) {
          var collected = <dynamic>[];
          for (var element in left) {
            var current = execute(node.children[1], element);
            if (current != null) {
              collected.add(current);
            }
          }
          return collected;
        }
        return null;
      case ast.Subexpression:
      case ast.IndexExpression:
        var left = execute(node.children[0], value);
        return execute(node.children[1], left);
      case ast.Slice:
        if (value is List) {
          if (node.value is List<int>) {
            List<int> parts = node.value;
            return slice(value, parts);
          }
        }
        return null;
      case ast.ValueProjection:
        var left = execute(node.children[0], value);
        if (left is Map<String, dynamic>) {
          var values = left.values;
          var collected = <dynamic>[];
          for (var element in values) {
            var current = execute(node.children[1], element);
            if (current != null) {
              collected.add(current);
            }
          }
          return collected;
        }
        return null;
      default:
        throw JmesException('Unknown ast node ${node.type}');
    }
  }
}

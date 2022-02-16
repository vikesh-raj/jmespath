import 'function.dart';
import 'parser.dart';
import 'lex.dart';
import 'util.dart';
import 'errors.dart';

class TreeInterpreter {
  FunctionCaller fCall;

  TreeInterpreter(this.fCall);

  dynamic callFunction(String name, List arguments) {
    if (!fCall.functionTable.containsKey(name)) {
      throw UnknownFunctionException('Unknown function : $name');
    }
    var entry = fCall.functionTable[name]!;
    var resolvedArgs = entry.resolveArgs(arguments);
    if (entry.hasExpRef) {
      resolvedArgs.insert(0, this);
    }
    return entry.handler(resolvedArgs);
  }

  dynamic execute(AstNode node, dynamic value) {
    switch (node.type) {
      case ast.comparator:
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
      case ast.expRef:
        return ExpRef(node.children[0]);
      case ast.functionExpression:
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
      case ast.field:
        if (node.value is String) {
          if (value is Map<String, dynamic>) {
            return value[node.value];
          }
          return null;
        }
        throw JmesException('Expecting string ${node.value}');
      case ast.filterProjection:
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
      case ast.flatten:
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
      case ast.identity:
      case ast.currentNode:
        return value;
      case ast.indexValue:
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
      case ast.keyValPair:
        return execute(node.children[0], value);
      case ast.literal:
        return node.value;
      case ast.multiSelectHash:
        if (value == null) {
          return null;
        }
        var collected = <String, dynamic>{};
        for (var child in node.children) {
          var current = execute(child, value);
          if (child.value is String) {
            String key = child.value!;
            collected[key] = current;
          }
        }
        return collected;
      case ast.multiSelectList:
        if (value == null) {
          return null;
        }
        var collected = <dynamic>[];
        for (var child in node.children) {
          var current = execute(child, value);
          collected.add(current);
        }
        return collected;
      case ast.orExpression:
        var matched = execute(node.children[0], value);
        if (isValueFalse(matched)) {
          matched = execute(node.children[1], value);
        }
        return matched;
      case ast.andExpression:
        var matched = execute(node.children[0], value);
        if (isValueFalse(matched)) {
          return matched;
        }
        return execute(node.children[1], value);
      case ast.notExpression:
        var matched = execute(node.children[0], value);
        return isValueFalse(matched);
      case ast.pipe:
        var result = value;
        for (var child in node.children) {
          result = execute(child, result);
        }
        return result;
      case ast.projection:
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
      case ast.subexpression:
      case ast.indexExpression:
        var left = execute(node.children[0], value);
        return execute(node.children[1], left);
      case ast.slice:
        if (value is List) {
          if (node.value is List<int?>) {
            List<int?> parts = node.value;
            return slice(value, parts);
          }
        }
        return null;
      case ast.valueProjection:
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

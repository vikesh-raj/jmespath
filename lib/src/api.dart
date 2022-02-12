import 'package:jmespath/src/interpreter.dart';

import 'parser.dart';
import 'interpreter.dart';
import 'functions.dart';

/// Jmespath holds the compiled expression.
/// Use the `search` function for searching the expression in the given data.
class Jmespath {
  late astNode _ast;
  late treeInterpreter _intr;

  Jmespath.compile(String expression) {
    _ast = parse(expression);
    _intr = _newInterpreter();
  }

  dynamic search(data) {
    return _intr.execute(_ast, data);
  }
}

/// search function evaluates the expression given the data.
/// throws `JmesException` on errors.
dynamic search(String expression, dynamic data) {
  var ast = parse(expression);
  var intr = _newInterpreter();
  return intr.execute(ast, data);
}

treeInterpreter _newInterpreter() => treeInterpreter(newFunctionCaller());

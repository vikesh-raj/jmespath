import 'parser.dart';
import 'util.dart';
import 'errors.dart';

typedef JpFunction = dynamic Function(List);

enum JpType {
  jpUnknown,
  jpNumber,
  jpString,
  jpArray,
  jpObject,
  jpArrayNumber,
  jpArrayString,
  jpExpref,
  jpAny,
}

class ArgSpec {
  List<JpType> types;
  bool variadic;

  ArgSpec(this.types, {this.variadic = false});

  void typeCheck(dynamic arg) {
    for (var t in types) {
      switch (t) {
        case JpType.jpNumber:
          if (arg is num) {
            return;
          }
          break;
        case JpType.jpString:
          if (arg is String) {
            return;
          }
          break;
        case JpType.jpArray:
          if (arg is List) {
            return;
          }
          break;
        case JpType.jpObject:
          if (arg is Map<String, dynamic>) {
            return;
          }
          break;
        case JpType.jpArrayNumber:
          if (arg is List && isArrayNum(arg)) {
            return;
          }
          break;
        case JpType.jpArrayString:
          if (arg is List && isArrayString(arg)) {
            return;
          }
          break;
        case JpType.jpAny:
          return;
        case JpType.jpExpref:
          if (arg is ExpRef) {
            return;
          }
          break;
        case JpType.jpUnknown:
          break;
      }
    }
    throw InvalidTypeException('Invalid type for $arg, expected $types');
  }
}

class FunctionEntry {
  String name;
  List<ArgSpec> arguments;
  JpFunction handler;
  bool hasExpRef;

  FunctionEntry(this.name, this.arguments, this.handler,
      {this.hasExpRef = false});

  List resolveArgs(List args) {
    if (arguments.isEmpty) {
      return args;
    }
    if (!arguments.last.variadic) {
      if (arguments.length != args.length) {
        throw InvalidArityException(
            'Incorrect number of arguments to $name. Expecting ${arguments.length}, got ${args.length}');
      }
      for (var i = 0; i < arguments.length; i++) {
        arguments[i].typeCheck(args[i]);
      }
      return args;
    }
    if (args.length < arguments.length) {
      throw InvalidArityException(
          'Invalid arity to function $name. Expecting ${arguments.length}, got ${args.length}');
    }
    return args;
  }
}

class FunctionCaller {
  Map<String, FunctionEntry> functionTable;
  FunctionCaller(this.functionTable);
}

class ExpRef {
  AstNode ref;
  ExpRef(this.ref);
}

import 'parser.dart';
import 'util.dart';
import 'errors.dart';

typedef jpFunction = dynamic Function(List);

enum jpType {
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

class argSpec {
  List<jpType> types;
  bool variadic;

  argSpec(this.types, {this.variadic = false});

  void typeCheck(dynamic arg) {
    for (var t in types) {
      switch (t) {
        case jpType.jpNumber:
          if (arg is num) {
            return;
          }
          break;
        case jpType.jpString:
          if (arg is String) {
            return;
          }
          break;
        case jpType.jpArray:
          if (arg is List) {
            return;
          }
          break;
        case jpType.jpObject:
          if (arg is Map<String, dynamic>) {
            return;
          }
          break;
        case jpType.jpArrayNumber:
          if (arg is List && isArrayNum(arg)) {
            return;
          }
          break;
        case jpType.jpArrayString:
          if (arg is List && isArrayString(arg)) {
            return;
          }
          break;
        case jpType.jpAny:
          return;
        case jpType.jpExpref:
          if (arg is expRef) {
            return;
          }
          break;
        case jpType.jpUnknown:
          break;
      }
    }
    throw InvalidTypeException('Invalid type for $arg, expected $types');
  }
}

class functionEntry {
  String name;
  List<argSpec> arguments;
  jpFunction handler;
  bool hasExpRef;

  functionEntry(this.name, this.arguments, this.handler,
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

class functionCaller {
  Map<String, functionEntry> functionTable;
  functionCaller(this.functionTable);
}

class expRef {
  astNode ref;
  expRef(this.ref);
}

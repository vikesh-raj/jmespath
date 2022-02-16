import 'package:collection/collection.dart';
import 'dart:convert';

import 'interpreter.dart';
import 'function.dart';
import 'util.dart';
import 'errors.dart';

FunctionCaller newFunctionCaller() {
  var functionTable = <String, FunctionEntry>{
    'length': FunctionEntry(
        'length',
        [
          ArgSpec([JpType.jpString, JpType.jpArray, JpType.jpObject])
        ],
        jpfLength),
    'starts_with': FunctionEntry(
        'starts_with',
        [
          ArgSpec([JpType.jpString]),
          ArgSpec([JpType.jpString])
        ],
        jpfStartsWith),
    'abs': FunctionEntry(
        'abs',
        [
          ArgSpec([JpType.jpNumber])
        ],
        jpfAbs),
    'avg': FunctionEntry(
        'avg',
        [
          ArgSpec([JpType.jpArrayNumber])
        ],
        jpfAvg),
    'ceil': FunctionEntry(
        'ceil',
        [
          ArgSpec([JpType.jpNumber])
        ],
        jpfCeil),
    'contains': FunctionEntry(
        'contains',
        [
          ArgSpec([JpType.jpArray, JpType.jpString]),
          ArgSpec([JpType.jpAny])
        ],
        jpfContains),
    'ends_with': FunctionEntry(
        'ends_with',
        [
          ArgSpec([JpType.jpString]),
          ArgSpec([JpType.jpString])
        ],
        jpfEndsWith),
    'floor': FunctionEntry(
        'floor',
        [
          ArgSpec([JpType.jpNumber])
        ],
        jpfFloor),
    'map': FunctionEntry(
        'map',
        [
          ArgSpec([JpType.jpExpref]),
          ArgSpec([JpType.jpArray])
        ],
        jpfMap,
        hasExpRef: true),
    'max': FunctionEntry(
        'max',
        [
          ArgSpec([JpType.jpArrayNumber, JpType.jpArrayString])
        ],
        jpfMax),
    'merge': FunctionEntry(
        'merge',
        [
          ArgSpec([JpType.jpObject], variadic: true)
        ],
        jpfMerge),
    'max_by': FunctionEntry(
        'max_by',
        [
          ArgSpec([JpType.jpArray]),
          ArgSpec([JpType.jpExpref])
        ],
        jpfMaxBy,
        hasExpRef: true),
    'sum': FunctionEntry(
        'sum',
        [
          ArgSpec([JpType.jpArrayNumber])
        ],
        jpfSum),
    'min': FunctionEntry(
        'min',
        [
          ArgSpec([JpType.jpArrayNumber, JpType.jpArrayString])
        ],
        jpfMin),
    'min_by': FunctionEntry(
        'min_by',
        [
          ArgSpec([JpType.jpArray]),
          ArgSpec([JpType.jpExpref])
        ],
        jpfMinBy,
        hasExpRef: true),
    'type': FunctionEntry(
        'type',
        [
          ArgSpec([JpType.jpAny])
        ],
        jpfType),
    'keys': FunctionEntry(
        'keys',
        [
          ArgSpec([JpType.jpObject])
        ],
        jpfKeys),
    'values': FunctionEntry(
        'values',
        [
          ArgSpec([JpType.jpObject])
        ],
        jpfValues),
    'sort': FunctionEntry(
        'sort',
        [
          ArgSpec([JpType.jpArrayNumber, JpType.jpArrayString])
        ],
        jpfSort),
    'sort_by': FunctionEntry(
        'sort_by',
        [
          ArgSpec([JpType.jpArray]),
          ArgSpec([JpType.jpExpref])
        ],
        jpfSortBy,
        hasExpRef: true),
    'join': FunctionEntry(
        'join',
        [
          ArgSpec([JpType.jpString]),
          ArgSpec([JpType.jpArrayString])
        ],
        jpfJoin),
    'reverse': FunctionEntry(
        'reverse',
        [
          ArgSpec([JpType.jpArray, JpType.jpString])
        ],
        jpfReverse),
    'to_array': FunctionEntry(
        'to_array',
        [
          ArgSpec([JpType.jpAny])
        ],
        jpfToArray),
    'to_string': FunctionEntry(
        'to_string',
        [
          ArgSpec([JpType.jpAny])
        ],
        jpfToString),
    'to_number': FunctionEntry(
        'to_number',
        [
          ArgSpec([JpType.jpAny])
        ],
        jpfToNumber),
    'not_null': FunctionEntry(
        'not_null',
        [
          ArgSpec([JpType.jpAny], variadic: true)
        ],
        jpfNotNull)
  };
  return FunctionCaller(functionTable);
}

dynamic jpfLength(List arguments) {
  var arg = arguments[0];
  if (arg is String) {
    return arg.length;
  } else if (arg is List) {
    return arg.length;
  } else if (arg is Map) {
    return arg.length;
  }
  throw JmesException('could not compute length()');
}

dynamic jpfStartsWith(List arguments) {
  var search = arguments[0] as String;
  var prefix = arguments[1] as String;
  return search.startsWith(prefix);
}

dynamic jpfAbs(List arguments) {
  var val = arguments[0] as num;
  return val.abs();
}

dynamic jpfAvg(List arguments) {
  var arg = arguments[0];
  if (arg is List) {
    var length = arg.length;
    var numerator = 0.0;
    for (var a in arg) {
      numerator += a;
    }
    return numerator / length;
  }
  throw JmesException('Argument is not a array {arg}');
}

dynamic jpfCeil(List arguments) {
  var val = arguments[0] as num;
  return val.ceil();
}

dynamic jpfContains(List arguments) {
  var search = arguments[0];
  var element = arguments[1];
  if (search is String) {
    if (element is String) {
      return search.contains(element);
    }
    return false;
  }
  if (search is List) {
    return search.any((e) => objsEqual(e, element));
  }
  return false;
}

dynamic jpfEndsWith(List arguments) {
  var search = arguments[0] as String;
  var prefix = arguments[1] as String;
  return search.endsWith(prefix);
}

dynamic jpfFloor(List arguments) {
  var val = arguments[0] as num;
  return val.floor();
}

dynamic jpfMap(List arguments) {
  var intr = arguments[0] as TreeInterpreter;
  var exp = arguments[1] as ExpRef;
  var node = exp.ref;
  var arr = arguments[2] as List;
  return List.from(arr.map((value) => intr.execute(node, value)));
}

dynamic jpfMax(List arguments) {
  var l = arguments[0] as List;
  if (l.isEmpty) {
    return null;
  }
  if (l.length == 1) {
    return l[0];
  }
  if (isArrayNum(l)) {
    var best = l[0];
    for (var e in l) {
      if (e > best) best = e;
    }
    return best;
  }
  if (isArrayString(l)) {
    var best = l[0] as String;
    for (var e in l) {
      if (best.compareTo(e) < 0) best = e as String;
    }
    return best;
  }
  return null;
}

dynamic jpfMerge(List arguments) {
  var output = <String, dynamic>{};
  for (var arg in arguments) {
    if (arg is Map) {
      arg.forEach((key, value) => output[key] = value);
    }
  }
  return output;
}

dynamic jpfMaxBy(List arguments) {
  var intr = arguments[0] as TreeInterpreter;
  var arr = arguments[1] as List;
  var exp = arguments[2] as ExpRef;
  var node = exp.ref;

  if (arr.isEmpty) return null;
  if (arr.length == 1) return arr[0];
  var start = intr.execute(node, arr[0]);
  if (start is num) {
    var bestVal = start;
    var bestItem = arr[0];
    for (var item in arr.sublist(1)) {
      var result = intr.execute(node, item);
      if (result is num) {
        if (result > bestVal) {
          bestVal = result;
          bestItem = item;
        }
      } else {
        throw JmesException('$result is not number');
      }
    }
    return bestItem;
  } else if (start is String) {
    var bestVal = start;
    var bestItem = arr[0];
    for (var item in arr.sublist(1)) {
      var result = intr.execute(node, item);
      if (result is String) {
        if (result.compareTo(bestVal) > 0) {
          bestVal = result;
          bestItem = item;
        }
      } else {
        throw InvalidTypeException('$result is not string');
      }
    }
    return bestItem;
  }
  throw InvalidTypeException('invalid type : $start should be float or string');
}

dynamic jpfSum(List arguments) {
  var l = arguments[0];
  if (l is List && isArrayNum(l)) {
    var sum = 0.0;
    for (var e in l) {
      sum += e;
    }
    return sum;
  }
  return 0.0;
}

dynamic jpfMin(List arguments) {
  var l = arguments[0] as List;
  if (l.isEmpty) {
    return null;
  }
  if (l.length == 1) {
    return l[0];
  }
  if (isArrayNum(l)) {
    var best = l[0];
    for (var e in l) {
      if (best.compareTo(e) > 0) best = e;
    }
    return best;
  }
  if (isArrayString(l)) {
    var best = l[0] as String;
    for (var e in l) {
      if (best.compareTo(e) > 0) best = e as String;
    }
    return best;
  }
  return null;
}

dynamic jpfMinBy(List arguments) {
  var intr = arguments[0] as TreeInterpreter;
  var arr = arguments[1] as List;
  var exp = arguments[2] as ExpRef;
  var node = exp.ref;

  if (arr.isEmpty) return null;
  if (arr.length == 1) return arr[0];
  var start = intr.execute(node, arr[0]);
  if (start is num) {
    var bestVal = start;
    var bestItem = arr[0];
    arr.sublist(1).forEach((item) {
      var result = intr.execute(node, item);
      if (result is num) {
        if (result.compareTo(bestVal) < 0) {
          bestVal = result;
          bestItem = item;
        }
      } else {
        throw InvalidTypeException('$result is not number');
      }
    });
    return bestItem;
  } else if (start is String) {
    var bestVal = start;
    var bestItem = arr[0];
    arr.sublist(1).forEach((item) {
      var result = intr.execute(node, item);
      if (result is String) {
        if (result.compareTo(bestVal) < 0) {
          bestVal = result;
          bestItem = item;
        }
      } else {
        throw InvalidTypeException('$result is not string');
      }
    });
    return bestItem;
  }
  throw InvalidTypeException('invalid type : should be float or string');
}

dynamic jpfType(List arguments) {
  var arg = arguments[0];
  if (arg is num) {
    return 'number';
  } else if (arg is String) {
    return 'string';
  } else if (arg is List) {
    return 'array';
  } else if (arg is Map) {
    return 'object';
  } else if (arg == null) {
    return 'null';
  } else if (arg is bool) {
    return 'boolean';
  }
  throw JmesException('Unknown type : $arg');
}

dynamic jpfKeys(List arguments) {
  var arg = arguments[0];
  if (arg is Map) {
    return List.from(arg.keys);
  }
  throw JmesException('Invalid argument to keys function : $arg');
}

dynamic jpfValues(List arguments) {
  var arg = arguments[0];
  if (arg is Map) {
    return List.from(arg.values);
  }
  throw JmesException('Invalid argument to values function : $arg');
}

dynamic jpfSort(List arguments) {
  var l = arguments[0] as List;
  if (isArrayNum(l)) {
    var d = List<num>.from(l);
    mergeSort(d);
    return d;
  }
  if (isArrayString(l)) {
    var d = List<String>.from(l);
    mergeSort(d);
    return d;
  }
  return null;
}

dynamic jpfSortBy(List arguments) {
  var intr = arguments[0] as TreeInterpreter;
  var arr = arguments[1] as List;
  var exp = arguments[2] as ExpRef;
  var node = exp.ref;
  if (arr.isEmpty) return arr;
  if (arr.length == 1) return arr;
  var array = List.from(arr);
  var start = intr.execute(node, arr[0]);
  if (start is num) {
    mergeSort(array, compare: (dynamic itemi, dynamic itemj) {
      var first = intr.execute(node, itemi);
      var second = intr.execute(node, itemj);
      if (first is num && second is num) {
        return first.compareTo(second);
      }
      throw InvalidTypeException(
          'invalid type. Expecting number for $first or $second');
    });
    return array;
  }

  if (start is String) {
    mergeSort(array, compare: (dynamic itemi, dynamic itemj) {
      var first = intr.execute(node, itemi);
      var second = intr.execute(node, itemj);
      if (first is String && second is String) {
        return first.compareTo(second);
      }
      throw InvalidTypeException(
          'invalid type. Expecting string for $first or $second');
    });
    return array;
  }
  throw InvalidTypeException('invalid type, must be number or string');
}

dynamic jpfJoin(List arguments) {
  var sep = arguments[0] as String;
  var l = arguments[1] as List;
  var s = List<String>.from(l);
  return s.join(sep);
}

dynamic jpfReverse(List arguments) {
  var arg = arguments[0];
  if (arg is String) {
    return reverseString(arg);
  }
  if (arg is List) {
    return List.from(arg.reversed);
  }
  throw JmesException('expected array or string $arg');
}

dynamic jpfToArray(List arguments) {
  var arg = arguments[0];
  if (arg is List) {
    return arg;
  }
  return [arg];
}

dynamic jpfToString(List arguments) {
  var arg = arguments[0];
  if (arg is String) {
    return arg;
  }
  return json.encode(arg);
}

dynamic jpfToNumber(List arguments) {
  var arg = arguments[0];
  if (arg is num) {
    return arg;
  } else if (arg is String) {
    try {
      return double.parse(arg);
    } on FormatException {
      return null;
    }
  } else if (arg is List || arg is Map || arg is bool || arg == null) {
    return null;
  }
  throw JmesException('unknown type for $arg');
}

dynamic jpfNotNull(List arguments) {
  for (var arg in arguments) {
    if (arg != null) return arg;
  }
  return null;
}

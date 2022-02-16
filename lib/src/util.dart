import 'package:collection/collection.dart';
import 'errors.dart';

bool isValueFalse(o) {
  if (o == null) {
    return true;
  } else if (o is String) {
    return o.isEmpty;
  } else if (o is bool) {
    return !o;
  } else if (o is List) {
    return o.isEmpty;
  } else if (o is Map) {
    return o.isEmpty;
  }
  return false;
}

List slice(List slice, List<int?> parts) {
  var computed = computeSliceParams(slice.length, parts);
  return slice3(slice, computed[0], computed[1], computed[2]);
}

List<int> computeSliceParams(int length, List<int?> parts) {
  var start = 0, stop = 0, step = 0;
  if (parts[2] == null) {
    step = 1;
  } else if (parts[2] == 0) {
    throw InvalidValueException('Invalid slice, step cannot be 0');
  } else {
    step = parts[2]!;
  }

  var stepValueNegative = false;
  if (step < 0) {
    stepValueNegative = true;
  }

  if (parts[0] == null) {
    if (stepValueNegative) {
      start = length - 1;
    } else {
      start = 0;
    }
  } else {
    start = capSlice(length, parts[0]!, step);
  }

  if (parts[1] == null) {
    if (stepValueNegative) {
      stop = -1;
    } else {
      stop = length;
    }
  } else {
    stop = capSlice(length, parts[1]!, step);
  }
  return [start, stop, step];
}

List slice3(List slice, int start, int stop, int step) {
  var result = <dynamic>[];
  if (step > 0) {
    for (var i = start; i < stop; i += step) {
      result.add(slice[i]);
    }
  } else {
    for (var i = start; i > stop; i += step) {
      result.add(slice[i]);
    }
  }
  return result;
}

int capSlice(int length, int actual, int step) {
  if (actual < 0) {
    actual += length;
    if (actual < 0) {
      if (step < 0) {
        actual = -1;
      } else {
        actual = 0;
      }
    }
  } else if (actual >= length) {
    if (step < 0) {
      actual = length - 1;
    } else {
      actual = length;
    }
  }
  return actual;
}

bool objsEqual(dynamic e1, e2) {
  var eq = DeepCollectionEquality();
  return eq.equals(e1, e2);
}

String repeat(String s, int count) {
  var sb = StringBuffer();
  for (var i = 0; i < count; i++) {
    sb.write(s);
  }
  return sb.toString();
}

bool isNumber(o) => o is num;
bool isString(o) => o is String;
bool isArrayNum(List l) => l.every(isNumber);
bool isArrayString(List l) => l.every(isString);
String reverseString(String s) =>
    String.fromCharCodes(s.runes.toList().reversed);

import 'package:jmespath/jmespath.dart';

import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:test/test.dart';

class TestCase {
  String comment;
  String expression;
  dynamic result;
  String error;
  bool run;

  TestCase.fromMap(Map<String, dynamic> o) {
    comment = o['comment'] as String;
    expression = o['expression'] as String;
    result = o['result'];
    error = o['error'] as String;
    run = o['run'] as bool;
  }
}

class TestSuite {
  dynamic given;
  List<TestCase> cases;
  String comment;
  String file;

  TestSuite.fromMap(Map<String, dynamic> o) {
    given = o['given'];
    var cs = o['cases'] as List;
    cases = List.from(cs.map((j) {
      var oo = j as Map<String, dynamic>;
      return TestCase.fromMap(oo);
    }));
    comment = o['comment'] as String;
  }
}

List<String> files = [
  'compliance/basic.json',
  'compliance/current.json',
  'compliance/escape.json',
  'compliance/filters.json',
  'compliance/functions.json',
  'compliance/identifiers.json',
  'compliance/indices.json',
  'compliance/literal.json',
  'compliance/multiselect.json',
  'compliance/ormatch.json',
  'compliance/pipe.json',
  'compliance/slice.json',
  'compliance/syntax.json',
  'compliance/unicode.json',
  'compliance/wildcard.json',
  'compliance/boolean.json',
];

List<TestSuite> loadTestCases(String base) {
  var tss = <TestSuite>[];
  files.forEach((file) {
    final j = json.decode(File(base + '/' + file).readAsStringSync()) as List;
    tss.addAll(j.map((ts) => TestSuite.fromMap(ts)..file = file));
  });
  return tss;
}

void runTestSuite(TestSuite ts) {
  var runMode = false;
  // runMode = true;
  print('File : ${ts.file}');
  ts.cases.forEach((testcase) {
    if (runMode && testcase?.run != true) {
      return;
    }
    print('expression : ${testcase.expression}');
    if (testcase.error != null && testcase.error.isNotEmpty) {
      var exceptionType = isA<JmesException>();
      switch (testcase.error) {
        case 'syntax':
          exceptionType = isA<SyntaxException>();
          break;
        case 'unknown-function':
          exceptionType = isA<UnknownFunctionException>();
          break;
        case 'invalid-type':
          exceptionType = isA<InvalidTypeException>();
          break;
        case 'invalid-value':
          exceptionType = isA<InvalidValueException>();
          break;
        case 'invalid-arity':
          exceptionType = isA<InvalidArityException>();
          break;
      }
      expect(
          () => search(testcase.expression, ts.given), throwsA(exceptionType),
          reason: 'expression : ${testcase.expression}');
    } else {
      var result = search(testcase.expression, ts.given);
      expect(result, testcase.result,
          reason: 'expression : ${testcase.expression}');
    }
  });
}

void main() {
  var tss = loadTestCases('.');
  test('compliance suite', () {
    tss.forEach(runTestSuite);
  });
}

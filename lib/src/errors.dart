/// JmesException is the base exception raised by all the functions
/// in this library.
class JmesException implements Exception {
  final String message;
  const JmesException(this.message);

  @override
  String toString() => 'JmesException: $message';
}

/// SyntaxException is thrown when there is a syntax error while parsing the
/// expression string.
class SyntaxException extends JmesException {
  final String expression;
  final int offset;
  SyntaxException({required String message, required this.expression, required this.offset})
      : super(message);
  @override
  String toString() =>
      'SyntaxException: Error while paring $expression at $offset : $message';
}

/// UnknownFunctionException is thrown when an unknown function is called.
class UnknownFunctionException extends JmesException {
  const UnknownFunctionException(String message) : super(message);
}

/// InvalidTypeException is thrown when types of the function argument doesn't
/// match with the expected type of the function value.
class InvalidTypeException extends JmesException {
  const InvalidTypeException(String message) : super(message);
}

/// InvalidValueException is thrown when the values to the function are invalid.
class InvalidValueException extends JmesException {
  const InvalidValueException(String message) : super(message);
}

/// InvalidArityException is thrown when the function is passed incorrect
/// number of arguments.
class InvalidArityException extends JmesException {
  const InvalidArityException(String message) : super(message);
}

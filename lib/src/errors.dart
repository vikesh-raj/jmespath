class JmesException implements Exception {
  final String message;
  const JmesException(this.message);

  @override
  String toString() => 'JmesException: $message';
}

class SyntaxException extends JmesException {
  final String expression;
  final int offset;
  SyntaxException({String message, this.expression, this.offset})
      : super(message);
  @override
  String toString() =>
      'SyntaxException: Error while paring $expression at $offset : $message';
}

class UnknownFunctionException extends JmesException {
  const UnknownFunctionException(String message) : super(message);
}

class InvalidTypeException extends JmesException {
  const InvalidTypeException(String message) : super(message);
}

class InvalidValueException extends JmesException {
  const InvalidValueException(String message) : super(message);
}

class InvalidArityException extends JmesException {
  const InvalidArityException(String message) : super(message);
}

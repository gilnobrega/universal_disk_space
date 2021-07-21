//https://www.woolha.com/tutorials/dart-creating-custom-exception-class

class NotFoundException implements Exception {
  final String message;

  const NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException{message: $message}';
}

class DiskInfoError implements Exception {
  final String message;

  const DiskInfoError([this.message = 'Failed to get disk info.']);

  @override
  String toString() => 'DiskInfoError{message: $message}';
}

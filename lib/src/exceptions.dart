//https://www.woolha.com/tutorials/dart-creating-custom-exception-class

class NotFoundException implements Exception {
  String _message = '';

  NotFoundException([String message = 'Failed to locate path.']) {
    _message = message;
  }

  @override
  String toString() {
    return _message;
  }
}

class DiskInfoError implements Exception {
  String _message = '';

  DiskInfoError([String message = 'Failed to get disk info.']) {
    _message = message;
  }

  @override
  String toString() {
    return _message;
  }
}

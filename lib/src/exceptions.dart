//https://www.woolha.com/tutorials/dart-creating-custom-exception-class

class BinNotFoundException implements Exception
{
    String _message;
  
    BinNotFoundException([String message = "Failed to locate binaries!"]) {
      this._message = message;
    }
  
    @override
    String toString() {
      return _message;
    }
}
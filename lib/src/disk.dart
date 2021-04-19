import 'dart:convert';

class Disk {
  //Original device path such as \\nasdrive or C:\ on windows and /dev/sdX on Linux
  String _devicePath = "";
  String get devicePath => _devicePath;

  //Path where this device is mounted such as Z:\ on windows and /mount/user/disk on Linux
  String _mountPath = "";
  String get mountPath => _mountPath;

  //Disk's total size in bytes
  int _totalSize = 0;
  int get totalSize => _totalSize;

  //Disk's used space in bytes
  int _usedSpace = 0;
  int get usedSpace => _usedSpace;

  //Disk's available space in bytes
  int _availableSpace = 0;
  int get availableSpace => _availableSpace;

  Disk(devicePath, mountPath, totalSize, usedSpace, availableSpace) {
    this._devicePath = devicePath ?? '';
    this._mountPath = mountPath ?? '';
    this._totalSize = totalSize ?? 0;
    this._usedSpace = usedSpace ?? 0;
    this._availableSpace = availableSpace ?? 0;
  }

  Map toJson() => {
    'mountPath': mountPath,
    'devicePath': devicePath,
    'totalSize': totalSize,
    'usedSpace': usedSpace,
    'availableSpace': availableSpace
  };

  String toString() {
    return jsonEncode(this);
  } 
}

class Disk {
  //Original device path such as \\nasdrive or C:\ on windows and /dev/sdX on Linux
  String _devicePath;
  String get devicePath => _devicePath;

  //Path where this device is mounted such as Z:\ on windows and /mount/user/disk on Linux
  String _mountPath;
  String get mountPath => _mountPath;

  //Disk's total size in bytes
  int _totalSize;
  int get totalSize => _totalSize;

  //Disk's used space in bytes
  int _usedSpace;
  int get usedSpace => _usedSpace;

  //Disk's available space in bytes
  int _availableSpace;
  int get availableSpace => _availableSpace;

  Disk(devicePath, mountPath, totalSize, usedSpace, availableSpace) {
    this._devicePath = devicePath;
    this._mountPath = mountPath;
    this._totalSize = totalSize;
    this._usedSpace = usedSpace;
    this._availableSpace = availableSpace;
  }
}

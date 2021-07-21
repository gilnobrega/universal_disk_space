import 'dart:convert';

class Disk {
  //Original device path such as \\nasdrive or C:\ on windows and /dev/sdX on Linux
  final String devicePath;

  //Path where this device is mounted such as Z:\ on windows and /mount/user/disk on Linux
  final String mountPath;

  //Disk's total size in bytes
  final int totalSize;

  //Disk's used space in bytes
  final int usedSpace;

  //Disk's available space in bytes
  final int availableSpace;

  const Disk(
    this.devicePath,
    this.mountPath,
    this.totalSize,
    this.usedSpace,
    this.availableSpace,
  );

  Map toJson() => {
        'mountPath': mountPath,
        'devicePath': devicePath,
        'totalSize': totalSize,
        'usedSpace': usedSpace,
        'availableSpace': availableSpace
      };

  @override
  String toString() {
    return jsonEncode(this);
  }
}

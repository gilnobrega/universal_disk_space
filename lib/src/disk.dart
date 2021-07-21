import 'dart:convert';

class Disk {
  /// The original device path such as `\\nasdrive` or `C:\` on Windows and
  /// `/dev/sdX` on Linux.
  final String devicePath;

  /// The path where this device is mounted such as `Z:\` on Windows and
  /// `/mount/user/disk` on Linux
  final String mountPath;

  /// The disk's total size in bytes.
  final int totalSize;

  /// The disk's used space in bytes.
  final int usedSpace;

  /// The disk's available space in bytes.
  final int availableSpace;

  const Disk({
    required this.devicePath,
    required this.mountPath,
    required this.totalSize,
    required this.usedSpace,
    required this.availableSpace,
  });

  Map toJson() => {
        'mountPath': mountPath,
        'devicePath': devicePath,
        'totalSize': totalSize,
        'usedSpace': usedSpace,
        'availableSpace': availableSpace
      };

  Disk.fromJson(dynamic json) {
    _devicePath = (json['devicePath'] as String?) ?? '';
    _mountPath = (json['mountPath'] as String?) ?? '';
    _totalSize = (json['totalSize'] as int?) ?? 0;
    _usedSpace = (json['usedSpace'] as int?) ?? 0;
    _availableSpace = (json['availableSpace'] as int?) ?? 0;
  }

  @override
  String toString() {
    return jsonEncode(this);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Disk &&
          runtimeType == other.runtimeType &&
          devicePath == other.devicePath &&
          mountPath == other.mountPath &&
          totalSize == other.totalSize &&
          usedSpace == other.usedSpace &&
          availableSpace == other.availableSpace;

  @override
  int get hashCode =>
      devicePath.hashCode ^
      mountPath.hashCode ^
      totalSize.hashCode ^
      usedSpace.hashCode ^
      availableSpace.hashCode;
}

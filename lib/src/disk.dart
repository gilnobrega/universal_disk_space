import 'dart:convert';

class Disk {
  /// The original device path such as `\\nasdrive` or `C:\` on Windows and
  /// `/dev/sdX` on Linux.
  late final String devicePath;

  /// The path where this device is mounted such as `Z:\` on Windows and
  /// `/mount/user/disk` on Linux
  late final String mountPath;

  /// The disk's total size in bytes.
  late final int totalSize;

  /// The disk's used space in bytes.
  late final int usedSpace;

  /// The disk's available space in bytes.
  late final int availableSpace;

  Disk({
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
    devicePath = (json['devicePath'] as String?) ?? '';
    mountPath = (json['mountPath'] as String?) ?? '';
    totalSize = (json['totalSize'] as int?) ?? 0;
    usedSpace = (json['usedSpace'] as int?) ?? 0;
    availableSpace = (json['availableSpace'] as int?) ?? 0;
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

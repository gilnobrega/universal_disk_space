import 'dart:io';

import 'package:universal_disk_space/universal_disk_space.dart';

Future<void> main() async {
  // Initializes the DiskSpace class.
  final diskSpace = DiskSpace();

  // Scan for disks in the system.
  await diskSpace.scan();

  // A list of disks in the system.
  var disks = diskSpace.disks;

  // Prints the device path, mount path, and total size of each disk in system.
  for (final disk in disks) {
    print(disk.devicePath); // e.g.: 'C:\' in Windows or '/dev/sdc' in Linux
    print(disk
        .mountPath); // e.g.: 'C:\' or '\\nasdrive' in Windows or '/' in Linux
    print(disk.totalSize.toString()); // in bytes
    print(disk.usedSpace.toString()); // in bytes
    print(disk.availableSpace.toString()); // in bytes
    print('');
  }

  /// Searches for the disk that '/home' belongs to.
  /// Any FileSystemEntity can be used.
  var homeDisk = diskSpace.getDisk(Directory('/home'));
  print(homeDisk);
}

import 'dart:core';
import 'dart:io' as io;

import 'exceptions.dart';

class DiskSpace {
  final RegExp dfRegex = new RegExp(
      "\n([^ ]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+\%)[ ]+([^\n]+)",
      caseSensitive: false,
      multiLine: true);
  final String dfLocation = "/usr/bin/df";

  //List of disks in the system
  List<Disk> disks = [];

  DiskSpace() {
    //Linux code
    if (io.Platform.isLinux) {
      //runs df if binary exists
      if (io.File(dfLocation).existsSync()) {
        String output = runCommand(dfLocation, []);

        print(output);

        List<RegExpMatch> matches = dfRegex.allMatches(output).toList();

        //Example /dev/sdb1        107132516   93716396    7931016  93% /
        for (RegExpMatch match in matches) {
          int blockSize = 1000; //1kb blocks

          String devicePath = match.group(1);
          String mountPath = match.group(6);

          int totalSize = int.parse(match.group(2)) * blockSize;
          int usedSpace = int.parse(match.group(3)) * blockSize;
          int availableSpace = int.parse(match.group(4)) * blockSize;

          disks.add(new Disk(
              devicePath, mountPath, totalSize, usedSpace, availableSpace));
        }
        
        //orders from longer mountpath to shorter mountpath, very important as getDisk would break otherise
        disks.sort((disk2, disk1) => disk1._mountPath.length.compareTo(disk2._mountPath.length));
      }
      //throws exception if df doesnt exist
      else
        throw new NotFoundException(
            "Could not locate df binary in " + dfLocation);
    }
    //Windows code
    else if (io.Platform.isWindows) {}
  }

  Disk getDisk(String path) //Gets info of disk of given path
  {
    io.FileSystemEntity entity;

    if (io.File(path).existsSync())
      entity = io.File(path);
    else if (io.Directory(path).existsSync())
      entity = io.Directory(path);
    else
      throw new NotFoundException(
          "Could not locate the following file or directory: " + path);

    for (Disk disk in disks) {
      if (entity.absolute.path.startsWith(disk.mountPath) ||
          entity.absolute.path.startsWith(disk._devicePath)) return disk;
    }

      throw new NotFoundException(
          "Unable to get information about disk which contains " + path);

  }
}

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

String runCommand(binPath, [List<String> args]) {
  var output = io.Process.runSync(binPath, args);
  return output.stdout;
}

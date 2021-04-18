import 'dart:core';
import 'dart:io' as io;

import 'exceptions.dart';
import 'disk.dart';

class DiskSpace {
  final int blockSize = 1000; //1kb blocks

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

        List<RegExpMatch> matches = dfRegex.allMatches(output).toList();

        //Example /dev/sdb1        107132516   93716396    7931016  93% /
        for (RegExpMatch match in matches) {
          String devicePath = match.group(1) ?? '';
          String mountPath = match.group(6) ?? '';

          int totalSize = int.parse(match.group(2) ?? '0') * blockSize;
          int usedSpace = int.parse(match.group(3) ?? '0') * blockSize;
          int availableSpace = int.parse(match.group(4) ?? '0') * blockSize;

          disks.add(new Disk(
              devicePath, mountPath, totalSize, usedSpace, availableSpace));
        }

        //orders from longer mountpath to shorter mountpath, very important as getDisk would break otherise
        disks.sort((disk2, disk1) =>
            disk1.mountPath.length.compareTo(disk2.mountPath.length));
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
          entity.absolute.path.startsWith(disk.devicePath)) return disk;
    }

    throw new NotFoundException(
        "Unable to get information about disk which contains " + path);
  }
}

String runCommand(binPath, List<String> args) {
  var output = io.Process.runSync(binPath, args);
  return output.stdout;
}

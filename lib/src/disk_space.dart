import 'dart:core';
import 'dart:io' as io;

import 'exceptions.dart';
import 'disk.dart';

class DiskSpace {
  final int blockSize = 1000; //default df block size - 1kb blocks

  final RegExp dfRegex = new RegExp(
      "\n([^ ]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+\%)[ ]+([^\n]+)",
      caseSensitive: false,
      multiLine: true);
  final String dfLocation = "/usr/bin/df";

  final RegExp wmicRegex = new RegExp("([A-Z]:)[ ]+([0-9]+)[ ]+([0-9]+)",
      caseSensitive: false, multiLine: true);
  final String wmicLocation = "C:\\Windows\\System32\\wbem\\wmic.exe";

  final RegExp netRegex = new RegExp("..[ ]+([A-Z]:)[ ]+([^ \r\n]+)",
      caseSensitive: false, multiLine: true);
  final String netLocation = "C:\\Windows\\System32\\net.exe";

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
      }
      //throws exception if df doesnt exist
      else
        throw new NotFoundException(
            "Could not locate df binary in " + dfLocation);
    }
    //Windows code
    else if (io.Platform.isWindows) {
      if (io.File(wmicLocation).existsSync()) {
        String output = runCommand(wmicLocation,
            ["logicalDisk", "get", "freespace,", "size,", "caption"]).replaceAll("\r", "");
        List<RegExpMatch> matches = wmicRegex.allMatches(output).toList();

        String netOutput = runCommand(netLocation, ["use"]);
        List<RegExpMatch> netMatches = netRegex.allMatches(netOutput).toList();

        //Example  C:       316204883968   499013238784
        for (RegExpMatch match in matches) {
          String devicePath = match.group(1) ?? ''; // C: or Z:
          String mountPath = devicePath;

          //If is network drive then mountpath will be of the form \\nasdrive\something
          if (netMatches
              .any((netMatch) => netMatch.group(1) == devicePath))
            mountPath = netMatches
                .firstWhere(
                    (netMatch) => netMatch.group(1) == devicePath)
                .group(2) ?? '';

          int totalSize = int.parse(match.group(3) ?? '0');
          int availableSpace = int.parse(match.group(2) ?? '0');
          int usedSpace = totalSize - availableSpace;

          disks.add(new Disk(
              devicePath, mountPath, totalSize, usedSpace, availableSpace));
        }
      }
    }

    //orders from longer mountpath to shorter mountpath, very important as getDisk would break otherise
    disks.sort((disk2, disk1) =>
        disk1.mountPath.length.compareTo(disk2.mountPath.length));
  }

  Disk getDisk(String path) //Gets info of disk of given path
  {
    io.FileSystemEntity entity;

    //throws exception if file doesn't exist
    if (io.File(path).existsSync())
      entity = io.File(path);
    else if (io.Directory(path).existsSync())
      entity = io.Directory(path);
    else
      throw new NotFoundException(
          "Could not locate the following file or directory: " + path);

    //if file exists then it searches for its disk in the list of disks
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

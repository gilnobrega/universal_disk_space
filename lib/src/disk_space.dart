import 'dart:core';
import 'dart:io' as io;

import 'exceptions.dart';
import 'disk.dart';

class DiskSpace {
  final int blockSize = 1024; //default df block size - 1K (1024) blocks

  final RegExp dfRegexLinux = RegExp(
      '\n([^ ]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+\%)[ ]+([^\n]+)',
      caseSensitive: false,
      multiLine: true);

  final RegExp dfRegexMacOs = RegExp(
      '\n([^ ]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+\%)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+\%)[ ]+([^\n]+)',
      caseSensitive: false,
      multiLine: true);

  final String dfLocation = '/usr/bin/env';
  // /usr/bin/env df points to df in every UNIX system

  final RegExp wmicRegex =
      RegExp('([A-Z]:)[ ]+([0-9]+)[ ]+([0-9]+)', caseSensitive: false, multiLine: true);
  final String wmicLocation = 'C:\\Windows\\System32\\wbem\\wmic.exe';

  final RegExp netRegex =
      RegExp('..[ ]+([A-Z]:)[ ]+([^\r\n]+)', caseSensitive: false, multiLine: true);
  final String netLocation = 'C:\\Windows\\System32\\net.exe';

  //List of disks in the system
  List<Disk> disks = [];

  DiskSpace() {
    //Linux code  -- macOS should work in theory??
    if (io.Platform.isLinux || io.Platform.isMacOS) {
      //runs df if binary exists
      if (io.File(dfLocation).existsSync()) {
        //if linux then run 'df -B 1024'
        //if macOS then run 'df -k'
        var args = (io.Platform.isLinux) ? ['df', '-B', '1024'] : ['df', '-k'];
        var output = runCommand(dfLocation, args);

        var matches = (io.Platform.isLinux)
            ? dfRegexLinux.allMatches(output).toList()
            : dfRegexMacOs.allMatches(output).toList();

        //Example /dev/sdb1        107132516   93716396    7931016  93% /
        for (var match in matches) {
          var devicePath = match.group(1).trim() ?? '';

          var mountPathIndex = (io.Platform.isLinux) ? 6 : 9;

          var mountPath = match.group(mountPathIndex).trim() ?? '';

          var totalSize = int.parse(match.group(2) ?? '0') * blockSize;
          var usedSpace = int.parse(match.group(3) ?? '0') * blockSize;
          var availableSpace = int.parse(match.group(4) ?? '0') * blockSize;

          var mountDir = io.Directory(mountPath);

          if (mountDir.existsSync()) {
            disks.add(
                Disk(devicePath, mountDir.absolute.path, totalSize, usedSpace, availableSpace));
          }
        }
      }
      //throws exception if df doesnt exist
      else {
        throw NotFoundException('Could not locate df binary in ' + dfLocation);
      }
    }
    //Windows code
    else if (io.Platform.isWindows) {
      if (io.File(wmicLocation).existsSync()) {
        var output =
            runCommand(wmicLocation, ['logicalDisk', 'get', 'freespace,', 'size,', 'caption'])
                .replaceAll('\r', '');
        var matches = wmicRegex.allMatches(output).toList();

        var netOutput =
            runCommand(netLocation, ['use']).replaceAll('Microsoft Windows Network', '');
        var netMatches = netRegex.allMatches(netOutput).toList();

        //Example  C:       316204883968   499013238784
        for (var match in matches) {
          var devicePath = match.group(1).trim() ?? ''; // C: or Z:
          var mountPath = devicePath;

          //If is network drive then mountpath will be of the form \\nasdrive\something
          if (netMatches.any((netMatch) => netMatch.group(1) == devicePath)) {
            mountPath = netMatches
                    .firstWhere((netMatch) => netMatch.group(1) == devicePath)
                    .group(2)
                    .trim() ??
                '';
          }

          var totalSize = int.parse(match.group(3) ?? '0');
          var availableSpace = int.parse(match.group(2) ?? '0');
          var usedSpace = totalSize - availableSpace;

          var mountDir = io.Directory(mountPath);

          if (mountDir.existsSync()) {
            disks.add(Disk(devicePath, mountDir.path, totalSize, usedSpace, availableSpace));
          }
        }
      }
    }

    //orders from longer mountpath to shorter mountpath, very important as getDisk would break otherise
    disks.sort((disk2, disk1) => disk1.mountPath.length.compareTo(disk2.mountPath.length));
  }

  Disk getDisk(String path) //Gets info of disk of given path
  {
    path = path.trim();
    io.FileSystemEntity entity;

    //throws exception if file doesn't exist
    if (io.File(path).existsSync()) {
      entity = io.File(path);
    } else if (io.Directory(path).existsSync()) {
      entity = io.Directory(path);
    } else {
      throw NotFoundException('Could not locate the following file or directory: ' + path);
    }

    //if file exists then it searches for its disk in the list of disks
    for (var disk in disks) {
      if (io.Platform.isWindows) {
        if (entity.path.startsWith(disk.mountPath) ||
            entity.path.startsWith(disk.devicePath) ||
            entity.absolute.path
                .toUpperCase() //Must convert both sides to upper case since Windows paths are case invariant
                .startsWith(disk.mountPath.toUpperCase()) ||
            entity.absolute.path.toUpperCase().startsWith(disk.devicePath.toUpperCase())) {
          return disk;
        }
      } else if (io.Platform.isLinux || io.Platform.isMacOS) {
        if (entity.absolute.path.startsWith(disk.mountPath) ||
            entity.absolute.path.startsWith(disk.devicePath)) return disk;
      }
    }

    throw NotFoundException('Unable to get information about disk which contains ' + path);
  }
}

String runCommand(String binPath, List<String> args) {
  var output = io.Process.runSync(binPath, args);
  return output.stdout.toString();
}

import 'dart:core';
import 'dart:io' as io;

import 'disk.dart';
import 'exceptions.dart';

class DiskSpace {
  static const int blockSize = 1024; //default df block size - 1K (1024) blocks

  final RegExp dfRegexLinux = RegExp(
      '\n([^ ]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+%)[ ]+([^\n]+)',
      caseSensitive: false,
      multiLine: true);

  final RegExp dfRegexMacOs = RegExp(
      '\n([^ ]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+%)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+%)[ ]+([^\n]+)',
      caseSensitive: false,
      multiLine: true);

  // If Linux, then run 'df -B 1024'.
  final List<String> dfArgs = (io.Platform.isLinux)
      ? const ['df', '-B', '1024']
      // If macOS, then run 'df -k'.
      : (io.Platform.isMacOS)
          ? const ['df', '-k']
          : const [];

  // /usr/bin/env df points to df in every UNIX system.
  final String dfLocation = '/usr/bin/env';

  final RegExp wmicRegex = RegExp(r'([A-Z][\S]+)\\[ ]+([0-9]+)[ ]+([0-9]+)',
      caseSensitive: false, multiLine: true);
  static const String wmicLocation =
      r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';

  // wmic logicalDisk get freespace, size, caption
  static const List<String> wmicArgs = [
    '-command',
    'get-wmiobject',
    'Win32_volume',
    '|',
    'select',
    'Name,Freespace,Capacity'
  ];

  final RegExp netRegex = RegExp('..[ ]+([A-Z]:)[ ]+([^\r\n]+)',
      caseSensitive: false, multiLine: true);
  static const String netLocation = r'C:\Windows\System32\net.exe';

  // net use
  static const List<String> netArgs = ['use'];

  // List of disks in the system.
  final List<Disk> disks = [];

  DiskSpace() {
    // Linux code  -- macOS should work in theory??
    if (io.Platform.isLinux || io.Platform.isMacOS) {
      // Runs df if binary exists.
      if (io.File(dfLocation).existsSync()) {
        final output = runCommand(dfLocation, dfArgs);

        final matches = (io.Platform.isLinux)
            ? dfRegexLinux.allMatches(output).toList()
            : dfRegexMacOs.allMatches(output).toList();

        // Example: /dev/sdb1        107132516   93716396    7931016  93% /
        for (final match in matches) {
          final devicePath = match.group(1)?.trim() ?? '';

          final mountPathIndex = (io.Platform.isLinux) ? 6 : 9;

          final mountPath = match.group(mountPathIndex)?.trim() ?? '';

          final totalSize = int.parse(match.group(2) ?? '0') * blockSize;
          final usedSpace = int.parse(match.group(3) ?? '0') * blockSize;
          final availableSpace = int.parse(match.group(4) ?? '0') * blockSize;

          final mountDir = io.Directory(mountPath);

          if (mountDir.existsSync()) {
            disks.add(Disk(devicePath, mountDir.absolute.path, totalSize,
                usedSpace, availableSpace));
          }
        }
      }
      // Throws exception if df doesnt exist.
      else {
        throw NotFoundException('Could not locate df binary in ' + dfLocation);
      }
    }
    // Windows code.
    else if (io.Platform.isWindows) {
      if (io.File(wmicLocation).existsSync()) {
        final output = runCommand(wmicLocation, wmicArgs).replaceAll('\r', '');
        final matches = wmicRegex.allMatches(output).toList();

        final netOutput = runCommand(netLocation, netArgs)
            .replaceAll('Microsoft Windows Network', '');
        final netMatches = netRegex.allMatches(netOutput).toList();

        //Example: C:       316204883968   499013238784
        for (final match in matches) {
          final devicePath = match.group(1)?.trim() ?? ''; // C: or Z:
          final String mountPath;

          // If it's a network drive, then the mountpath will be of the form
          // \\nasdrive\something.
          if (netMatches.any((netMatch) => netMatch.group(1) == devicePath)) {
            mountPath = netMatches
                    .firstWhere((netMatch) => netMatch.group(1) == devicePath)
                    .group(2)
                    ?.trim() ??
                '';
          } else {
            mountPath = devicePath;
          }

          final totalSize = int.parse(match.group(3) ?? '0');
          final availableSpace = int.parse(match.group(2) ?? '0');
          final usedSpace = totalSize - availableSpace;

          final mountDir = io.Directory(mountPath);

          if (mountDir.existsSync()) {
            disks.add(Disk(devicePath, mountDir.path, totalSize, usedSpace,
                availableSpace));
          }
        }
      }
    }

    // Sorts in order of descending mountpath length.
    // Very important as [getDisk] relies on this.
    disks.sort((disk2, disk1) =>
        disk1.mountPath.length.compareTo(disk2.mountPath.length));
  }

  /// Retrieves the disk referenced in the given [entity].
  Disk getDisk(io.FileSystemEntity entity) {
    for (var disk in disks) {
      if (io.Platform.isWindows) {
        if (entity.path.startsWith(disk.mountPath) ||
            entity.path.startsWith(disk.devicePath) ||
            entity.absolute.path
                .toUpperCase() // Must convert both sides to upper case since Windows paths are case invariant
                .startsWith(disk.mountPath.toUpperCase()) ||
            entity.absolute.path
                .toUpperCase()
                .startsWith(disk.devicePath.toUpperCase())) {
          return disk;
        }
      } else if (io.Platform.isLinux || io.Platform.isMacOS) {
        if (entity.path.startsWith(disk.mountPath) ||
            entity.path.startsWith(disk.devicePath) ||
            entity.absolute.path.startsWith(disk.mountPath) ||
            entity.absolute.path.startsWith(disk.devicePath)) return disk;
      }
    }

    throw NotFoundException(
        'Unable to get information about disk which contains ' + entity.path);
  }
}

String runCommand(String binPath, List<String> args) {
  var output = io.Process.runSync(binPath, args);
  return output.stdout.toString();
}

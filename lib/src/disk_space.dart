import 'dart:core';
import 'dart:io' as io;

import 'disk.dart';
import 'exceptions.dart';

class DiskSpace {
  /// Default df block size - 1K (1024) blocks.
  static const blockSize = 1024;

  final _dfRegexLinux = RegExp(
      '\n([^ ]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+%)[ ]+([^\n]+)',
      caseSensitive: false,
      multiLine: true);

  final _dfRegexMacOs = RegExp(
      '\n([^ ]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+%)[ ]+([0-9]+)[ ]+([0-9]+)[ ]+([0-9]+%)[ ]+([^\n]+)',
      caseSensitive: false,
      multiLine: true);

  // If Linux, then run 'df -B 1024'.
  final _dfArgs = (io.Platform.isLinux)
      ? const ['df', '-B', '1024']
      // If macOS, then run 'df -k'.
      : (io.Platform.isMacOS)
          ? const ['df', '-k']
          : const <String>[];

  // /usr/bin/env df points to df in every UNIX system.
  static const _dfLocation = '/usr/bin/env';

  final _wmicRegex = RegExp(r'([A-Z][\S]+)\\[ ]+([0-9]+)[ ]+([0-9]+)',
      caseSensitive: false, multiLine: true);
  static const _wmicLocation =
      r'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';

  // wmic logicalDisk get freespace, size, caption
  static const _wmicArgs = [
    '-command',
    'get-wmiobject',
    'Win32_volume',
    '|',
    'select',
    'Name,Freespace,Capacity'
  ];

  final _netRegex = RegExp('..[ ]+([A-Z]:)[ ]+([^\r\n]+)',
      caseSensitive: false, multiLine: true);
  static const String _netLocation = r'C:\Windows\System32\net.exe';

  // net use
  static const List<String> _netArgs = ['use'];

  /// List of disks in the system.
  ///
  /// [scan] must be called at least once to populate this list.
  List<Disk> get disks => _disks;
  var _disks = const <Disk>[];

  /// Scans for disks in the system.
  ///
  /// Throws a [NotFoundException] if required system binaries cannot be found.
  ///
  /// The result can be accessed through [disks].
  Future<void> scan() async {
    // Linux code  -- macOS should work in theory??
    if (io.Platform.isLinux || io.Platform.isMacOS) {
      if (!await io.File(_dfLocation).exists()) {
        throw NotFoundException('Could not locate df binary at $_dfLocation');
      }

      final output =
          (await io.Process.run(_dfLocation, _dfArgs)).stdout as String;

      // Example: /dev/sdb1        107132516   93716396    7931016  93% /
      final matches = (io.Platform.isLinux)
          ? _dfRegexLinux.allMatches(output).toList()
          : _dfRegexMacOs.allMatches(output).toList();

      _disks = (await Future.wait(
        matches.map(
          (match) {
            final devicePath = match.group(1)?.trim() ?? '';

            final mountPathIndex = (io.Platform.isLinux) ? 6 : 9;

            final mountPath = match.group(mountPathIndex)?.trim() ?? '';

            final totalSize = int.parse(match.group(2) ?? '0') * blockSize;
            final usedSpace = int.parse(match.group(3) ?? '0') * blockSize;
            final availableSpace = int.parse(match.group(4) ?? '0') * blockSize;

            final mountDir = io.Directory(mountPath);

            return mountDir.exists().then(
                  (exists) => exists
                      ? Disk(
                          devicePath,
                          mountDir.absolute.path,
                          totalSize,
                          usedSpace,
                          availableSpace,
                        )
                      : null,
                );
          },
        ),
      ))
          .whereType<Disk>()
          .toList(growable: false);
    }
    // Windows code.
    else if (io.Platform.isWindows) {
      if (!await io.File(_wmicLocation).exists()) {
        throw NotFoundException(
            'Could not locate wmic binary at $_wmicLocation');
      }

      final output =
          ((await io.Process.run(_wmicLocation, _wmicArgs)).stdout as String)
              .replaceAll('\r', '');
      final matches = _wmicRegex.allMatches(output).toList();

      final netOutput =
          ((await io.Process.run(_netLocation, _netArgs)).stdout as String)
              .replaceAll('Microsoft Windows Network', '');
      final netMatches = _netRegex.allMatches(netOutput).toList();

      // Example: C:       316204883968   499013238784
      _disks = (await Future.wait(
        matches.map(
          (match) {
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

            return mountDir.exists().then(
                  (value) => value
                      ? Disk(
                          devicePath,
                          mountDir.path,
                          totalSize,
                          usedSpace,
                          availableSpace,
                        )
                      : null,
                );
          },
        ),
      ))
          .whereType<Disk>()
          .toList(growable: false);
    }

    // Sorts in order of descending mountpath length.
    // Very important as [getDisk] relies on this.
    disks.sort((disk1, disk2) =>
        disk2.mountPath.length.compareTo(disk1.mountPath.length));
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

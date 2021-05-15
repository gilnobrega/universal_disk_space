# Universal Disk Space
A dart package which parses total and available disk spaces on Windows and UNIX-based systems (including Linux and macOS).

## Usage
Add ``universal_disk_space`` as a dependency to your project's ``pubspec.yaml`` file

## Example

``` dart
import 'package:universal_disk_space/universal_disk_space.dart';

main () {
  //Initializes the diskspace class
  //Gets info about disks which are mounted
  DiskSpace diskspace = new DiskSpace();

  //List of disks in the system
  List<Disk> disks = diskspace.disks;

  //Prints device path, mount path, total size,  about each disk in system
  for (Disk disk in disks)
  {
      print(disk.devicePath); // e.g.: 'C:\' in Windows or '/dev/sdc' in Linux
      print(disk.mountPath); // e.g.: 'C:\' or '\\nasdrive' in Windows or '/' in Linux
      print(disk.totalSize.toString()); // in bytes
      print(disk.usedSpace.toString()); // in bytes
      print(disk.availableSpace.toString()); // in bytes
  }
  
  //Selects disk form diskspace.disks which contains '/home' folder
  //Also works with files
  Disk homedisk = diskspace.getDisk('/home');
  print(homedisk); //prints serialized version of Disk which contains '/home'
  
}

```
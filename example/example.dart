import 'package:universal_disk_space/universal_disk_space.dart';

void main () {
  //Initializes the diskspace class
  //Gets info about disks which are mounted
  var diskspace = DiskSpace();

  //List of disks in the system
  var disks = diskspace.disks;

  //Prints device path, mount path, total size,  about each disk in system
  for (var disk in disks)
  {
      print(disk.devicePath); // e.g.: 'C:\' in Windows or '/dev/sdc' in Linux
      print(disk.mountPath); // e.g.: 'C:\' or '\\nasdrive' in Windows or '/' in Linux
      print(disk.totalSize.toString()); // in bytes
      print(disk.usedSpace.toString()); // in bytes
      print(disk.availableSpace.toString()); // in bytes
  }
  
  //Selects disk form diskspace.disks which contains '/home' folder
  //Also works with files
  var homedisk = diskspace.getDisk('/home');
  print(homedisk); //prints serialized version of Disk which contains '/home'
  
}
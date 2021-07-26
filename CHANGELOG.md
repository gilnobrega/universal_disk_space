# 0.2.3
- Replaced GPL license with MIT License

# 0.2.2
- Made Disk class constant

# 0.2.1
- Uses universal_io instead of dart:io (makes disk class compatible with dart2js)

# 0.2.0
- Merged @hacker1024's Pull Request
  - improves code's structure, documentation and readability

# 0.1.21
- Added Disk.fromJson(dynamic) function

# 0.1.20
- Improved drive detection in UNIX

# 0.1.19
- Migrated code to null safety

# 0.1.18
- Formatted code

# 0.1.17
- Windows: fixed bug with previous version changes

# 0.1.16
- Windows: now gets disk space from powershell's get-wmiobject script

# 0.1.15
- Added macOS support (not tested)
- Organized command args as final List<String>

# 0.1.14
- Formatted code with dart format

# 0.1.13
- Fixed bug with absolute mountpaths in Windows

# 0.1.12
- Trims whitespaces in paths

# 0.1.11
- Filters ``Microsoft Windows Network`` from the output of ``net use`` command

# 0.1.10
- Fixed minor issue with parsing ``net use`` command in Windows

# 0.1.9
- Formatted code with ``dart format``
- Moved example.md's code into example.dart

# 0.1.8
- Formatted code according to pedantic's guidelines

# 0.1.7
- Added example.md
- Removed unnecessary "new" keywords

# 0.1.6 

- Changed df block size to 1024 bytes

# 0.1.5

- Added README.md
- Improved CHANGELOG.md

# 0.1.4 

- Unix paths are not uppercase/lowercase invariant

# 0.1.3 

- Fixed a bug with Windows network mounth paths being uppercase/lowercase invariant

# 0.1.2 

- Checks that disks are mounted in windows before adding them

# 0.1.1 

- Locates df in multiple UNIX systems, should work in macOS (untested)

# 0.1.0

- First release 
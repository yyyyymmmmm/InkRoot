# Windows Packaging

Use the project CLI for Windows builds:

```bash
dart tool/inkroot.dart build windows-debug
dart tool/inkroot.dart build windows-release
```

The GitHub Release workflow packages the Windows build automatically after a version tag is pushed.

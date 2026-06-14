# macOS Packaging

macOS helper scripts live in this directory.

Common local flow:

```bash
dart tool/inkroot.dart build macos-debug
```

The GitHub Release workflow packages the macOS app automatically after a version tag is pushed.

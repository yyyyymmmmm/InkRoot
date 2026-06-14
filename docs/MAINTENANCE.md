# Maintenance

This document describes the project workflow for versioning, checks, builds, and releases.

## Version

`pubspec.yaml` is the source of truth for the application version.

```yaml
version: 1.1.1+10101
```

Do not duplicate the app version in platform files or Dart code. Flutter passes the version into Android, iOS, macOS, Windows, and Linux build metadata.

## CLI

Use the project CLI for repeatable local work:

```bash
dart tool/inkroot.dart doctor
dart tool/inkroot.dart verify
dart tool/inkroot.dart verify --coverage
dart tool/inkroot.dart build android-debug
dart tool/inkroot.dart build ios-sim
dart tool/inkroot.dart build macos-debug
dart tool/inkroot.dart build windows-debug
dart tool/inkroot.dart build linux-debug
dart tool/inkroot.dart release v1.1.1
```

Host-specific builds require matching local tools:

- Android requires an Android SDK.
- iOS simulator requires macOS, Xcode, and CocoaPods.
- macOS requires macOS and Xcode.
- Windows requires Windows and Visual Studio C++ desktop components.
- Linux requires GTK, CMake, Ninja, and system libraries used by the desktop plugins.

The shell entrypoint remains available for compatibility:

```bash
scripts/ci.sh all
```

## Continuous Integration

Pull requests and pushes run:

- Flutter dependency resolution.
- Static analysis.
- Automated tests.
- Secret scanning.
- Android APK build.
- iOS simulator build.
- macOS build.
- Windows build.
- Linux build.

The current CI and release workflows intentionally skip the Web platform.

## Release

Release flow:

1. Update `pubspec.yaml`.
2. Update `CHANGELOG.md` and `CHANGELOG.en.md`.
3. Run `dart tool/inkroot.dart verify`.
4. Commit and push the changes.
5. Run `dart tool/inkroot.dart release vX.Y.Z`.
6. Wait for the GitHub Actions Release workflow to finish.

The tag must match the version in `pubspec.yaml`. For `version: 1.1.1+10101`, the release tag is `v1.1.1`.

GitHub Actions publishes the release assets after all release jobs pass.

## Security

Do not commit credentials, local configuration, private keys, certificates, user exports, or backup files. If a secret is exposed, revoke it and rotate the credential.

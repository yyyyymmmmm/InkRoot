# InkRoot Maintenance Guide

This document describes the project maintenance workflow used for local builds,
CI, release checks, and Android signing.

## Version Source

`pubspec.yaml` is the single source of truth for the app version.

Current version:

```yaml
version: 1.1.0+10100
```

Flutter injects this value into Android, iOS, macOS, Windows, and Linux
build metadata. Do not hardcode app versions in platform files or Dart code.

## Local CLI

Use the project CLI for repeatable local checks:

```bash
dart tool/inkroot.dart doctor
dart tool/inkroot.dart verify
dart tool/inkroot.dart verify --coverage
dart tool/inkroot.dart build android-debug
dart tool/inkroot.dart build ios-sim
dart tool/inkroot.dart build macos-debug
dart tool/inkroot.dart build windows-debug
dart tool/inkroot.dart build linux-debug
dart tool/inkroot.dart ci all
```

Host-specific builds still require the matching host OS:

| Target | Host requirement |
| --- | --- |
| iOS simulator | macOS + Xcode + CocoaPods |
| macOS | macOS |
| Windows | Windows + Visual Studio C++ desktop workload |
| Linux | Linux + GTK/CMake/Ninja dependencies + system SQLite |
| Android | Any host with Android SDK |

The project configures `package:sqlite3` to use the system SQLite library in
`pubspec.yaml` hooks. This avoids downloading prebuilt SQLite binaries during
desktop builds. macOS normally provides SQLite; Linux CI installs the required
system packages before building.

The legacy shell entrypoint is still available:

```bash
scripts/ci.sh all
```

It delegates to `dart tool/inkroot.dart`.

## GitHub Actions

`.github/workflows/ci.yml` runs:

- `flutter analyze`
- `flutter test --coverage`
- secret scanning with Gitleaks
- Android APK build
- iOS simulator build
- macOS debug build
- Windows debug build
- Linux debug build

Artifacts are uploaded from each platform job.

Manual release builds can be started from GitHub Actions with
`workflow_dispatch` and `release_build=true`.

## Android Release Signing

Android release signing is intentionally kept out of Git.

Local files:

```text
android/key.properties
android/inkroot-new-release.keystore
```

Both files are ignored by Git. `android/app/build.gradle` signs release builds
only when all signing fields are present.

Expected `android/key.properties` shape:

```properties
storeFile=../inkroot-new-release.keystore
storePassword=...
keyAlias=...
keyPassword=...
```

For GitHub Actions release builds, configure these repository secrets:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64 encoded keystore file |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |

Generate the base64 value locally:

```bash
base64 -i android/inkroot-new-release.keystore | pbcopy
```

On Linux:

```bash
base64 -w 0 android/inkroot-new-release.keystore
```

## Release Checklist

1. Update `pubspec.yaml` version.
2. Update `CHANGELOG.md` and `CHANGELOG.en.md`.
3. Run `dart tool/inkroot.dart verify`.
4. Build the required targets using `dart tool/inkroot.dart build <target>`.
5. Run the app on at least one real device or simulator for each changed platform.
6. Create a GitHub Release and upload build artifacts.
7. Confirm no signing keys, tokens, or local config files are included in Git.

## Security Baseline

Never commit:

- Personal access tokens
- `android/key.properties`
- Keystores, certificates, provisioning profiles
- API keys or service account files
- User data exports or backups

If a token or key is exposed, revoke it immediately and rotate the credential.

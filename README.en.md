# InkRoot

InkRoot is a cross-platform note-taking app for personal knowledge capture. It works locally and can also connect to a self-hosted Memos server for sync. The app supports Markdown rendering, images, tags, reminders, search, WebDAV backup, import/export, and AI-assisted writing.

[Latest release](https://github.com/yyyyymmmmm/InkRoot/releases/latest) · [Issues](https://github.com/yyyyymmmmm/InkRoot/issues) · [中文](README.md)

## Current Version

`1.1.2`

This release fixes Memos account profile loading after login and continues to improve editing, home feed rendering, image preview, WebDAV backup, Memos compatibility, timeline merging, localization, and the release workflow.

Highlights:

- Memos profile loading now falls back across v0.21, v0.22-v0.25, and v0.26+ account APIs after login.
- Requests support both Bearer Token and Memos Cookie authentication to reduce self-hosted server and reverse-proxy compatibility failures.
- Login errors now distinguish credential, token, network, TLS, and server response failures.
- Home feed rendering keeps user line breaks and spacing.
- Expand controls are based on rendered visible content.
- Image preview supports tap-to-dismiss, original image viewing, and multi-image browsing.
- WebDAV backup supports image attachment options and improved folder creation, progress, and error handling.
- Sync and refresh preserve note creation time to keep activity heatmaps stable.
- The project CLI covers verification, builds, and release tags.
- GitHub Actions covers Android, iOS, macOS, Windows, and Linux.

## Features

- Local notes and Memos sync.
- Markdown rendering, todos, links, images, and tags.
- Hierarchical tags such as `#work/projectA`.
- Full-text search, pinning, reminders, and random review.
- Image upload, preview, saving, and multi-image browsing.
- WebDAV backup and restore, with optional image backup.
- Import from Flomo, WeRead, and other sources.
- AI-assisted writing and custom prompts.
- Chinese and English UI.
- Android, iOS, macOS, Windows, and Linux builds.

## Download

Release assets are available on [GitHub Releases](https://github.com/yyyyymmmmm/InkRoot/releases).

Android users can install the APK.
Windows users can download and run the packaged app.
Linux users can extract and run the packaged app.
iOS and macOS packages are currently intended for test distribution.

## Development

After installing Flutter:

```bash
flutter pub get
dart tool/inkroot.dart verify
```

Common commands:

```bash
dart tool/inkroot.dart doctor
dart tool/inkroot.dart analyze
dart tool/inkroot.dart test
dart tool/inkroot.dart build android-debug
dart tool/inkroot.dart build ios-sim
dart tool/inkroot.dart build macos-debug
dart tool/inkroot.dart build windows-debug
dart tool/inkroot.dart build linux-debug
```

Platform builds require the matching host environment. iOS and macOS require macOS with Xcode, Windows requires Visual Studio C++ desktop components, and Linux requires GTK, CMake, and Ninja.

## Release

The app version is managed in `pubspec.yaml`:

```yaml
version: 1.1.2+10102
```

Release command:

```bash
dart tool/inkroot.dart release v1.1.2
```

The command creates and pushes a version tag. GitHub Actions then verifies, builds, and publishes Android, iOS, macOS, Windows, and Linux assets.

## Documentation

- [Maintenance guide](docs/MAINTENANCE.md)
- [Changelog](CHANGELOG.en.md)
- [Security policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)

## License

InkRoot is released under the MIT License. See [LICENSE](LICENSE).

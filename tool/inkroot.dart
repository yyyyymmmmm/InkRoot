import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  final cli = InkRootCli();
  exitCode = await cli.run(args);
}

class InkRootCli {
  static const String _cloudVerifyAppId = '10002';
  static const String _androidReleaseCertSha256 =
      '7A:00:C9:A1:AC:E1:AC:15:0E:79:0C:9D:7A:5B:FC:37:A3:F1:A1:2F:0D:F5:9D:ED:86:27:17:93:C8:40:99:8D';

  Future<int> run(List<String> args) async {
    if (args.isEmpty || args.first == 'help' || args.first == '--help') {
      _printHelp();
      return 0;
    }

    try {
      switch (args.first) {
        case 'version':
          _printVersion();
          return 0;
        case 'doctor':
          await _run(['flutter', 'doctor', '-v']);
          return 0;
        case 'deps':
          await _deps();
          return 0;
        case 'analyze':
          await _analyze();
          return 0;
        case 'test':
          await _test(coverage: args.contains('--coverage'));
          return 0;
        case 'verify':
          await _verify(coverage: args.contains('--coverage'));
          return 0;
        case 'store-check':
          await _storeCheck();
          return 0;
        case 'ci':
          await _verify(coverage: args.contains('--coverage'));
          await _build(args.length > 1 ? args[1] : 'all');
          return 0;
        case 'build':
          await _build(args.length > 1 ? args[1] : 'all');
          return 0;
        case 'run':
          await _runApp(args.length > 1 ? args[1] : 'default');
          return 0;
        case 'release':
          await _release(args);
          return 0;
        case 'clean':
          await _run(['flutter', 'clean']);
          return 0;
        default:
          stderr.writeln('Unknown command: ${args.first}');
          _printHelp();
          return 2;
      }
    } on ToolExit catch (error) {
      stderr.writeln(error.message);
      return error.code;
    }
  }

  Future<void> _verify({required bool coverage}) async {
    await _deps();
    await _analyze();
    await _test(coverage: coverage);
  }

  Future<void> _deps() => _run(['flutter', 'pub', 'get']);

  Future<void> _analyze() => _run(['flutter', 'analyze']);

  Future<void> _test({required bool coverage}) {
    final args = ['flutter', 'test'];
    if (coverage) {
      args.add('--coverage');
    }
    return _run(args);
  }

  Future<void> _storeCheck() async {
    final version = _readVersion();
    if (!RegExp(r'^\d+\.\d+\.\d+\+\d+$').hasMatch(version)) {
      throw ToolExit(
        2,
        'pubspec version must be semver plus integer build number, got $version.',
      );
    }

    await _assertFileContains(
      'android/app/build.gradle',
      'applicationId "com.didichou.inkroot"',
      'Android applicationId must stay com.didichou.inkroot.',
    );
    await _assertFileContains(
      'android/app/build.gradle',
      'versionCode flutter.versionCode',
      'Android versionCode must come from pubspec.yaml.',
    );
    await _assertFileContains(
      'android/app/build.gradle',
      'versionName flutter.versionName',
      'Android versionName must come from pubspec.yaml.',
    );
    await _assertFileContains(
      'android/app/build.gradle',
      'applicationName: "android.app.Application"',
      'Android manifest placeholders must keep Flutter applicationName.',
    );
    await _assertFileContains(
      'android/app/build.gradle',
      'buildConfig true',
      'Android native code requires generated BuildConfig.',
    );
    await _assertFileContains(
      'android/app/build.gradle',
      'Release builds require android/key.properties',
      'Android release builds must fail when signing credentials are missing.',
    );
    await _assertFileDoesNotContain(
      'android/app/src/main/AndroidManifest.xml',
      'android.permission.SCHEDULE_EXACT_ALARM',
      'Do not request exact-alarm special access for store builds.',
    );
    await _assertFileDoesNotContain(
      'android/app/src/main/AndroidManifest.xml',
      'android.permission.READ_MEDIA_IMAGES',
      'Do not request broad Android 13+ photo-library access.',
    );
    await _assertFileDoesNotContain(
      'android/app/src/main/AndroidManifest.xml',
      'android:requestLegacyExternalStorage="true"',
      'Do not use legacy external storage in store builds.',
    );

    if (Platform.isMacOS) {
      await _run([
        'plutil',
        '-lint',
        'ios/Runner/Info.plist',
        'ios/Runner/Runner.entitlements',
        'ios/Runner/PrivacyInfo.xcprivacy',
      ]);
    }
    await _assertFileContains(
      'ios/Runner/Info.plist',
      'CFBundleShortVersionString',
      'iOS Info.plist must expose bundle version metadata.',
    );
    await _assertFileContains(
      'ios/Runner.xcodeproj/project.pbxproj',
      'PrivacyInfo.xcprivacy in Resources',
      'PrivacyInfo.xcprivacy must be copied into Runner.app.',
    );
    await _assertFileContains(
      'lib/config/app_config.dart',
      'accountDeletionUrl',
      'Account deletion URL must stay centrally configured.',
    );
    await _assertFileContains(
      'lib/routes/app_router.dart',
      '/account-deletion',
      'Account deletion route must be available in app.',
    );
    await _assertFileContains(
      '.github/workflows/release.yml',
      'android-aab',
      'Release workflow must build the Play Store AAB.',
    );
    await _assertFileContains(
      '.github/workflows/release.yml',
      r'Missing required release secret: $name',
      'Release workflow must fail when required release secrets are missing.',
    );
    await _assertFileContains(
      '.github/workflows/release.yml',
      _androidReleaseCertSha256,
      'Release workflow must verify the Android release signing certificate.',
    );
    await _assertFileContains(
      '.github/workflows/release.yml',
      'expected release certificate found',
      'Release workflow must verify Android package certificates.',
    );
    await _assertFileContains(
      'lib/config/app_config.dart',
      "static const String appId = '$_cloudVerifyAppId';",
      'Cloud verification AppID must stay fixed in source.',
    );
    await _assertFileContains(
      '.github/workflows/release.yml',
      'CLOUD_VERIFY_APP_KEY',
      'Release workflow must inject the cloud verification app key.',
    );

    stdout.writeln('Store checks passed for $version.');
  }

  Future<void> _release(List<String> args) async {
    if (args.length < 2) {
      throw ToolExit(2, 'Usage: dart tool/inkroot.dart release v1.1.0');
    }

    final tag = args[1];
    if (!RegExp(r'^v\d+\.\d+\.\d+([+-][0-9A-Za-z.-]+)?$').hasMatch(tag)) {
      throw ToolExit(2, 'Release tag must look like v1.1.0.');
    }

    final currentVersion = _readVersion().split('+').first;
    final expectedTag = 'v$currentVersion';
    if (tag != expectedTag) {
      throw ToolExit(
        2,
        'Tag $tag does not match pubspec version $currentVersion.',
      );
    }

    await _run(['git', 'diff', '--quiet']);
    await _run(['git', 'diff', '--cached', '--quiet']);

    if (await _gitTagExists(tag)) {
      throw ToolExit(2, 'Tag already exists locally: $tag');
    }
    if (await _remoteTagExists(tag)) {
      throw ToolExit(2, 'Tag already exists on origin: $tag');
    }

    await _run(['git', 'tag', '-a', tag, '-m', 'InkRoot $tag']);
    await _run(['git', 'push', 'origin', tag]);
    stdout.writeln('Release tag pushed: $tag');
    stdout.writeln('GitHub Actions will build and publish the release.');
  }

  Future<void> _build(String target) async {
    switch (target) {
      case 'all':
        for (final buildTarget in _hostBuildTargets()) {
          await _build(buildTarget);
        }
        _printSkippedTargets();
        return;
      case 'android':
      case 'android-debug':
        await _run(_flutterBuildCommand(['apk', '--debug']));
        return;
      case 'android-release':
        await _run(_flutterBuildCommand(['apk', '--release']));
        return;
      case 'android-aab':
      case 'android-appbundle':
        await _run(_flutterBuildCommand(['appbundle', '--release']));
        return;
      case 'ios':
      case 'ios-sim':
        _requireHost(target, Platform.isMacOS, 'macOS with Xcode');
        await _clearAppleExtendedAttributes();
        await _disableSwiftPackageManager();
        await _podInstall('ios');
        await _run(_flutterBuildCommand(['ios', '--simulator', '--debug']));
        return;
      case 'ios-unsigned-ipa':
        _requireHost(target, Platform.isMacOS, 'macOS with Xcode');
        await _clearAppleExtendedAttributes();
        await _disableSwiftPackageManager();
        await _run(
          ['bash', 'scripts/build_unsigned_ipa.sh'],
          environment: _dartDefineEnvironment(),
        );
        return;
      case 'macos-debug':
        _requireHost(target, Platform.isMacOS, 'macOS');
        await _clearAppleExtendedAttributes();
        await _run(['flutter', 'config', '--enable-macos-desktop']);
        await _disableSwiftPackageManager();
        await _run(_flutterBuildCommand(['macos', '--debug']));
        return;
      case 'macos':
      case 'macos-release':
        _requireHost(target, Platform.isMacOS, 'macOS');
        await _clearAppleExtendedAttributes();
        await _run(['flutter', 'config', '--enable-macos-desktop']);
        await _disableSwiftPackageManager();
        await _run(_flutterBuildCommand(['macos', '--release']));
        return;
      case 'windows-debug':
        _requireHost(target, Platform.isWindows, 'Windows');
        await _run(['flutter', 'config', '--enable-windows-desktop']);
        await _run(_flutterBuildCommand(['windows', '--debug']));
        return;
      case 'windows':
      case 'windows-release':
        _requireHost(target, Platform.isWindows, 'Windows');
        await _run(['flutter', 'config', '--enable-windows-desktop']);
        await _run(_flutterBuildCommand(['windows', '--release']));
        return;
      case 'linux-debug':
        _requireHost(target, Platform.isLinux, 'Linux');
        await _run(['flutter', 'config', '--enable-linux-desktop']);
        await _run(_flutterBuildCommand(['linux', '--debug']));
        return;
      case 'linux':
      case 'linux-release':
        _requireHost(target, Platform.isLinux, 'Linux');
        await _run(['flutter', 'config', '--enable-linux-desktop']);
        await _run(_flutterBuildCommand(['linux', '--release']));
        return;
      default:
        throw ToolExit(2, 'Unknown build target: $target');
    }
  }

  List<String> _hostBuildTargets() {
    final targets = <String>['android-debug'];
    if (Platform.isMacOS) {
      targets.addAll(['ios-sim', 'macos-debug']);
    } else if (Platform.isWindows) {
      targets.add('windows-debug');
    } else if (Platform.isLinux) {
      targets.add('linux-debug');
    }
    return targets;
  }

  void _printSkippedTargets() {
    final skipped = <String>[];
    if (!Platform.isMacOS) {
      skipped.addAll(['ios-sim', 'macos-debug']);
    }
    if (!Platform.isWindows) {
      skipped.add('windows-debug');
    }
    if (!Platform.isLinux) {
      skipped.add('linux-debug');
    }
    if (skipped.isNotEmpty) {
      stdout.writeln('Skipped host-specific targets: ${skipped.join(', ')}');
    }
  }

  Future<void> _podInstall(String directory) async {
    await _run(
      ['pod', 'install'],
      workingDirectory: directory,
      environment: {
        'LANG': 'en_US.UTF-8',
        'LC_ALL': 'en_US.UTF-8',
      },
    );
  }

  Future<void> _disableSwiftPackageManager() {
    return _run(['flutter', 'config', '--no-enable-swift-package-manager']);
  }

  Future<void> _clearAppleExtendedAttributes() async {
    if (!Platform.isMacOS) {
      return;
    }

    final script = File('scripts/clean_apple_xattrs.sh');
    if (await script.exists()) {
      await _run(['bash', script.path]);
    }
  }

  Future<void> _runApp(String target) async {
    switch (target) {
      case 'default':
        await _run(_flutterRunCommand(<String>[]));
        return;
      case 'ios':
      case 'ios-sim':
        _requireHost(target, Platform.isMacOS, 'macOS with Xcode');
        await _clearAppleExtendedAttributes();
        await _run(
          _flutterRunCommand([
            '-d',
            _envValue('IOS_SIMULATOR_ID') ?? 'iPhone',
          ]),
        );
        return;
      case 'macos':
        _requireHost(target, Platform.isMacOS, 'macOS');
        await _clearAppleExtendedAttributes();
        await _run(_flutterRunCommand(['-d', 'macos']));
        return;
      default:
        await _run(_flutterRunCommand(['-d', target]));
        return;
    }
  }

  List<String> _flutterBuildCommand(List<String> args) => [
        'flutter',
        'build',
        ...args,
        ..._dartDefines(isRelease: _isReleaseBuildArgs(args)),
      ];

  List<String> _flutterRunCommand(List<String> args) => [
        'flutter',
        'run',
        ...args,
        ..._dartDefines(isRelease: args.contains('--release')),
      ];

  List<String> _dartDefines({required bool isRelease}) {
    final defines = <String>[];
    final cloudVerifyAppKey = _envValue('CLOUD_VERIFY_APP_KEY');
    final environment = _envValue('ENVIRONMENT');

    if (isRelease && cloudVerifyAppKey == null) {
      throw ToolExit(
        2,
        'Release builds require CLOUD_VERIFY_APP_KEY.',
      );
    }

    defines.add(
      '--dart-define=ENVIRONMENT=${environment ?? (isRelease ? 'production' : 'development')}',
    );

    if (cloudVerifyAppKey != null) {
      defines.add('--dart-define=CLOUD_VERIFY_APP_KEY=$cloudVerifyAppKey');
    }
    for (final key in _optionalBuildDefineKeys) {
      final value = _envValue(key);
      if (value != null) {
        defines.add('--dart-define=$key=$value');
      }
    }

    return defines;
  }

  Map<String, String>? _dartDefineEnvironment() {
    final values = <String, String>{};
    values['ENVIRONMENT'] = _envValue('ENVIRONMENT') ?? 'production';
    if (_envValue('CLOUD_VERIFY_APP_KEY') == null) {
      throw ToolExit(
        2,
        'Release builds require CLOUD_VERIFY_APP_KEY.',
      );
    }
    for (final key in [
      'CLOUD_VERIFY_APP_KEY',
      ..._optionalBuildDefineKeys,
    ]) {
      final value = _envValue(key);
      if (value != null) {
        values[key] = value;
      }
    }
    return values;
  }

  static const List<String> _optionalBuildDefineKeys = [
    'UMENG_ANDROID_APPKEY',
    'UMENG_IOS_APPKEY',
    'UMENG_CHANNEL',
    'SENTRY_DSN',
  ];

  bool _isReleaseBuildArgs(List<String> args) =>
      args.contains('--release') ||
      (args.isNotEmpty &&
          (args.first == 'apk' ||
              args.first == 'appbundle' ||
              args.first == 'macos' ||
              args.first == 'windows' ||
              args.first == 'linux') &&
          !args.contains('--debug') &&
          !args.contains('--profile'));

  String? _envValue(String key) {
    final value = Platform.environment[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  void _requireHost(String target, bool condition, String requirement) {
    if (!condition) {
      throw ToolExit(3, '$target requires $requirement.');
    }
  }

  Future<void> _run(
    List<String> command, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    stdout.writeln('\n> ${command.join(' ')}');
    final process = await Process.start(
      command.first,
      command.sublist(1),
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: Platform.isWindows,
    );

    final output = stdout.addStream(process.stdout);
    final errors = stderr.addStream(process.stderr);
    final code = await process.exitCode;
    await Future.wait([output, errors]);

    if (code != 0) {
      throw ToolExit(code, 'Command failed with exit code $code.');
    }
  }

  void _printVersion() {
    stdout.writeln('version: ${_readVersion()}');
  }

  String _readVersion() {
    final pubspec = File('pubspec.yaml');
    final versionLine = pubspec
        .readAsLinesSync()
        .firstWhere((line) => line.trimLeft().startsWith('version:'));
    return versionLine.split(':').sublist(1).join(':').trim();
  }

  Future<bool> _gitTagExists(String tag) async {
    return _runForStatus(
      ['git', 'rev-parse', '-q', '--verify', 'refs/tags/$tag'],
    );
  }

  Future<bool> _remoteTagExists(String tag) async {
    return _runForStatus(
      ['git', 'ls-remote', '--exit-code', '--tags', 'origin', tag],
    );
  }

  Future<bool> _runForStatus(List<String> command) async {
    final process = await Process.start(
      command.first,
      command.sublist(1),
      runInShell: Platform.isWindows,
    );
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);
    final code = await process.exitCode;
    return code == 0;
  }

  Future<void> _assertFileContains(
    String path,
    String needle,
    String message,
  ) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ToolExit(2, 'Missing required file: $path');
    }
    final content = await file.readAsString();
    if (!content.contains(needle)) {
      throw ToolExit(2, '$message ($path)');
    }
  }

  Future<void> _assertFileDoesNotContain(
    String path,
    String needle,
    String message,
  ) async {
    final file = File(path);
    if (!await file.exists()) {
      throw ToolExit(2, 'Missing required file: $path');
    }
    final content = await file.readAsString();
    if (content.contains(needle)) {
      throw ToolExit(2, '$message ($path)');
    }
  }

  void _printHelp() {
    stdout.writeln('''
InkRoot maintenance CLI

Usage:
  dart tool/inkroot.dart <command> [target]

Commands:
  doctor                         Run flutter doctor -v
  deps                           Run flutter pub get
  analyze                        Run flutter analyze
  test [--coverage]              Run Flutter tests
  verify [--coverage]            Run deps + analyze + tests
  store-check                    Validate store-submission critical metadata
  ci [target] [--coverage]       Run verify, then build target
  build [target]                 Build one target or all host-supported targets
  run [target]                   Run app with shared dart-defines
  clean                          Run flutter clean
  version                        Print pubspec version
  release vX.Y.Z                 Push a release tag for GitHub Actions

Build targets:
  all                            Android + host-specific desktop/mobile
  android-debug | android-release | android-aab
  ios-sim | ios-unsigned-ipa     macOS only
  macos-debug | macos-release    macOS only
  windows-debug | windows-release Windows only
  linux-debug | linux-release    Linux only
''');
  }
}

class ToolExit implements Exception {
  ToolExit(this.code, this.message);

  final int code;
  final String message;
}

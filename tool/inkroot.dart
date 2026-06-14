import 'dart:async';
import 'dart:io';

Future<void> main(List<String> args) async {
  final cli = InkRootCli();
  exitCode = await cli.run(args);
}

class InkRootCli {
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
        case 'ci':
          await _verify(coverage: args.contains('--coverage'));
          await _build(args.length > 1 ? args[1] : 'all');
          return 0;
        case 'build':
          await _build(args.length > 1 ? args[1] : 'all');
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
        await _run(['flutter', 'build', 'apk', '--debug']);
        return;
      case 'android-release':
        await _run(['flutter', 'build', 'apk', '--release']);
        return;
      case 'ios':
      case 'ios-sim':
        _requireHost(target, Platform.isMacOS, 'macOS with Xcode');
        await _podInstall('ios');
        await _run(['flutter', 'build', 'ios', '--simulator', '--debug']);
        return;
      case 'ios-unsigned-ipa':
        _requireHost(target, Platform.isMacOS, 'macOS with Xcode');
        await _run(['bash', 'scripts/build_unsigned_ipa.sh']);
        return;
      case 'macos':
      case 'macos-debug':
        _requireHost(target, Platform.isMacOS, 'macOS');
        await _run(['flutter', 'config', '--enable-macos-desktop']);
        await _run(['flutter', 'build', 'macos', '--debug']);
        return;
      case 'macos-release':
        _requireHost(target, Platform.isMacOS, 'macOS');
        await _run(['flutter', 'config', '--enable-macos-desktop']);
        await _run(['flutter', 'build', 'macos', '--release']);
        return;
      case 'windows':
      case 'windows-debug':
        _requireHost(target, Platform.isWindows, 'Windows');
        await _run(['flutter', 'config', '--enable-windows-desktop']);
        await _run(['flutter', 'build', 'windows', '--debug']);
        return;
      case 'windows-release':
        _requireHost(target, Platform.isWindows, 'Windows');
        await _run(['flutter', 'config', '--enable-windows-desktop']);
        await _run(['flutter', 'build', 'windows', '--release']);
        return;
      case 'linux':
      case 'linux-debug':
        _requireHost(target, Platform.isLinux, 'Linux');
        await _run(['flutter', 'config', '--enable-linux-desktop']);
        await _run(['flutter', 'build', 'linux', '--debug']);
        return;
      case 'linux-release':
        _requireHost(target, Platform.isLinux, 'Linux');
        await _run(['flutter', 'config', '--enable-linux-desktop']);
        await _run(['flutter', 'build', 'linux', '--release']);
        return;
      case 'web':
      case 'web-release':
        await _run(['flutter', 'build', 'web', '--release']);
        return;
      default:
        throw ToolExit(2, 'Unknown build target: $target');
    }
  }

  List<String> _hostBuildTargets() {
    final targets = <String>['android-debug', 'web-release'];
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
    final pubspec = File('pubspec.yaml');
    final versionLine = pubspec
        .readAsLinesSync()
        .firstWhere((line) => line.trimLeft().startsWith('version:'));
    stdout.writeln(versionLine.trim());
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
  ci [target] [--coverage]       Run verify, then build target
  build [target]                 Build one target or all host-supported targets
  clean                          Run flutter clean
  version                        Print pubspec version

Build targets:
  all                            Android + Web + host-specific desktop/mobile
  android-debug | android-release
  ios-sim | ios-unsigned-ipa     macOS only
  macos-debug | macos-release    macOS only
  windows-debug | windows-release Windows only
  linux-debug | linux-release    Linux only
  web-release
''');
  }
}

class ToolExit implements Exception {
  ToolExit(this.code, this.message);

  final int code;
  final String message;
}

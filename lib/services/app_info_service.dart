import 'package:inkroot/config/app_identity.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Single source of truth for app version/build number.
///
/// Values come from the packaged metadata (derived from `pubspec.yaml`).
class AppInfoService {
  static bool _initialized = false;
  static late PackageInfo _info;

  static Future<void> init() async {
    if (_initialized) {
      return;
    }
    _info = await PackageInfo.fromPlatform();
    _initialized = true;
  }

  static String get appName => _initialized ? _info.appName : AppIdentity.name;

  /// e.g. "1.0.9"
  static String get version => _initialized ? _info.version : '0.0.0';

  /// e.g. "10009"
  static String get buildNumber => _initialized ? _info.buildNumber : '0';

  /// e.g. "1.0.9+10009"
  static String get fullVersion => '$version+$buildNumber';

  /// e.g. "InkRoot/1.0.9+10009"
  static String get userAgent => '$appName/$fullVersion';
}

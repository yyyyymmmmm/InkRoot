/// Product identity values that should stay consistent across the app.
///
/// Runtime version/build metadata still comes from `pubspec.yaml` through
/// `PackageInfo`; these values cover brand, bundle, and default storage names.
class AppIdentity {
  const AppIdentity._();

  static const String name = 'InkRoot';
  static const String displayName = 'InkRoot';
  static const String fullName = 'InkRoot-墨鸣笔记';
  static const String packageName = 'com.didichou.inkroot';
  static const String defaultWebDavPath = '/InkRoot/';
  static const String botName = 'InkRoot_Bot';
}

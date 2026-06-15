class AssetConfig {
  // 本地资源
  static const String localLogo = 'assets/images/logo.png';

  // CDN 资源 URL。默认留空，正式版优先使用包内资源，避免请求占位域名。
  static const String cdnBaseUrl = String.fromEnvironment('ASSET_CDN_BASE_URL');

  // 获取图片URL
  static String getImageUrl(String imageName, {bool useLocal = false}) {
    if (useLocal || cdnBaseUrl.isEmpty) {
      return 'assets/images/$imageName';
    }
    return '$cdnBaseUrl/images/$imageName';
  }

  // 主题相关图片
  static const String lightThemeImage = 'baise.png';
  static const String darkThemeImage = 'heise.png';

  // 获取主题图片URL
  static String getThemeImageUrl(bool isDarkMode, {bool useLocal = false}) {
    final imageName = isDarkMode ? darkThemeImage : lightThemeImage;
    return getImageUrl(imageName, useLocal: useLocal);
  }
}

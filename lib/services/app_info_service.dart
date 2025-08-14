import 'package:package_info_plus/package_info_plus.dart';

class AppInfoService {
  static PackageInfo? _packageInfo;
  
  /// Initialize package info - should be called once at app startup
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }
  
  /// Get app version from pubspec.yaml
  static String get version {
    return _packageInfo?.version ?? '0.0.1';
  }
  
  /// Get app name
  static String get appName {
    return _packageInfo?.appName ?? 'LaChispa';
  }
  
  /// Get build number
  static String get buildNumber {
    return _packageInfo?.buildNumber ?? '1';
  }
  
  /// Get package name/bundle ID
  static String get packageName {
    return _packageInfo?.packageName ?? 'com.lachispa.wallet';
  }
  
  /// Get full version string with build number
  static String get fullVersion {
    return '${version}+${buildNumber}';
  }
  
  /// Get formatted version for UI display
  static String getVersionDisplay(String locale) {
    switch (locale) {
      case 'es':
        return 'Versión: $version';
      case 'pt':
        return 'Versão: $version';
      default: // en
        return 'Version: $version';
    }
  }
  
  /// Get User-Agent string for HTTP requests
  static String getUserAgent([String? platform]) {
    final platformSuffix = platform ?? 'Wallet';
    return 'LaChispa-$platformSuffix/$version';
  }
}
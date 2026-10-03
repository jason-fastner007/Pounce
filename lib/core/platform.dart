import 'package:flutter/foundation.dart';

/// Platform info without dart:io (web-safe).
abstract final class Platform {
  static bool get isWeb => kIsWeb;
  static bool get isDesktop =>
      !kIsWeb &&
      const {TargetPlatform.linux, TargetPlatform.windows, TargetPlatform.macOS}.contains(defaultTargetPlatform);
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isApple =>
      !kIsWeb && const {TargetPlatform.iOS, TargetPlatform.macOS}.contains(defaultTargetPlatform);
}

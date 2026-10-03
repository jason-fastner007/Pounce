import 'package:flutter/foundation.dart';

/// Where an update comes from.
enum UpdateChannel { github, play }

/// An available update (immutable).
@immutable
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.channel,
    this.changelog = '',
    this.assetUrl,
    this.assetName,
    this.assetSize = 0,
    this.sha256,
    this.pageUrl,
    this.publishedAt,
  });

  /// Version name without "v", e.g. "0.3.0".
  final String version;
  final UpdateChannel channel;

  /// Changes (Markdown from the release).
  final String changelog;

  /// GitHub only: direct download URL of the matching APK, its size and SHA-256 checksum (hex).
  final String? assetUrl;
  final String? assetName;
  final int assetSize;
  final String? sha256;

  /// Release page (to read in the browser).
  final String? pageUrl;
  final DateTime? publishedAt;

  /// Can be downloaded directly (otherwise only the release page or the Play dialog).
  bool get downloadable => assetUrl != null && sha256 != null;
}

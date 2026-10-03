import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'github_updater.dart';
import 'play_updater.dart';
import 'release_provider.dart';

export 'models/update_info.dart';
export 'release_provider.dart';

/// GitHub repository of the releases ("owner/repo"). Empty = updater off (no repo yet).
const githubRepo = String.fromEnvironment('POUNCE_GITHUB_REPO');

const _channel = MethodChannel('pounce/updates');

/// Installed version and distribution channel (from the native side – no extra package).
Future<({String version, String store})?> installedApp() async {
  try {
    final r = await _channel.invokeMapMethod<String, Object?>('app');
    if (r == null) return null;
    return (version: r['version'] as String, store: r['store'] as String);
  } catch (_) {
    return null; // platform without an update channel (desktop, web)
  }
}

/// Matching [ReleaseProvider] for this build, null = no updates possible (desktop, web, no
/// repo). The rest of the app only knows the interface.
Future<ReleaseProvider?> createReleaseProvider(http.Client client) async {
  final app = await installedApp();
  if (app == null) return null;
  if (app.store == 'play') return PlayReleaseProvider(_channel);
  if (githubRepo.isEmpty) return null;
  return GitHubReleaseProvider(
    repo: githubRepo,
    client: client,
    userAgent: 'Pounce-Client/${app.version}',
    downloadDir: () async => Directory('${(await getApplicationCacheDirectory()).path}/updates'),
    installer: const ChannelApkInstaller(_channel),
  );
}

/// [ApkInstaller] via the native channel (FileProvider + system installer, "github" flavor only).
class ChannelApkInstaller implements ApkInstaller {
  const ChannelApkInstaller(this._ch);
  final MethodChannel _ch;

  @override
  Future<bool> canInstall() async => await _ch.invokeMethod<bool>('canInstall') ?? false;

  @override
  Future<void> requestPermission() => _ch.invokeMethod('allowInstall');

  @override
  Future<void> install(String path) => _ch.invokeMethod('install', path);
}

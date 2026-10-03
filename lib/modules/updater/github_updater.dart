import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'models/update_info.dart';
import 'release_provider.dart';

/// Hands a downloaded APK to the system installer (platform-specific, see
/// [ChannelApkInstaller]). Separate so the provider is testable without a device.
abstract class ApkInstaller {
  Future<bool> canInstall();

  /// Opens the system setting "Install unknown apps" for this app.
  Future<void> requestPermission();

  Future<void> install(String path);
}

/// Updates from GitHub Releases ("github" flavor, F-Droid compatible).
///
/// Privacy: a single request to the official REST API, neutral user agent
/// ("Pounce-Client/`version`"), no device or advertising IDs, no cookies. It only checks on
/// user action or when the setting "Check for updates automatically" is on. Downloads
/// happen only after consent in the update dialog – never in the background.
class GitHubReleaseProvider implements ReleaseProvider {
  GitHubReleaseProvider({
    required this.repo,
    required this.client,
    required this.userAgent,
    required this.downloadDir,
    required this.installer,
    this.abi = 'arm64-v8a',
    this.flavor = 'github',
  });

  /// "owner/repo".
  final String repo;
  final http.Client client;
  final String userAgent;

  /// Download target (app cache, "updates/" – only this folder is shared with the installer).
  final Future<Directory> Function() downloadDir;
  final ApkInstaller installer;

  /// Matching APK: CPU architecture and distribution channel in the file name.
  final String abi;
  final String flavor;

  Map<String, String> get _headers => {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': userAgent,
  };

  @override
  Future<UpdateInfo?> checkForUpdate({required String currentVersion}) async {
    try {
      final res = await client
          .get(Uri.https('api.github.com', '/repos/$repo/releases/latest'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final tag = (j['tag_name'] as String? ?? '').replaceFirst(RegExp(r'^[vV]'), '');
      if (tag.isEmpty || !isNewer(tag, currentVersion)) return null;
      final assets = [for (final a in (j['assets'] as List? ?? const [])) a as Map<String, dynamic>];
      final apk = _pickApk(assets);
      return UpdateInfo(
        version: tag,
        channel: UpdateChannel.github,
        changelog: j['body'] as String? ?? '',
        assetUrl: apk?['browser_download_url'] as String?,
        assetName: apk?['name'] as String?,
        assetSize: (apk?['size'] as num?)?.toInt() ?? 0,
        sha256: apk == null ? null : await _checksum(apk, assets),
        pageUrl: j['html_url'] as String?,
        publishedAt: DateTime.tryParse(j['published_at'] as String? ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  /// Prefers the APK for this architecture and channel, otherwise the universal one.
  Map<String, dynamic>? _pickApk(List<Map<String, dynamic>> assets) {
    final apks = assets.where((a) => (a['name'] as String? ?? '').endsWith('.apk')).toList();
    int score(Map<String, dynamic> a) {
      final n = (a['name'] as String).toLowerCase();
      return (n.contains(abi) ? 4 : 0) + (n.contains(flavor) ? 2 : 0) + (n.contains('universal') ? 1 : 0);
    }

    apks.sort((a, b) => score(b) - score(a));
    final best = apks.firstOrNull;
    return best != null && score(best) > 0 ? best : null;
  }

  /// SHA-256 from the API's asset "digest", otherwise from a SHA256SUMS file in the release.
  Future<String?> _checksum(Map<String, dynamic> apk, List<Map<String, dynamic>> assets) async {
    final digest = apk['digest'] as String?;
    if (digest != null && digest.startsWith('sha256:')) return digest.substring(7).toLowerCase();
    final sums = assets.where((a) => (a['name'] as String? ?? '').toUpperCase().startsWith('SHA256SUMS')).firstOrNull;
    if (sums == null) return null;
    final res = await client.get(Uri.parse(sums['browser_download_url'] as String), headers: {'User-Agent': userAgent});
    if (res.statusCode != 200) return null;
    for (final line in const LineSplitter().convert(utf8.decode(res.bodyBytes))) {
      final m = RegExp(r'^([0-9a-fA-F]{64})\s+\*?(.+)$').firstMatch(line.trim());
      if (m != null && m.group(2) == apk['name']) return m.group(1)!.toLowerCase();
    }
    return null;
  }

  @override
  Future<InstallResult> install(UpdateInfo info, {void Function(double progress)? onProgress}) async {
    if (!info.downloadable) return InstallResult.failed;
    if (!await installer.canInstall()) {
      await installer.requestPermission();
      return InstallResult.needsPermission;
    }
    final file = await download(info, onProgress: onProgress);
    if (file == null) return InstallResult.checksumMismatch;
    await installer.install(file.path);
    return InstallResult.started;
  }

  /// Downloads the asset and checks the SHA-256 sum while writing. Wrong sum: the file is deleted,
  /// result null. Throws on network errors.
  Future<File?> download(UpdateInfo info, {void Function(double progress)? onProgress}) async {
    final dir = await downloadDir();
    await dir.create(recursive: true);
    final file = File('${dir.path}/${info.assetName ?? 'pounce-${info.version}.apk'}');
    final res = await client.send(http.Request('GET', Uri.parse(info.assetUrl!))..headers['User-Agent'] = userAgent);
    if (res.statusCode != 200) throw HttpException('Download: HTTP ${res.statusCode}');
    final total = res.contentLength ?? info.assetSize;
    final sink = file.openWrite();
    final hashOut = _DigestSink();
    final hasher = sha256.startChunkedConversion(hashOut);
    var got = 0;
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
        hasher.add(chunk);
        got += chunk.length;
        if (total > 0) onProgress?.call(got / total);
      }
    } finally {
      await sink.close();
      hasher.close();
    }
    if (hashOut.value.toString() != info.sha256) {
      await file.delete();
      return null;
    }
    return file;
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

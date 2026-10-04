import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/modules/updater/github_updater.dart';
import 'package:pounce/modules/updater/release_provider.dart';

class FakeInstaller implements ApkInstaller {
  bool allowed = true;
  String? installed;
  var asked = false;

  @override
  Future<bool> canInstall() async => allowed;

  @override
  Future<void> requestPermission() async => asked = true;

  @override
  Future<void> install(String path) async => installed = path;
}

final apkBytes = utf8.encode('echte APK');
final apkHash = sha256.convert(apkBytes).toString();

Map<String, Object?> release({String tag = 'v0.3.0', bool digest = true}) => {
  'tag_name': tag,
  'body': '- Webradio\n- DJ-Player',
  'html_url': 'https://github.com/x/pounce/releases/tag/$tag',
  'published_at': '2026-10-03T18:00:00Z',
  'assets': [
    {
      'name': 'pounce-armeabi-v7a-github.apk',
      'size': 9,
      'browser_download_url': 'https://dl/v7.apk',
      'digest': 'sha256:${'0' * 64}',
    },
    {
      'name': 'pounce-arm64-v8a-github.apk',
      'size': apkBytes.length,
      'browser_download_url': 'https://dl/arm64.apk',
      if (digest) 'digest': 'sha256:$apkHash',
    },
    {'name': 'SHA256SUMS', 'size': 100, 'browser_download_url': 'https://dl/SHA256SUMS'},
  ],
};

GitHubReleaseProvider provider(http.Client c, FakeInstaller i, Directory dir) => GitHubReleaseProvider(
  repo: 'x/pounce',
  client: c,
  userAgent: 'Pounce-Client/0.2.0',
  downloadDir: () async => dir,
  installer: i,
);

void main() {
  test('compare versions', () {
    expect(isNewer('0.3.0', '0.2.0'), isTrue);
    expect(isNewer('v1.2.10', '1.2.9'), isTrue);
    expect(isNewer('0.2.0', '0.2.0+7'), isFalse);
    expect(isNewer('0.2.0-beta', '0.3.0'), isFalse);
    expect(isNewer('0.2.0', '0.2.0-beta.1'), isTrue);
    expect(isNewer('0.2.0-beta.2', '0.2.0-beta.1+8'), isTrue);
    expect(isNewer('0.2.0-beta.10', '0.2.0-beta.9'), isTrue);
    expect(isNewer('0.2.0-beta.1', '0.2.0'), isFalse);
  });

  test('new release: matching APK and checksum from "digest", neutral user agent', () async {
    final seen = <http.BaseRequest>[];
    final c = MockClient((r) async {
      seen.add(r);
      return http.Response(jsonEncode(release()), 200);
    });
    final u = await provider(c, FakeInstaller(), Directory.systemTemp).checkForUpdate(currentVersion: '0.2.0');
    expect(u!.version, '0.3.0');
    expect(u.assetName, 'pounce-arm64-v8a-github.apk');
    expect(u.sha256, apkHash);
    expect(seen.single.url.toString(), 'https://api.github.com/repos/x/pounce/releases/latest');
    expect(seen.single.headers['User-Agent'], 'Pounce-Client/0.2.0');
    expect(seen.single.headers.keys.map((k) => k.toLowerCase()), isNot(contains('authorization')));
  });

  test('beta build also sees pre-releases (not served by /releases/latest)', () async {
    final seen = <http.BaseRequest>[];
    final c = MockClient((r) async {
      seen.add(r);
      return http.Response(
        jsonEncode([
          {...release(tag: 'v0.3.0-beta.1'), 'draft': true},
          {...release(tag: 'v0.2.0-beta.2'), 'prerelease': true},
        ]),
        200,
      );
    });
    final u = await provider(c, FakeInstaller(), Directory.systemTemp).checkForUpdate(currentVersion: '0.2.0-beta.1+8');
    expect(u!.version, '0.2.0-beta.2');
    expect(seen.single.url.toString(), 'https://api.github.com/repos/x/pounce/releases?per_page=10');
  });

  test('same version or network error: no update', () async {
    final same = MockClient((_) async => http.Response(jsonEncode(release(tag: 'v0.2.0')), 200));
    expect(await provider(same, FakeInstaller(), Directory.systemTemp).checkForUpdate(currentVersion: '0.2.0'), isNull);
    final down = MockClient((_) async => throw const SocketException('offline'));
    expect(await provider(down, FakeInstaller(), Directory.systemTemp).checkForUpdate(currentVersion: '0.2.0'), isNull);
  });

  test('without "digest": checksum from SHA256SUMS', () async {
    final c = MockClient(
      (r) async => r.url.path.endsWith('SHA256SUMS')
          ? http.Response('$apkHash  pounce-arm64-v8a-github.apk\n${'1' * 64}  other.apk\n', 200)
          : http.Response(jsonEncode(release(digest: false)), 200),
    );
    final u = await provider(c, FakeInstaller(), Directory.systemTemp).checkForUpdate(currentVersion: '0.2.0');
    expect(u!.sha256, apkHash);
  });

  test('download with correct sum is installed, tampered file discarded', () async {
    final dir = await Directory.systemTemp.createTemp('pounce-update');
    addTearDown(() => dir.delete(recursive: true));
    var tampered = false;
    final c = MockClient((r) async {
      if (r.url.host == 'dl') return http.Response.bytes(tampered ? utf8.encode('manipuliert') : apkBytes, 200);
      return http.Response(jsonEncode(release()), 200);
    });
    final inst = FakeInstaller();
    final p = provider(c, inst, dir);
    final u = (await p.checkForUpdate(currentVersion: '0.2.0'))!;

    final progress = <double>[];
    expect(await p.install(u, onProgress: progress.add), InstallResult.started);
    expect(File(inst.installed!).readAsBytesSync(), apkBytes);
    expect(progress.last, 1.0);

    tampered = true;
    inst.installed = null;
    expect(await p.install(u), InstallResult.checksumMismatch);
    expect(inst.installed, isNull);
    expect(
      dir.listSync().where((f) => f.path.endsWith('.apk') && File(f.path).readAsStringSync() == 'manipuliert'),
      isEmpty,
    );
  });

  test('without install permission: open the setting instead of downloading', () async {
    var downloads = 0;
    final c = MockClient((r) async {
      if (r.url.host == 'dl') downloads++;
      return http.Response(jsonEncode(release()), 200);
    });
    final inst = FakeInstaller()..allowed = false;
    final p = provider(c, inst, Directory.systemTemp);
    final u = (await p.checkForUpdate(currentVersion: '0.2.0'))!;
    expect(await p.install(u), InstallResult.needsPermission);
    expect(inst.asked, isTrue);
    expect(downloads, 0);
  });
}

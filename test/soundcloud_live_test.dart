@Tags(['live'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/lyrics/lyrics_service.dart';
import 'package:pounce/sc/models.dart';
import 'package:pounce/sc/soundcloud.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _TmpPaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationSupportPath() async => (await Directory.systemTemp.createTemp('kf')).path;
}

/// Real network tests: flutter test --run-skipped --tags live
void main() {
  late SoundCloud sc;

  setUpAll(() async {
    // Otherwise flutter_test blocks real HTTP requests.
    HttpOverrides.global = null;
    PathProviderPlatform.instance = _TmpPaths();
    final store = Store.memory();
    sc = SoundCloud(store, Settings(store));
  });

  test('client_id, search, stream', () async {
    final id = await sc.clientId();
    expect(id.length, 32);
    final res = await sc.searchTracks('lofi beats');
    expect(res.items, isNotEmpty);
    final track = res.items.firstWhere((t) => t.transcodings.any((x) => !x.snipped));
    final s = await sc.stream(track);
    expect(s.url, startsWith('https://'));
    // ignore: avoid_print
    print('stream: ${s.hls ? 'HLS' : 'MP3'} ${s.url.substring(0, 60)}…');
  });

  test('home, playlist, artist, related, waveform, suggestions', () async {
    final sel = await sc.selections();
    expect(sel, isNotEmpty);
    final p = await sc.playlist(sel.first.playlists.first.id);
    expect(p.tracks, isNotEmpty);
    expect(p.tracks.every((t) => !t.isStub), isTrue);
    final t = p.tracks.first;
    expect(await sc.related(t.id), isNotEmpty);
    expect((await sc.userTracks(t.user.id)).items, isNotEmpty);
    expect(await sc.waveform(t), isNotEmpty);
    expect(await sc.suggestions('daft'), isNotEmpty);
    final next = (await sc.searchTracks('house')).next;
    expect(next, isNotNull);
    expect((await sc.next(next!, (j) => j)).items, isNotEmpty);
  });

  test('resolve link + lyrics', () async {
    final res = await sc.searchTracks('Rick Astley Never Gonna Give You Up');
    final r = await sc.resolve(res.items.first.permalinkUrl!);
    expect(r, isA<ResolvedTrack>());
    final lyrics = await LyricsService(http.Client()).forTrack(res.items.first);
    // ignore: avoid_print
    print('lyrics: ${lyrics?.source} synced=${lyrics?.synced} lines=${lyrics?.lines.length}');
    expect(lyrics, isNotNull);
  });
}

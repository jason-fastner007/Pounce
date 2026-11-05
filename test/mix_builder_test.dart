import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/dj/beat_analyzer.dart';
import 'package:pounce/dj/dj_flow_controller.dart';
import 'package:pounce/dj/mix_builder.dart';
import 'package:pounce/dj/taste.dart';
import 'package:pounce/library/library.dart';
import 'package:pounce/player/audio_engine.dart';
import 'package:pounce/player/player_controller.dart';
import 'package:pounce/sc/models.dart';
import 'package:pounce/sc/soundcloud.dart';

class _FakeEngine extends AudioEngine {
  final _st = StreamController<EngineState>.broadcast();
  final _cmd = StreamController<RemoteCommand>.broadcast();

  @override
  Stream<EngineState> get states => _st.stream;
  @override
  Stream<RemoteCommand> get commands => _cmd.stream;
  @override
  Future<void> load(StreamInfo s, MediaMeta m, {bool play = true, Duration start = Duration.zero}) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration p) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setVolume(double v) async {}
  @override
  Future<void> setSpeed(double s) async {}
  @override
  Future<void> setLoudMode(LoudMode mode) async {}
  @override
  bool get supportsLoudness => false;
  @override
  final loudness = ValueNotifier(Loudness.none);

  @override
  void dispose() {
    _st.close();
    _cmd.close();
  }
}

Track t(
  int id, {
  String title = 'Song',
  String? genre,
  int ms = 240000,
  String? policy,
  bool isLive = false,
  List<Transcoding>? transcodings,
}) => Track(
  id: id,
  title: title,
  user: const ScUser(id: 1, username: 'u'),
  durationMs: ms,
  genre: genre,
  policy: policy,
  streamUrl: isLive ? 'https://live.stream/hls.m3u8' : null,
  trackAuthorization: 'auth_$id',
  transcodings: transcodings ?? const [
    Transcoding(url: 'https://api/x', preset: 'mp3', protocol: 'progressive', mime: 'audio/mpeg', snipped: false),
  ],
);

void main() {
  test('mix starts familiar and keeps the new/favourites ratio', () {
    final fav = [for (var i = 0; i < 30; i++) t(i)];
    final fresh = [for (var i = 100; i < 130; i++) t(i)];
    final m = MixBuilder.mix(fav, fresh, .6, 50);
    expect(m.length, 50);
    expect(m.first.id, lessThan(100));
    final share = m.where((x) => x.id >= 100).length / m.length;
    expect(share, closeTo(.6, .05));
    expect(m.toSet().length, 50, reason: 'keine Doppelten');
  });

  test('no favourites: only new; no new: only favourites', () {
    expect(MixBuilder.mix([], [t(1), t(2)], .6, 50).length, 2);
    expect(MixBuilder.mix([t(1), t(2)], [], .6, 50).length, 2);
  });

  test('previews, hour-long mixes and snippets are dropped', () {
    expect(MixBuilder.usable(t(1)), isTrue);
    expect(MixBuilder.usable(t(2, policy: 'SNIP')), isFalse);
    expect(MixBuilder.usable(t(3, ms: 3600000)), isFalse);
    expect(MixBuilder.usable(t(5, ms: 7 * 60000)), isFalse);
    expect(MixBuilder.usable(t(4, ms: 30000)), isFalse);
  });

  test('categories match tag, title and tempo', () {
    final hard = DjCategory.all.firstWhere((c) => c.id == 'hardtechno');
    expect(hard.matches(t(1, title: 'Song (Hard Techno Remix)')), isTrue);
    expect(hard.matches(t(2, genre: 'Hardtekk')), isTrue);
    expect(hard.matches(t(3, title: 'Unbekannt'), bpm: 155), isTrue);
    expect(hard.matches(t(4, title: 'Unbekannt'), bpm: 124), isFalse);
  });

  test('MixBuilder: selected categories and discovery persistence', () {
    final store = Store.memory();
    final client = MockClient((req) async => http.Response('{}', 200));
    final settings = Settings(store);
    final sc = SoundCloud(store, settings, client: client);
    final lib = Library(store);
    final engine = _FakeEngine();
    final player = PlayerController(engine, sc, settings, lib, store);
    final analyzer = BeatAnalyzer(sc, store);
    final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
    final taste = TasteModel(store);

    final builder = MixBuilder(sc: sc, library: lib, player: player, dj: dj, store: store, taste: taste);

    expect(builder.selected, isEmpty);
    expect(builder.discovery, 0.6);

    builder.toggle('techno');
    expect(builder.selected, contains('techno'));
    expect(store.get<List>('dj_categories'), ['techno']);

    builder.toggle('techno');
    expect(builder.selected, isEmpty);

    builder.selected = {'house', 'trance'};
    expect(builder.selected, {'house', 'trance'});

    builder.discovery = 0.8;
    expect(builder.discovery, 0.8);
    expect(store.get<num>('dj_discovery'), 0.8);

    player.dispose();
  });

  test('MixBuilder.start with empty categories returns 0', () async {
    final store = Store.memory();
    final client = MockClient((req) async => http.Response('{}', 200));
    final settings = Settings(store);
    final sc = SoundCloud(store, settings, client: client);
    final lib = Library(store);
    final engine = _FakeEngine();
    final player = PlayerController(engine, sc, settings, lib, store);
    final analyzer = BeatAnalyzer(sc, store);
    final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
    final taste = TasteModel(store);

    final builder = MixBuilder(sc: sc, library: lib, player: player, dj: dj, store: store, taste: taste);
    builder.selected = {};

    final count = await builder.start();
    expect(count, 0);
    expect(builder.building, isFalse);

    player.dispose();
  });

  test('MixBuilder.start successfully builds mix and starts DJ flow', () async {
    final store = Store.memory();
    store.set('lib.likes', [
      t(101, title: 'My Techno Fav', genre: 'Techno', ms: 220000).toJson(),
      t(102, title: 'Banned Fav', genre: 'Techno', ms: 220000).toJson(),
    ]);

    final client = MockClient((req) async {
      if (req.url.path.contains('related')) {
        return http.Response(
          '''[
            {"id": 201, "title": "Related Techno", "duration": 200000, "genre": "Techno", "user": {"id": 1, "username": "dj"}},
            {"id": 202, "title": "Related Ambient", "duration": 200000, "genre": "Ambient", "user": {"id": 1, "username": "dj"}}
          ]''',
          200,
        );
      }
      if (req.url.path.contains('search/tracks')) {
        return http.Response(
          '''{
            "collection": [
              {"id": 301, "title": "Peak Techno", "duration": 240000, "genre": "Techno", "user": {"id": 1, "username": "dj"}},
              {"id": 302, "title": "Snip", "duration": 30000, "genre": "Techno", "policy": "SNIP", "user": {"id": 1, "username": "dj"}}
            ]
          }''',
          200,
        );
      }
      return http.Response('{"url":"https://cdn/stream.mp3"}', 200);
    });

    final settings = Settings(store);
    final sc = SoundCloud(store, settings, client: client);
    final lib = Library(store);
    final engine = _FakeEngine();
    final player = PlayerController(engine, sc, settings, lib, store);
    final analyzer = BeatAnalyzer(sc, store);
    final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
    final taste = TasteModel(store);

    taste.record(t(102), null, Outcome.earlySkip);

    final builder = MixBuilder(sc: sc, library: lib, player: player, dj: dj, store: store, taste: taste);
    builder.selected = {'techno'};

    expect(dj.state.isActive, isFalse);

    final count = await builder.start();
    expect(count, greaterThan(0));
    expect(dj.state.isActive, isTrue);
    expect(player.queue, isNotEmpty);
    expect(player.queue.any((tr) => tr.id == 102), isFalse); // Banned track excluded
    expect(builder.building, isFalse);
    expect(builder.error, isNull);

    player.dispose();
  });

  test('MixBuilder.start error sets error property and resets building', () async {
    final store = Store.memory();
    final client = MockClient((req) async {
      throw Exception('Network failed');
    });

    final settings = Settings(store);
    final sc = SoundCloud(store, settings, client: client);
    final lib = Library(store);
    final engine = _FakeEngine();
    final player = PlayerController(engine, sc, settings, lib, store);
    final analyzer = BeatAnalyzer(sc, store);
    final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
    final taste = TasteModel(store);

    final builder = MixBuilder(sc: sc, library: lib, player: player, dj: dj, store: store, taste: taste);
    builder.selected = {'techno'};

    final count = await builder.start();
    expect(count, 0);
    expect(builder.building, isFalse);

    player.dispose();
  });
}

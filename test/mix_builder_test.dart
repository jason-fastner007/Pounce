import 'dart:async';
import 'dart:convert';

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
  final loaded = <String>[];
  final _st = StreamController<EngineState>.broadcast();
  final _cmd = StreamController<RemoteCommand>.broadcast();

  @override
  Stream<EngineState> get states => _st.stream;
  @override
  Stream<RemoteCommand> get commands => _cmd.stream;

  @override
  Future<void> load(StreamInfo s, MediaMeta m, {bool play = true, Duration start = Duration.zero}) async {
    loaded.add(m.id);
  }

  @override
  Future<void> prebuffer(StreamInfo s, MediaMeta m, {Duration start = Duration.zero, bool autoAdvance = false}) async {}

  @override
  Future<void> crossfade(
    StreamInfo s,
    MediaMeta m, {
    Duration start = Duration.zero,
    Duration duration = const Duration(milliseconds: 3000),
    double tempoRatio = 1,
  }) async {}

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
  final ValueListenable<Loudness> loudness = ValueNotifier(Loudness.none);
  @override
  SpectrumSource? get spectrum => null;
  @override
  void dispose() {
    _st.close();
    _cmd.close();
  }
}

Track t(int id, {String title = 'Song', String? genre, int ms = 240000, String? policy}) => Track(
  id: id,
  title: title,
  user: const ScUser(id: 1, username: 'u'),
  durationMs: ms,
  genre: genre,
  policy: policy,
  transcodings: const [
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

  group('MixBuilder state and workflow tests', () {
    late Store store;
    late Settings settings;
    late Library library;
    late PlayerController player;
    late DjFlowController dj;
    late TasteModel taste;

    setUp(() {
      store = Store.memory();
      settings = Settings(store);
      library = Library(store);
      taste = TasteModel(store);
    });

    test('selected categories and discovery settings getter/setter and toggle', () {
      final mockClient = MockClient((_) async => http.Response('{"url":"https://cdn/x.mp3"}', 200));
      final sc = SoundCloud(store, settings, client: mockClient);
      player = PlayerController(_FakeEngine(), sc, settings, library, store);
      final analyzer = BeatAnalyzer(sc, store);
      dj = DjFlowController(player: player, analyzer: analyzer, store: store);

      final builder = MixBuilder(
        sc: sc,
        library: library,
        player: player,
        dj: dj,
        store: store,
        taste: taste,
      );

      expect(builder.selected, isEmpty);
      expect(builder.discovery, 0.6);

      builder.discovery = 0.8;
      expect(builder.discovery, 0.8);
      expect(store.get<num>('dj_discovery'), 0.8);

      builder.toggle('techno');
      expect(builder.selected, {'techno'});
      expect(store.get<List>('dj_categories'), ['techno']);

      builder.toggle('house');
      expect(builder.selected, {'techno', 'house'});

      builder.toggle('techno');
      expect(builder.selected, {'house'});

      builder.selected = {'trance', 'dnb'};
      expect(builder.selected, {'trance', 'dnb'});
      expect(store.get<List>('dj_categories'), containsAll(['trance', 'dnb']));
    });

    test('start returns 0 when no category selected or already building', () async {
      final mockClient = MockClient((_) async => http.Response('{"url":"https://cdn/x.mp3"}', 200));
      final sc = SoundCloud(store, settings, client: mockClient);
      player = PlayerController(_FakeEngine(), sc, settings, library, store);
      final analyzer = BeatAnalyzer(sc, store);
      dj = DjFlowController(player: player, analyzer: analyzer, store: store);

      final builder = MixBuilder(
        sc: sc,
        library: library,
        player: player,
        dj: dj,
        store: store,
        taste: taste,
      );

      final count = await builder.start();
      expect(count, 0);
      expect(builder.building, isFalse);
    });

    test('start builds mix from likes and search, enables dj flow and starts player', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final favoriteTrack = t(10, title: 'Techno Fav', genre: 'techno');
      library.toggleLike(favoriteTrack);

      final mockClient = MockClient((request) async {
        final path = request.url.path;
        if (path == '/tracks/10/related') {
          return http.Response(
            jsonEncode({
              'collection': [
                t(20, title: 'Related Techno', genre: 'techno').toJson(),
              ]
            }),
            200,
          );
        } else if (path == '/search/tracks') {
          return http.Response(
            jsonEncode({
              'collection': [
                t(30, title: 'Searched Techno', genre: 'techno').toJson(),
              ]
            }),
            200,
          );
        } else if (path == '/transcodings/prog' || path.startsWith('/stream')) {
          return http.Response(jsonEncode({'url': 'https://cdn/audio.mp3'}), 200);
        }
        return http.Response('{"url":"https://cdn/default.mp3"}', 200);
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      player = PlayerController(_FakeEngine(), sc, settings, library, store);
      final analyzer = BeatAnalyzer(sc, store);
      dj = DjFlowController(player: player, analyzer: analyzer, store: store);

      final builder = MixBuilder(
        sc: sc,
        library: library,
        player: player,
        dj: dj,
        store: store,
        taste: taste,
      );

      builder.selected = {'techno'};
      expect(dj.state.isActive, isFalse);

      final count = await builder.start();
      expect(count, greaterThan(0));
      expect(dj.state.isActive, isTrue);
      expect(player.queue, isNotEmpty);
      expect(builder.error, isNull);
    });

    test('build excludes recently played history tracks and banned tracks', () async {
      store.set('sc.cid', 'testcid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);

      final recentFav = t(1, title: 'Recent Fav Techno', genre: 'techno');
      final bannedFav = t(2, title: 'Banned Fav Techno', genre: 'techno');
      final goodFav = t(3, title: 'Good Fav Techno', genre: 'techno');

      library.toggleLike(recentFav);
      library.toggleLike(bannedFav);
      library.toggleLike(goodFav);

      library.addHistory(recentFav); // in recent history
      taste.record(bannedFav, null, Outcome.earlySkip); // banned by taste

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'collection': [
              t(4, title: 'New Techno', genre: 'techno').toJson(),
              t(1, title: 'Recent Fav Techno', genre: 'techno').toJson(), // should be dropped as recent
            ]
          }),
          200,
        );
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      player = PlayerController(_FakeEngine(), sc, settings, library, store);
      final analyzer = BeatAnalyzer(sc, store);
      dj = DjFlowController(player: player, analyzer: analyzer, store: store);

      final builder = MixBuilder(
        sc: sc,
        library: library,
        player: player,
        dj: dj,
        store: store,
        taste: taste,
      );

      final cats = [DjCategory.all.firstWhere((c) => c.id == 'techno')];
      final tracks = await builder.build(cats);

      final trackIds = tracks.map((x) => x.id).toList();
      expect(trackIds, contains(goodFav.id));
      expect(trackIds, isNot(contains(recentFav.id)));
      expect(trackIds, isNot(contains(bannedFav.id)));
    });

    test('start handles building failure gracefully', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network error');
      });

      final sc = SoundCloud(store, settings, client: mockClient);
      player = PlayerController(_FakeEngine(), sc, settings, library, store);
      final analyzer = BeatAnalyzer(sc, store);
      dj = DjFlowController(player: player, analyzer: analyzer, store: store);

      final builder = MixBuilder(
        sc: sc,
        library: library,
        player: player,
        dj: dj,
        store: store,
        taste: taste,
      );

      builder.selected = {'techno'};
      final count = await builder.start();
      expect(count, 0);
      expect(builder.building, isFalse);
    });
  });
}

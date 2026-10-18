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
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setLoudMode(LoudMode mode) async {}
  @override
  ValueListenable<Loudness> get loudness => ValueNotifier(const Loudness());
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

  group('MixBuilder state and category management', () {
    late Store store;
    late Settings settings;
    late SoundCloud sc;
    late Library library;
    late PlayerController player;
    late DjFlowController dj;
    late TasteModel taste;
    late MixBuilder builder;

    setUp(() {
      store = Store.memory();
      settings = Settings(store);
      final client = MockClient((_) async => http.Response('{"url":"https://cdn/stream.mp3"}', 200));
      sc = SoundCloud(store, settings, client: client);
      library = Library(store);
      final analyzer = BeatAnalyzer(sc, store);
      player = PlayerController(_FakeEngine(), sc, settings, library, store);
      dj = DjFlowController(player: player, analyzer: analyzer, store: store);
      taste = TasteModel(store);
      builder = MixBuilder(
        sc: sc,
        library: library,
        player: player,
        dj: dj,
        store: store,
        taste: taste,
      );
    });

    test('selected categories toggle and persist in store', () {
      expect(builder.selected, isEmpty);

      builder.toggle('techno');
      expect(builder.selected, contains('techno'));
      expect(store.get<List>('dj_categories'), ['techno']);

      builder.toggle('techno');
      expect(builder.selected, isNot(contains('techno')));
      expect(store.get<List>('dj_categories'), isEmpty);

      builder.selected = {'house', 'trance'};
      expect(builder.selected, equals({'house', 'trance'}));
      expect(store.get<List>('dj_categories'), containsAll(['house', 'trance']));
    });

    test('discovery getter and setter persist values correctly', () {
      expect(builder.discovery, equals(0.6));

      builder.discovery = 0.8;
      expect(builder.discovery, equals(0.8));
      expect(store.get<num>('dj_discovery'), equals(0.8));
    });

    test('start returns 0 when no categories selected', () async {
      builder.selected = {};
      final count = await builder.start();
      expect(count, equals(0));
    });

    test('start builds mix, toggles dj flow if inactive, and plays queue', () async {
      builder.selected = {'techno'};
      final track1 = t(1, title: 'Techno Banger 1');
      final track2 = t(2, title: 'Techno Banger 2');
      library.likes.addAll([track1, track2]);

      expect(dj.state.isActive, isFalse);
      final count = await builder.start();

      expect(count, greaterThan(0));
      expect(dj.state.isActive, isTrue);
      expect(player.queue.isNotEmpty, isTrue);
    });

    test('build filters banned tracks and excludes recently played history', () async {
      builder.selected = {'techno'};
      final likedTrack = t(1, title: 'Techno Track 1');
      final recentTrack = t(2, title: 'Techno Track 2');
      final bannedTrack = t(3, title: 'Techno Track 3');

      library.likes.addAll([likedTrack, recentTrack, bannedTrack]);
      library.history.add(recentTrack);
      taste.record(bannedTrack, null, Outcome.earlySkip);

      final cats = [DjCategory.all.firstWhere((c) => c.id == 'techno')];
      final tracks = await builder.build(cats);

      expect(tracks.map((x) => x.id), contains(1));
      expect(tracks.map((x) => x.id), isNot(contains(2)));
      expect(tracks.map((x) => x.id), isNot(contains(3)));
    });
  });
}

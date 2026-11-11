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
  trackAuthorization: 'auth_$id',
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

  group('MixBuilder state, selection, and build flow', () {
    late Store store;
    late Settings settings;
    late SoundCloud sc;
    late Library library;
    late PlayerController player;
    late BeatAnalyzer analyzer;
    late DjFlowController dj;
    late TasteModel taste;
    late MixBuilder builder;

    setUp(() {
      store = Store.memory();
      settings = Settings(store);
      final client = MockClient((req) async {
        if (req.url.path.contains('/related')) {
          return http.Response(
            '[{"id":501,"title":"Related 1","duration":200000,"user":{"id":1,"username":"u"}}]',
            200,
          );
        }
        if (req.url.path.contains('/search')) {
          return http.Response(
            '{"collection":[{"id":601,"title":"Searched Techno","duration":210000,"genre":"Techno","user":{"id":1,"username":"u"}}]}',
            200,
          );
        }
        return http.Response('{"url":"https://cdn/x.mp3"}', 200);
      });
      sc = SoundCloud(store, settings, client: client);
      library = Library(store);
      player = PlayerController(_FakeEngine(), sc, settings, library, store);
      analyzer = BeatAnalyzer(sc, store);
      dj = DjFlowController(player: player, analyzer: analyzer, store: store);
      taste = TasteModel(store);
      builder = MixBuilder(sc: sc, library: library, player: player, dj: dj, store: store, taste: taste);
    });

    tearDown(() {
      builder.dispose();
      dj.dispose();
      player.dispose();
    });

    test('selected categories and toggle logic', () {
      expect(builder.selected, isEmpty);

      builder.toggle('techno');
      expect(builder.selected, contains('techno'));
      expect(store.get<List>('dj_categories'), ['techno']);

      builder.toggle('techno');
      expect(builder.selected, isEmpty);
      expect(store.get<List>('dj_categories'), isEmpty);

      builder.selected = {'house', 'trance'};
      expect(builder.selected, {'house', 'trance'});
    });

    test('discovery getter and setter persist to store', () {
      expect(builder.discovery, 0.6);

      builder.discovery = 0.8;
      expect(builder.discovery, 0.8);
      expect(store.get<num>('dj_discovery'), 0.8);
    });

    test('start returns 0 if no categories selected or already building', () async {
      expect(await builder.start(), 0);
      expect(builder.building, isFalse);
    });

    test('start builds mix, toggles dj flow and starts player queue', () async {
      final likedTrack = t(10, title: 'Fav Techno Track', genre: 'techno');
      library.toggleLike(likedTrack);

      builder.toggle('techno');
      expect(builder.selected, contains('techno'));

      final count = await builder.start();
      expect(count, greaterThan(0));
      expect(dj.state.isActive, isTrue);
      expect(player.queue, isNotEmpty);
      expect(player.current, isNotNull);
    });
  });
}

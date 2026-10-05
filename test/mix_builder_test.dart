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

  test('guest whose recent history covers every search result still gets a mix', () async {
    final store = Store.memory()
      ..set('sc.cid', 'testcid123456789012345678901234')
      ..set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);
    final settings = Settings(store);
    final songs = [for (var i = 1; i <= 5; i++) _json(i)];
    final client = MockClient((_) async => http.Response(jsonEncode({'collection': songs}), 200));
    final sc = SoundCloud(store, settings, client: client);
    final library = Library(store);
    for (final s in songs) {
      library.addHistory(Track.fromJson(s));
    }
    final player = PlayerController(_SilentEngine(), sc, settings, library, store);
    final dj = DjFlowController(player: player, analyzer: BeatAnalyzer(sc, store), store: store);
    final mix = MixBuilder(sc: sc, library: library, player: player, dj: dj, store: store, taste: TasteModel(store));
    addTearDown(() {
      dj.dispose();
      player.dispose();
    });

    final tracks = await mix.build([DjCategory.all.firstWhere((c) => c.id == 'techno')]);
    expect(tracks.map((t) => t.id), unorderedEquals([1, 2, 3, 4, 5]));
  });
}

Map<String, Object?> _json(int id) => {
  'id': id,
  'title': 'Techno $id',
  'genre': 'Techno',
  'duration': 240000,
  'user': {'id': 1, 'username': 'u'},
  'track_authorization': 'x',
  'media': {
    'transcodings': [
      {
        'url': 'https://api-v2.soundcloud.com/t/$id',
        'preset': 'mp3_128k',
        'snipped': false,
        'format': {'protocol': 'progressive', 'mime_type': 'audio/mpeg'},
      },
    ],
  },
};

class _SilentEngine extends AudioEngine {
  final _st = StreamController<EngineState>.broadcast();
  final _cmd = StreamController<RemoteCommand>.broadcast();
  @override
  Stream<EngineState> get states => _st.stream;
  @override
  Stream<RemoteCommand> get commands => _cmd.stream;
  @override
  Future<void> load(StreamInfo s, MediaMeta m, {bool play = true, Duration start = Duration.zero}) async {}
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

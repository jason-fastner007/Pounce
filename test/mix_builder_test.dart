import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
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
  @override
  Stream<EngineState> get states => const Stream.empty();
  @override
  Stream<RemoteCommand> get commands => const Stream.empty();
  @override
  Future<void> load(StreamInfo s, MediaMeta m, {bool play = true, Duration start = Duration.zero}) async {}
  @override
  Future<void> prebuffer(StreamInfo s, MediaMeta m, {Duration start = Duration.zero, bool autoAdvance = false}) async {}
  @override
  Future<void> crossfade(StreamInfo s, MediaMeta m, {Duration start = Duration.zero, Duration duration = const Duration(milliseconds: 3000), double tempoRatio = 1}) async {}
  @override
  Future<void> cancelPrebuffer() async {}
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
  void dispose() {}
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

  test('MixBuilder category selection and discovery preference persistence', () {
    final store = Store.memory();
    final settings = Settings(store);
    final sc = SoundCloud(store, settings);
    final lib = Library(store);
    final player = PlayerController(_FakeEngine(), sc, settings, lib, store);
    final analyzer = BeatAnalyzer(sc, store);
    final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
    final taste = TasteModel(store);

    final mb = MixBuilder(sc: sc, library: lib, player: player, dj: dj, store: store, taste: taste);

    expect(mb.selected, isEmpty);
    mb.toggle('techno');
    expect(mb.selected, contains('techno'));
    expect(store.get<List>('dj_categories'), ['techno']);

    mb.toggle('techno');
    expect(mb.selected, isEmpty);

    expect(mb.discovery, 0.6);
    mb.discovery = 0.8;
    expect(mb.discovery, 0.8);
    expect(store.get<num>('dj_discovery'), 0.8);

    mb.dispose();
    dj.dispose();
    player.dispose();
  });
}

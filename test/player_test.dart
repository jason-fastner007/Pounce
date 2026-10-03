import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
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
  Future<void> load(StreamInfo s, MediaMeta m, {bool play = true, Duration start = Duration.zero}) async =>
      loaded.add(m.id);
  @override
  Future<void> prebuffer(StreamInfo s, MediaMeta m, {Duration start = Duration.zero, bool autoAdvance = false}) async {}
  @override
  Future<void> crossfade(
    StreamInfo s,
    MediaMeta m, {
    Duration start = Duration.zero,
    Duration duration = const Duration(milliseconds: 3000),
    double tempoRatio = 1,
  }) async => loaded.add(m.id);
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

Track _t(int id) => Track(
  id: id,
  title: 't$id',
  user: const ScUser(id: 1, username: 'u'),
  durationMs: 1000,
  trackAuthorization: 'x',
  transcodings: const [
    Transcoding(url: 'https://api/x', preset: 'mp3', protocol: 'progressive', mime: 'audio/mpeg', snipped: false),
  ],
);

void main() {
  late PlayerController player;
  late _FakeEngine engine;

  setUp(() async {
    final store = Store.memory();
    store
      ..set('sc.cid', 'id')
      ..set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);
    final settings = Settings(store)..autoplay = false;
    // Every stream request returns a URL.
    final client = MockClient((_) async => http.Response('{"url":"https://cdn/a.mp3"}', 200));
    engine = _FakeEngine();
    player = PlayerController(engine, SoundCloud(store, settings, client: client), settings, Library(store), store);
  });

  test('Queue: next/previous/repeat', () async {
    await player.playQueue([_t(1), _t(2), _t(3)], 1);
    expect(player.current!.id, 2);
    await player.next();
    expect(player.current!.id, 3);
    await player.next(); // end without repeat/autoplay -> stays
    expect(player.current!.id, 3);
    player.cycleRepeat(); // all
    await player.next();
    expect(player.current!.id, 1);
    await player.previous();
    expect(player.current!.id, 1); // at the start: only rewind
    expect(engine.loaded, ['2', '3', '1']);
  });

  test('shuffle keeps the current track and restores the order', () async {
    final list = [for (var i = 0; i < 20; i++) _t(i)];
    await player.playQueue(list, 5);
    player.toggleShuffle();
    expect(player.current!.id, 5);
    expect(player.queue.take(6).map((e) => e.id), [0, 1, 2, 3, 4, 5]);
    player.toggleShuffle();
    expect(player.queue.map((e) => e.id), list.map((e) => e.id));
    expect(player.index, 5);
  });

  test('playNext and move', () async {
    await player.playQueue([_t(1), _t(2)]);
    player.playNext(_t(9));
    expect(player.queue.map((e) => e.id), [1, 9, 2]);
    player.move(2, 0);
    expect(player.queue.map((e) => e.id), [2, 1, 9]);
    expect(player.current!.id, 1);
  });
}

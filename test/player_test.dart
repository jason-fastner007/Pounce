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
  final prebuffered = <String>[];
  final crossfaded = <String>[];
  bool played = false;
  bool paused = false;
  Duration? seekedTo;
  double volume = 1.0;
  double speed = 1.0;

  final _st = StreamController<EngineState>.broadcast();
  final _cmd = StreamController<RemoteCommand>.broadcast();

  void emitState(EngineState state) => _st.add(state);
  void emitCommand(RemoteCommand command) => _cmd.add(command);

  @override
  Stream<EngineState> get states => _st.stream;
  @override
  Stream<RemoteCommand> get commands => _cmd.stream;
  @override
  Future<void> load(StreamInfo s, MediaMeta m, {bool play = true, Duration start = Duration.zero}) async {
    loaded.add(m.id);
  }

  @override
  Future<void> prebuffer(StreamInfo s, MediaMeta m, {Duration start = Duration.zero, bool autoAdvance = false}) async {
    prebuffered.add(m.id);
  }

  @override
  Future<void> crossfade(
    StreamInfo s,
    MediaMeta m, {
    Duration start = Duration.zero,
    Duration duration = const Duration(milliseconds: 3000),
    double tempoRatio = 1,
  }) async {
    crossfaded.add(m.id);
  }

  @override
  Future<void> cancelPrebuffer() async {}

  @override
  Future<void> play() async {
    played = true;
    paused = false;
  }

  @override
  Future<void> pause() async {
    paused = true;
    played = false;
  }

  @override
  Future<void> seek(Duration p) async {
    seekedTo = p;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double v) async {
    volume = v;
  }

  @override
  Future<void> setSpeed(double s) async {
    speed = s;
  }

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

Track _t(
  int id, {
  bool isPreview = false,
  int durationMs = 1000,
  bool isLive = false,
  List<Transcoding>? transcodings,
}) => Track(
  id: id,
  title: 't$id',
  user: const ScUser(id: 1, username: 'u'),
  durationMs: durationMs,
  policy: isPreview ? 'SNIP' : null,
  streamUrl: isLive ? 'https://live.stream/hls.m3u8' : null,
  trackAuthorization: 'x',
  transcodings: transcodings ?? const [
    Transcoding(url: 'https://api/x', preset: 'mp3', protocol: 'progressive', mime: 'audio/mpeg', snipped: false),
  ],
);

void main() {
  late Store store;
  late Settings settings;
  late PlayerController player;
  late _FakeEngine engine;

  setUp(() async {
    store = Store.memory();
    store
      ..set('sc.cid', 'id')
      ..set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);
    settings = Settings(store)..autoplay = false;
    final client = MockClient((req) async {
      if (req.url.path.contains('error')) {
        return http.Response('{"error":"not_found"}', 404);
      }
      return http.Response('{"url":"https://cdn/a.mp3"}', 200);
    });
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

  test('addToQueue, removeAt, jumpTo and reorderUpcoming', () async {
    await player.playQueue([_t(1), _t(2), _t(3)]);
    player.addToQueue(_t(4));
    expect(player.queue.map((e) => e.id), [1, 2, 3, 4]);

    player.removeAt(1); // removes track 2
    expect(player.queue.map((e) => e.id), [1, 3, 4]);

    await player.jumpTo(2); // jump to track 4
    expect(player.current!.id, 4);

    player.reorderUpcoming([_t(3)]);
    expect(player.queue.map((e) => e.id), [1, 3, 4]);
  });

  test('Playback transport and speed/volume controls', () async {
    await player.playQueue([_t(1)]);

    await player.play();
    expect(engine.played, true);

    await player.pause();
    expect(engine.paused, true);

    await player.seek(const Duration(seconds: 5));
    expect(engine.seekedTo, const Duration(seconds: 5));

    await player.setSpeed(1.25);
    expect(player.speed, 1.25);
    expect(engine.speed, 1.25);

    await player.setVolume(0.8);
    expect(player.volume.value, 0.8);
    expect(engine.volume, 0.8);
  });

  test('Track filtering with allow predicate and skipPreviews setting', () async {
    settings.skipPreviews = true;
    player.allow = (t) => t.id != 2; // block track 2

    final previewTrack = _t(3, isPreview: true);
    await player.playQueue([_t(1), _t(2), previewTrack, _t(4)]);

    expect(player.current!.id, 1);
    await player.next();
    // Tracks 2 (blocked by allow) and 3 (preview) are skipped -> lands on track 4
    expect(player.current!.id, 4);
  });

  test('warm and cool prebuffering logic', () async {
    final t1 = _t(1);
    final t2 = _t(2);
    await player.playQueue([t1, t2]);

    await player.warm(t2);
    expect(engine.prebuffered, contains('2'));

    player.cool(t2);
  });

  test('crossfadeTo switches current track seamlessly', () async {
    final t1 = _t(1);
    final t2 = _t(2);
    await player.playQueue([t1]);

    await player.crossfadeTo(t2, crossfadeDuration: const Duration(seconds: 2));
    expect(player.current!.id, 2);
    expect(engine.crossfaded, contains('2'));
  });

  test('onLeave callback triggers on track transition', () async {
    Track? leftTrack;
    bool? leftSkipped;

    player.onLeave = (track, played, duration, skipped) {
      leftTrack = track;
      leftSkipped = skipped;
    };

    await player.playQueue([_t(1), _t(2)]);
    await player.next(auto: false); // user skipped

    expect(leftTrack?.id, 1);
    expect(leftSkipped, true);
  });

  test('Remote commands trigger player actions', () async {
    await player.playQueue([_t(1), _t(2)]);

    engine.emitCommand(RemoteCommand.next);
    await Future<void>.delayed(Duration.zero);
    expect(player.current!.id, 2);

    engine.emitCommand(RemoteCommand.pause);
    await Future<void>.delayed(Duration.zero);
    expect(engine.paused, true);
  });

  test('Error handling in stream loading auto-advances to next track', () async {
    final brokenTrack = Track(
      id: 99,
      title: 'broken',
      user: const ScUser(id: 1, username: 'u'),
      durationMs: 1000,
      trackAuthorization: 'x',
      transcodings: const [
        Transcoding(
          url: 'https://api/error',
          preset: 'mp3',
          protocol: 'progressive',
          mime: 'audio/mpeg',
          snipped: false,
        ),
      ],
    );

    await player.playQueue([brokenTrack, _t(1)]);
    // The broken track fails, sets error and auto advances to track 1
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(player.current!.id, 1);
  });

  test('Sleep timer pauses playback when timer fires', () async {
    await player.playQueue([_t(1)]);
    await player.play();

    player.setSleepTimer(const Duration(milliseconds: 50));
    expect(player.sleepAt, isNotNull);

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(engine.paused, true);
    expect(player.sleepAt, isNull);

    // setSleepTimer(null) cancels sleep timer
    player.setSleepTimer(const Duration(hours: 1));
    expect(player.sleepAt, isNotNull);
    player.setSleepTimer(null);
    expect(player.sleepAt, isNull);
  });

  test('Live track properties, seek guard, and toggle play/pause', () async {
    final liveTrack = _t(100, isLive: true);
    await player.playQueue([liveTrack]);

    expect(player.isLive, isTrue);
    expect(player.duration, Duration.zero);

    // Seek on live stream does not invoke engine seek
    await player.seek(const Duration(seconds: 10));
    expect(engine.seekedTo, isNull);

    // Toggle play/pause
    await player.toggle();
    expect(engine.played, isTrue);
  });

  test('LoudMode enum lufs values', () {
    expect(LoudMode.off.lufs, isNull);
    expect(LoudMode.quiet.lufs, -19);
    expect(LoudMode.normal.lufs, -14);
    expect(LoudMode.loud.lufs, -11);
  });

  test('removeAt current index returns early without removing', () async {
    await player.playQueue([_t(1), _t(2), _t(3)], 1);
    expect(player.index, 1);

    player.removeAt(1); // removing current track index
    expect(player.queue.length, 3);
    expect(player.index, 1);
  });

  test('Player state persistence and restoration', () async {
    await player.playQueue([_t(10), _t(11)], 1);
    await player.seek(const Duration(milliseconds: 500));
    player.dispose(); // Persists queue, index, and pos

    // Create new player controller with same store to test restoration
    final newPlayer = PlayerController(
      _FakeEngine(),
      SoundCloud(store, settings),
      settings,
      Library(store),
      store,
    );

    expect(newPlayer.queue.map((e) => e.id), [10, 11]);
    expect(newPlayer.index, 1);
    expect(newPlayer.position.value, const Duration(milliseconds: 500));
    newPlayer.dispose();
  });
}

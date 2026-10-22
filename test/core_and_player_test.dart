import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pounce/core/app_info.dart';
import 'package:pounce/core/debug_export.dart';
import 'package:pounce/core/login_launcher.dart';
import 'package:pounce/core/platform.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/library/library.dart';
import 'package:pounce/player/audio_engine.dart';
import 'package:pounce/player/player_controller.dart';
import 'package:pounce/sc/models.dart';
import 'package:pounce/sc/soundcloud.dart';

class _MockEngine extends AudioEngine {
  final loaded = <String>[];
  final prebuffered = <String>[];
  bool played = false;
  bool paused = false;

  final _st = StreamController<EngineState>.broadcast();
  final _cmd = StreamController<RemoteCommand>.broadcast();

  void emitState(EngineState state) => _st.add(state);

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

Track _track(int id, {bool isLive = false, String? liveUrl}) => Track(
      id: id,
      title: 'Track $id',
      user: const ScUser(id: 1, username: 'Artist'),
      durationMs: isLive ? 0 : 200000,
      streamUrl: liveUrl,
      trackAuthorization: 'auth',
      transcodings: const [
        Transcoding(
          url: 'https://api/stream',
          preset: 'mp3',
          protocol: 'progressive',
          mime: 'audio/mpeg',
          snipped: false,
        ),
      ],
    );

void main() {
  group('Core Module Tests', () {
    test('Platform properties reflect runtime environment', () {
      expect(Platform.isWeb, kIsWeb);
      expect(Platform.isAndroid, isA<bool>());
      expect(Platform.isDesktop, isA<bool>());
      expect(Platform.isApple, isA<bool>());
    });

    test('AppInfo version metadata parsing', () {
      expect(appVersion, isA<String>());
      expect(isBeta, isA<bool>());
    });

    test('Debug export non-crashing execution', () {
      expect(() => debugExport({'key': 'value', 'number': 42}), returnsNormally);
    });

    test('LoginLauncher creation and factory', () {
      final launcher = LoginLauncher.create();
      expect(launcher, isA<LoginLauncher>());
      expect(launcher.callbacks, isA<Stream<String>>());
      expect(launcher.automatic, isA<bool>());
    });
  });

  group('PlayerController Extended Edge Cases', () {
    late Store store;
    late Settings settings;
    late _MockEngine engine;
    late PlayerController player;

    setUp(() {
      store = Store.memory();
      store.set('sc.cid', 'cid123456789012345678901234');
      store.set('sc.cidAt', DateTime.now().millisecondsSinceEpoch);
      settings = Settings(store);
      engine = _MockEngine();
      final client = MockClient((req) async {
        return http.Response('{"url":"https://cdn/audio.mp3"}', 200);
      });
      player = PlayerController(engine, SoundCloud(store, settings, client: client), settings, Library(store), store);
    });

    test('livePosition extrapolates position while playing and caps at track duration', () async {
      final t1 = _track(1);
      await player.playQueue([t1]);

      engine.emitState(EngineState(
        status: EngineStatus.ready,
        playing: true,
        position: const Duration(seconds: 10),
        duration: const Duration(seconds: 200),
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(player.livePosition, greaterThanOrEqualTo(const Duration(seconds: 10)));
      expect(player.livePosition, lessThanOrEqualTo(const Duration(seconds: 200)));
    });

    test('prebufferTrack skips live tracks or duplicate prebuffer requests', () async {
      final liveTrack = _track(99, isLive: true, liveUrl: 'https://radio.live/stream');
      final normalTrack = _track(100);

      await player.prebufferTrack(liveTrack);
      expect(engine.prebuffered, isEmpty);

      await player.prebufferTrack(normalTrack);
      expect(engine.prebuffered, contains('100'));

      // Duplicate prebuffer call should do nothing
      await player.prebufferTrack(normalTrack);
      expect(engine.prebuffered.length, 1);
    });

    test('startLatency calculates latency on first playing state', () async {
      final t1 = _track(1);
      await player.playQueue([t1]);

      expect(player.startLatency.value, isNull);

      engine.emitState(EngineState(
        status: EngineStatus.ready,
        playing: true,
        position: Duration.zero,
        duration: const Duration(seconds: 100),
      ));

      await Future<void>.delayed(Duration.zero);
      expect(player.startLatency.value, isNotNull);
    });

    test('djFits correctly identifies tracks fitting DJ transitions', () {
      final shortTrack = _track(1, isLive: false);
      final liveTrack = _track(2, isLive: true, liveUrl: 'https://radio/live');
      final previewTrack = Track(
        id: 3,
        title: 'Preview',
        user: const ScUser(id: 1, username: 'u'),
        durationMs: 30000,
        policy: 'SNIP',
      );
      final longMixTrack = Track(
        id: 4,
        title: 'Long 10 Min Mix',
        user: const ScUser(id: 1, username: 'u'),
        durationMs: 10 * 60 * 1000,
      );

      expect(PlayerController.djFits(shortTrack), isTrue);
      expect(PlayerController.djFits(liveTrack), isTrue);
      expect(PlayerController.djFits(previewTrack), isFalse);
      expect(PlayerController.djFits(longMixTrack), isFalse);
    });
  });
}

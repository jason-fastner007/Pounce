import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pounce/core/deps.dart';
import 'package:pounce/core/login_launcher.dart';
import 'package:pounce/core/platform.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/dj/beat_analyzer.dart';
import 'package:pounce/dj/dj_flow_controller.dart';
import 'package:pounce/dj/mix_builder.dart';
import 'package:pounce/dj/taste.dart';
import 'package:pounce/library/account.dart';
import 'package:pounce/library/library.dart';
import 'package:pounce/lyrics/lyrics_service.dart';
import 'package:pounce/player/audio_engine.dart';
import 'package:pounce/player/player_controller.dart';
import 'package:pounce/radio/radio_browser.dart';
import 'package:pounce/radio/radio_service.dart';
import 'package:pounce/sc/auth.dart';
import 'package:pounce/sc/soundcloud.dart';
import 'package:pounce/sync/sync_log.dart';
import 'package:pounce/sync/sync_service.dart';

class _FakeAudioEngine extends AudioEngine {
  @override
  Stream<EngineState> get states => const Stream.empty();
  @override
  Stream<RemoteCommand> get commands => const Stream.empty();
  @override
  Future<void> load(StreamInfo stream, MediaMeta meta, {bool play = true, Duration start = Duration.zero}) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setLoudMode(LoudMode mode) async {}
  @override
  ValueListenable<Loudness> get loudness => ValueNotifier(Loudness.none);
  @override
  void dispose() {}
}

void main() {
  group('Platform unit tests', () {
    test('Platform getters return boolean flags', () {
      expect(Platform.isWeb, isFalse); // Running in Flutter VM unit tests
      expect(Platform.isAndroid, isA<bool>());
      expect(Platform.isApple, isA<bool>());
      expect(Platform.isDesktop, isA<bool>());
    });
  });

  group('AudioEngine model unit tests', () {
    test('EngineState copyWith updates position', () {
      const state = EngineState(
        status: EngineStatus.ready,
        playing: true,
        position: Duration(seconds: 10),
        duration: Duration(seconds: 100),
        buffered: Duration(seconds: 50),
        error: null,
      );

      final updated = state.copyWith(position: const Duration(seconds: 20));
      expect(updated.position, const Duration(seconds: 20));
      expect(updated.playing, isTrue);
      expect(updated.status, EngineStatus.ready);
      expect(updated.duration, const Duration(seconds: 100));
    });

    test('LoudMode enum maps target LUFS values correctly', () {
      expect(LoudMode.off.lufs, isNull);
      expect(LoudMode.quiet.lufs, -19.0);
      expect(LoudMode.normal.lufs, -14.0);
      expect(LoudMode.loud.lufs, -11.0);
    });

    test('Loudness none defaults are zero / null', () {
      expect(Loudness.none.momentary, isNull);
      expect(Loudness.none.integrated, isNull);
      expect(Loudness.none.gainDb, isNull);
      expect(Loudness.none.limiterDb, 0.0);
      expect(Loudness.none.clipping, isFalse);
    });

    test('MediaMeta toMap serializes fields', () {
      const meta = MediaMeta(
        id: 'track123',
        title: 'Song Title',
        artist: 'Artist Name',
        artUrl: 'https://art.png',
        duration: Duration(seconds: 180),
      );

      final map = meta.toMap();
      expect(map['id'], 'track123');
      expect(map['title'], 'Song Title');
      expect(map['artist'], 'Artist Name');
      expect(map['artUrl'], 'https://art.png');
      expect(map['durationMs'], 180000);
    });

    test('PcmClip length calculation from sample rate and samples count', () {
      final samples = Float32List(44100); // 1 second mono audio at 44.1 kHz
      final clip = PcmClip(samples, 44100, Duration.zero);
      expect(clip.length.inMilliseconds, closeTo(1000, 5));
    });

    test('logBandEdges calculates correct FFT band boundaries', () {
      final edges = logBandEdges(44100, 2048);
      expect(edges.length, SpectrumSource.bands + 1);
      expect(edges.first, greaterThanOrEqualTo(1));
      expect(edges.last, lessThanOrEqualTo(1024));
    });
  });

  group('Deps widget injection tests', () {
    testWidgets('Deps inherited widget provides dependencies to context', (tester) async {
      final store = Store.memory();
      final settings = Settings(store);
      final httpClient = http.Client();
      final sc = SoundCloud(store, settings, client: httpClient);
      final lyrics = LyricsService(httpClient);
      final library = Library(store);
      final engine = _FakeAudioEngine();
      final player = PlayerController(engine, sc, settings, library, store);
      final scAuth = ScAuth(store, httpClient, (uri) => uri);
      final launcher = LoginLauncher.create();
      final account = Account(scAuth, sc, library, launcher);
      final analyzer = BeatAnalyzer(sc, store);
      final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
      final taste = TasteModel(store);
      final mix = MixBuilder(sc: sc, library: library, player: player, dj: dj, store: store, taste: taste);
      final radioBrowser = RadioBrowser(httpClient);
      final radio = RadioService(radioBrowser, store, settings, player);
      final syncLog = SyncLog(store, library);
      final sync = SyncService(store: store, log: syncLog);

      Deps? capturedDeps;

      await tester.pumpWidget(
        Deps(
          settings: settings,
          sc: sc,
          lyrics: lyrics,
          library: library,
          player: player,
          account: account,
          dj: dj,
          mix: mix,
          taste: taste,
          radio: radio,
          store: store,
          updates: Future.value(null),
          sync: sync,
          child: Builder(
            builder: (context) {
              capturedDeps = context.deps;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedDeps, isNotNull);
      expect(capturedDeps!.settings, settings);
      expect(capturedDeps!.sc, sc);
      expect(capturedDeps!.player, player);
      expect(capturedDeps!.store, store);

      // Clean up services and pending timers
      sync.dispose();
      dj.dispose();
      account.dispose();
      player.dispose();
      scAuth.dispose();

      await tester.pump(const Duration(seconds: 35));
    });
  });
}

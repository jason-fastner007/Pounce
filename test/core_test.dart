import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
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
  ValueNotifier<Loudness> get loudness => ValueNotifier(Loudness.none);
  @override
  void dispose() {}
}

class _FakeLoginLauncher extends LoginLauncher {
  @override
  Stream<String> get callbacks => const Stream.empty();
  @override
  bool get automatic => true;
  @override
  Future<void> open(Uri url) async {}
}

void main() {
  group('Platform helper tests', () {
    test('Platform properties evaluate without throwing', () {
      expect(Platform.isWeb, isA<bool>());
      expect(Platform.isDesktop, isA<bool>());
      expect(Platform.isAndroid, isA<bool>());
      expect(Platform.isApple, isA<bool>());

      // In pure VM test environment
      expect(Platform.isWeb, isFalse);
    });
  });

  group('Deps dependency injection tests', () {
    testWidgets('Deps inherited widget provides dependencies to descendant widgets', (tester) async {
      final client = MockClient((_) async => throw UnimplementedError());
      final store = Store.memory();
      final settings = Settings(store);
      final sc = SoundCloud(store, settings, client: client);
      final lyrics = LyricsService(client);
      final library = Library(store);
      final player = PlayerController(_FakeAudioEngine(), sc, settings, library, store);
      final auth = ScAuth(store, client, (uri) => uri);
      final launcher = _FakeLoginLauncher();
      final account = Account(auth, sc, library, launcher);
      final analyzer = BeatAnalyzer(sc, store);
      final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
      final taste = TasteModel(store);
      final mix = MixBuilder(sc: sc, library: library, player: player, dj: dj, store: store, taste: taste);
      final radioBrowser = RadioBrowser(client);
      final radio = RadioService(radioBrowser, store, settings, player);
      final syncLog = SyncLog(store, library);
      final sync = SyncService(store: store, log: syncLog);

      Deps? resolvedDeps;

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
              resolvedDeps = context.deps;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(resolvedDeps, isNotNull);
      expect(resolvedDeps!.settings, equals(settings));
      expect(resolvedDeps!.sc, equals(sc));
      expect(resolvedDeps!.player, equals(player));
      expect(resolvedDeps!.store, equals(store));
      expect(resolvedDeps!.updateShouldNotify(resolvedDeps!), isFalse);

      sync.dispose();
      dj.dispose();
      account.dispose();
      player.dispose();

      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}

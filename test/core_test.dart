import 'dart:async';
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
import 'package:pounce/modules/updater/release_provider.dart';
import 'package:pounce/player/audio_engine.dart';
import 'package:pounce/player/player_controller.dart';
import 'package:pounce/radio/radio_browser.dart';
import 'package:pounce/radio/radio_service.dart';
import 'package:pounce/sc/auth.dart';
import 'package:pounce/sc/soundcloud.dart';
import 'package:pounce/sync/sync_log.dart';
import 'package:pounce/sync/sync_service.dart';

class MockAudioEngine implements AudioEngine {
  final _stateController = StreamController<EngineState>.broadcast();
  final _commandController = StreamController<RemoteCommand>.broadcast();

  @override
  Stream<EngineState> get states => _stateController.stream;

  @override
  Stream<RemoteCommand> get commands => _commandController.stream;

  @override
  Future<void> load(StreamInfo stream, MediaMeta meta, {bool play = true, Duration start = Duration.zero}) async {}

  @override
  Future<void> prebuffer(StreamInfo stream, MediaMeta meta, {Duration start = Duration.zero, bool autoAdvance = false}) async {}

  @override
  Future<void> cancelPrebuffer() async {}

  @override
  Future<void> crossfade(StreamInfo stream, MediaMeta meta, {Duration start = Duration.zero, Duration duration = const Duration(milliseconds: 3000), double tempoRatio = 1}) async {}

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
  bool get supportsLoudness => false;

  @override
  ValueListenable<Loudness> get loudness => ValueNotifier(Loudness.none);

  @override
  SpectrumSource? get spectrum => null;

  @override
  ValueListenable<String?> get streamTitle => ValueNotifier<String?>(null);

  @override
  Future<PcmClip?> decodePcm(StreamInfo stream, {Duration from = Duration.zero, required Duration length}) async => null;

  @override
  void dispose() {
    _stateController.close();
    _commandController.close();
  }
}

class DummyLoginLauncher implements LoginLauncher {
  @override
  Stream<String> get callbacks => const Stream.empty();

  @override
  bool get automatic => false;

  @override
  Future<void> open(Uri url) async {}
}

void main() {
  group('Platform info tests', () {
    test('Platform getters correctly reflect current environment', () {
      expect(Platform.isWeb, equals(kIsWeb));

      if (!kIsWeb) {
        final expectedDesktop = const {
          TargetPlatform.linux,
          TargetPlatform.windows,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform);
        expect(Platform.isDesktop, equals(expectedDesktop));

        expect(Platform.isAndroid, equals(defaultTargetPlatform == TargetPlatform.android));

        final expectedApple = const {
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform);
        expect(Platform.isApple, equals(expectedApple));
      }
    });
  });

  group('Deps InheritedWidget tests', () {
    testWidgets('Deps provides dependencies via context.deps', (WidgetTester tester) async {
      final store = Store.memory();
      final client = http.Client();
      final settings = Settings(store);
      final sc = SoundCloud(store, settings, client: client);
      final library = Library(store);
      final auth = ScAuth(store, client, sc.wrap);
      final account = Account(auth, sc, library, DummyLoginLauncher());
      final player = PlayerController(MockAudioEngine(), sc, settings, library, store);
      final analyzer = BeatAnalyzer(sc, store);
      final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
      final taste = TasteModel(store);
      final mix = MixBuilder(sc: sc, library: library, player: player, dj: dj, store: store, taste: taste);
      final syncLog = SyncLog(store, library);
      final sync = SyncService(store: store, log: syncLog);
      final radio = RadioService(RadioBrowser(client), store, settings, player);
      final lyrics = LyricsService(client, wrap: sc.wrap);
      final updates = Future<ReleaseProvider?>.value(null);

      late Deps retrievedDeps;

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
          updates: updates,
          sync: sync,
          child: Builder(
            builder: (context) {
              retrievedDeps = context.deps;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(retrievedDeps, isNotNull);
      expect(retrievedDeps.settings, equals(settings));
      expect(retrievedDeps.sc, equals(sc));
      expect(retrievedDeps.lyrics, equals(lyrics));
      expect(retrievedDeps.library, equals(library));
      expect(retrievedDeps.player, equals(player));
      expect(retrievedDeps.account, equals(account));
      expect(retrievedDeps.dj, equals(dj));
      expect(retrievedDeps.mix, equals(mix));
      expect(retrievedDeps.taste, equals(taste));
      expect(retrievedDeps.radio, equals(radio));
      expect(retrievedDeps.store, equals(store));
      expect(retrievedDeps.updates, equals(updates));
      expect(retrievedDeps.sync, equals(sync));

      player.dispose();
      sync.dispose();
      client.close();
      await store.save();
      await tester.pumpAndSettle();
    });
  });
}

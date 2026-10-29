import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pounce/core/app_info.dart';
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

class _FakeEngine extends AudioEngine {
  @override
  Stream<EngineState> get states => const Stream.empty();
  @override
  Stream<RemoteCommand> get commands => const Stream.empty();
  @override
  Future<void> load(StreamInfo s, MediaMeta m, {bool play = true, Duration start = Duration.zero}) async {}
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
  ValueListenable<Loudness> get loudness => ValueNotifier(Loudness.none);
  @override
  void dispose() {}
}

void main() {
  group('Core Platform and AppInfo tests', () {
    test('Platform environment getters respond without errors', () {
      expect(Platform.isWeb, isA<bool>());
      expect(Platform.isDesktop, isA<bool>());
      expect(Platform.isAndroid, isA<bool>());
      expect(Platform.isApple, isA<bool>());
    });

    test('AppInfo version metadata behaves correctly', () {
      expect(appVersion, isNotEmpty);
      expect(isBeta, appVersion.contains('-'));
    });
  });

  group('Settings edge cases and fallback values', () {
    late Store store;
    late Settings settings;

    setUp(() {
      store = Store.memory();
      settings = Settings(store);
    });

    test('invalid enum strings in store fallback gracefully to default settings', () {
      store.set('accent', 'non_existent_accent');
      store.set('loud', 'invalid_loud_mode');
      store.set('beatLevel', 'broken_beat_level');

      expect(settings.accent, Accent.cyan);
      expect(settings.loudMode, LoudMode.normal);
      expect(settings.beatLevel, BeatLevel.light);
    });

    test('booleans and feature toggles persist correctly', () {
      settings.setupDone = true;
      expect(settings.setupDone, isTrue);
      expect(store.get<bool>('setupDone'), isTrue);

      settings.recognitionOptIn = true;
      expect(settings.recognitionOptIn, isTrue);
      expect(store.get<bool>('recognitionOptIn'), isTrue);

      settings.fastStart = false;
      expect(settings.fastStart, isFalse);
      expect(store.get<bool>('fastStart'), isFalse);

      settings.radioEnabled = false;
      expect(settings.radioEnabled, isFalse);
      expect(store.get<bool>('radioEnabled'), isFalse);

      settings.autoCheckUpdates = true;
      expect(settings.autoCheckUpdates, isTrue);
      expect(store.get<bool>('autoCheckUpdates'), isTrue);
    });
  });

  group('Deps InheritedWidget test', () {
    testWidgets('Deps.of and context.deps provide injected dependencies', (tester) async {
      final store = Store.memory();
      final settings = Settings(store);
      final httpClient = http.Client();
      final sc = SoundCloud(store, settings, client: httpClient);
      final auth = ScAuth(store, httpClient, sc.wrap);
      final lyrics = LyricsService(httpClient, wrap: sc.wrap);
      final library = Library(store);
      final engine = _FakeEngine();
      final player = PlayerController(engine, sc, settings, library, store);
      final launcher = LoginLauncher.create();
      final account = Account(auth, sc, library, launcher);
      final analyzer = BeatAnalyzer(sc, store);
      final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
      final taste = TasteModel(store);
      final mix = MixBuilder(sc: sc, library: library, player: player, dj: dj, store: store, taste: taste);
      final syncLog = SyncLog(store, library);
      final sync = SyncService(store: store, log: syncLog);
      final radioBrowser = RadioBrowser(httpClient);
      final radio = RadioService(radioBrowser, store, settings, player);

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
          updates: Future<ReleaseProvider?>.value(null),
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
      expect(resolvedDeps!.settings, settings);
      expect(resolvedDeps!.store, store);
      expect(resolvedDeps!.sc, sc);
      expect(resolvedDeps!.player, player);

      player.dispose();
      dj.dispose();
      account.dispose();
      sync.dispose();
      httpClient.close();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}

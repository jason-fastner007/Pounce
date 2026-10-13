import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:pounce/core/deps.dart';
import 'package:pounce/core/login_launcher.dart';
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

class DummyAudioEngine implements AudioEngine {
  final _stateController = StreamController<EngineState>.broadcast();
  final _cmdController = StreamController<RemoteCommand>.broadcast();

  @override
  Stream<EngineState> get states => _stateController.stream;

  @override
  Stream<RemoteCommand> get commands => _cmdController.stream;

  @override
  ValueListenable<Loudness> get loudness => ValueNotifier(const Loudness(integrated: -14));

  @override
  bool get supportsLoudness => false;

  @override
  SpectrumSource? get spectrum => null;

  @override
  ValueListenable<String?> get streamTitle => ValueNotifier(null);

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
  Future<void> prebuffer(
    StreamInfo stream,
    MediaMeta meta, {
    Duration start = Duration.zero,
    bool autoAdvance = false,
  }) async {}

  @override
  Future<void> cancelPrebuffer() async {}

  @override
  Future<void> crossfade(
    StreamInfo stream,
    MediaMeta meta, {
    Duration start = Duration.zero,
    Duration duration = const Duration(milliseconds: 3000),
    double tempoRatio = 1,
  }) async {}

  @override
  Future<PcmClip?> decodePcm(StreamInfo stream, {Duration from = Duration.zero, required Duration length}) async => null;

  @override
  void dispose() {
    _stateController.close();
    _cmdController.close();
  }
}

class DummyLoginLauncher implements LoginLauncher {
  final _controller = StreamController<String>.broadcast();

  @override
  Stream<String> get callbacks => _controller.stream;

  @override
  bool get automatic => false;

  @override
  Future<void> open(Uri url) async {}

  Future<bool> launch(Uri url) async => true;
}

void main() {
  testWidgets('Deps inherited widget provides dependencies to descendant context', (tester) async {
    final store = Store.memory();
    final settings = Settings(store);
    final mockClient = MockClient((_) async => http.Response('', 200));
    final sc = SoundCloud(store, settings, client: mockClient);
    final auth = ScAuth(store, mockClient, (uri) => uri);
    final lyrics = LyricsService(mockClient);
    final library = Library(store);
    final engine = DummyAudioEngine();
    final player = PlayerController(engine, sc, settings, library, store);
    final launcher = DummyLoginLauncher();
    final account = Account(auth, sc, library, launcher);
    final analyzer = BeatAnalyzer(sc, store);
    final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
    final taste = TasteModel(store);
    final mix = MixBuilder(sc: sc, library: library, taste: taste, player: player, dj: dj, store: store);
    final radioApi = RadioBrowser(mockClient);
    final radio = RadioService(radioApi, store, settings, player);
    final syncLog = SyncLog(store, library);
    final sync = SyncService(store: store, log: syncLog);

    late Deps resolvedDeps;

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

    expect(resolvedDeps.store, same(store));
    expect(resolvedDeps.settings, same(settings));
    expect(resolvedDeps.sc, same(sc));
    expect(resolvedDeps.lyrics, same(lyrics));
    expect(resolvedDeps.library, same(library));
    expect(resolvedDeps.player, same(player));
    expect(resolvedDeps.account, same(account));
    expect(resolvedDeps.dj, same(dj));
    expect(resolvedDeps.mix, same(mix));
    expect(resolvedDeps.taste, same(taste));
    expect(resolvedDeps.radio, same(radio));
    expect(resolvedDeps.sync, same(sync));
    expect(Deps.of(tester.element(find.byType(SizedBox))), same(resolvedDeps));

    final oldDeps = Deps(
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
      child: const SizedBox(),
    );
    expect(oldDeps.updateShouldNotify(oldDeps), false);

    player.dispose();
    sync.dispose();
    await tester.pump(const Duration(milliseconds: 500));
  });
}

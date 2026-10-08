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

class _MockEngine extends AudioEngine {
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
  bool get supportsLoudness => false;
  @override
  ValueListenable<Loudness> get loudness => ValueNotifier(Loudness.none);
  @override
  void dispose() {}
}

void main() {
  testWidgets('Deps inherited widget provides dependencies', (tester) async {
    final store = Store.memory();
    final settings = Settings(store);
    final httpClient = http.Client();
    final sc = SoundCloud(store, settings, client: httpClient);
    final auth = ScAuth(store, httpClient, sc.wrap);
    final lyrics = LyricsService(httpClient, wrap: sc.wrap);
    final library = Library(store);
    final engine = _MockEngine();
    final player = PlayerController(engine, sc, settings, library, store);
    final account = Account(auth, sc, library, LoginLauncher.create());
    final analyzer = BeatAnalyzer(sc, store);
    final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
    final taste = TasteModel(store);
    final mix = MixBuilder(sc: sc, library: library, player: player, dj: dj, store: store, taste: taste);
    final syncLog = SyncLog(store, library);
    final sync = SyncService(store: store, log: syncLog);
    final radio = RadioService(RadioBrowser(httpClient), store, settings, player);

    late Deps capturedDeps;

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

    expect(capturedDeps.settings, settings);
    expect(capturedDeps.sc, sc);
    expect(capturedDeps.lyrics, lyrics);
    expect(capturedDeps.library, library);
    expect(capturedDeps.player, player);
    expect(capturedDeps.account, account);
    expect(capturedDeps.dj, dj);
    expect(capturedDeps.mix, mix);
    expect(capturedDeps.taste, taste);
    expect(capturedDeps.radio, radio);
    expect(capturedDeps.store, store);
    expect(capturedDeps.sync, sync);

    sync.dispose();
    player.dispose();
    await tester.pump(const Duration(milliseconds: 500));
  });

  test('Platform helpers return consistent flags', () {
    expect(Platform.isWeb, false);
    expect(Platform.isDesktop || Platform.isAndroid || Platform.isApple || !Platform.isWeb, true);
  });
}

import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'core/deps.dart';
import 'core/settings.dart';
import 'core/store.dart';
import 'core/login_launcher.dart';
import 'dj/beat_analyzer.dart';
import 'dj/dj_flow_controller.dart';
import 'dj/mix_builder.dart';
import 'dj/taste.dart';
import 'library/account.dart';
import 'modules/updater/updater.dart';
import 'library/library.dart';
import 'lyrics/lyrics_service.dart';
import 'player/audio_engine.dart';
import 'player/drm_support.dart';
import 'player/player_controller.dart';
import 'radio/radio_browser.dart';
import 'radio/radio_service.dart';
import 'sc/auth.dart';
import 'sc/models.dart';
import 'sc/soundcloud.dart';
import 'sync/sync_log.dart';
import 'sync/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Probe DRM support while the store opens; startup waits for it only briefly.
  final drm = probeDrmPlayback()..then((v) => Track.drmPlayback = v, onError: (_) {});
  final store = await Store.open();
  final client = http.Client();
  final settings = Settings(store);
  final sc = SoundCloud(store, settings, client: client);
  final library = Library(store);
  final account = Account(ScAuth(store, client, sc.wrap), sc, library, LoginLauncher.create());
  final player = PlayerController(AudioEngine.create(), sc, settings, library, store);
  final analyzer = BeatAnalyzer(sc, store);
  final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
  final taste = TasteModel(store);
  final mix = MixBuilder(sc: sc, library: library, player: player, dj: dj, store: store, taste: taste);
  // DJ learning: how was a song left? Leaving early = disliked (won't appear in mixes again).
  player.djExclude = taste.isBanned;
  dj.taste = taste;
  player.onLeave = (track, played, duration, skipped) {
    if (!dj.state.isActive) return;
    final early =
        played < const Duration(seconds: 30) ||
        (duration > Duration.zero && played.inMilliseconds < duration.inMilliseconds * .15);
    taste.record(track, analyzer.peek(track), !skipped ? Outcome.complete : (early ? Outcome.earlySkip : Outcome.skip));
  };
  final syncLog = SyncLog(store, library);
  final sync = SyncService(store: store, log: syncLog);

  // Feed library events into the SyncLog.
  library.addLikeListener((track, liked) => syncLog.recordLike(track, liked));
  library.addLikeListener((track, liked) {
    if (liked && dj.state.isActive) taste.record(track, analyzer.peek(track), Outcome.like);
  });
  library.addHistoryListener((track) => syncLog.recordListen(track));

  await drm.timeout(const Duration(milliseconds: 300), onTimeout: () => false).catchError((_) => false);

  runApp(
    Deps(
      settings: settings,
      sc: sc,
      lyrics: LyricsService(client, wrap: sc.wrap),
      library: library,
      player: player,
      account: account,
      dj: dj,
      mix: mix,
      taste: taste,
      sync: sync,
      // Only loads favourites from the database; network only once web radio is used.
      radio: RadioService(RadioBrowser(client), store, settings, player),
      store: store,
      updates: createReleaseProvider(client),
      child: const PounceApp(),
    ),
  );
}

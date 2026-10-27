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
import 'package:pounce/sc/models.dart';
import 'package:pounce/sc/soundcloud.dart';
import 'package:pounce/sync/sync_log.dart';
import 'package:pounce/sync/sync_service.dart';

class _DummyEngine extends AudioEngine {
  @override
  Stream<EngineState> get states => const Stream.empty();
  @override
  Stream<RemoteCommand> get commands => const Stream.empty();
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
  ValueListenable<Loudness> get loudness => ValueNotifier(Loudness.none);
  @override
  SpectrumSource? get spectrum => null;
  @override
  void dispose() {}
}

void main() {
  group('Platform unit tests', () {
    test('Platform boolean flags return valid boolean values', () {
      expect(Platform.isWeb, isA<bool>());
      expect(Platform.isDesktop, isA<bool>());
      expect(Platform.isAndroid, isA<bool>());
      expect(Platform.isApple, isA<bool>());
    });
  });

  group('LoginLauncher unit tests', () {
    test('LoginLauncher.create produces a valid instance', () {
      final launcher = LoginLauncher.create();
      expect(launcher, isNotNull);
      expect(launcher.automatic, isA<bool>());
      expect(launcher.callbacks, isA<Stream<String>>());
    });
  });

  group('Deps InheritedWidget tests', () {
    testWidgets('Deps is accessible via BuildContext and Deps.of', (tester) async {
      final store = Store.memory();
      final client = http.Client();
      final settings = Settings(store);
      final sc = SoundCloud(store, settings, client: client);
      final library = Library(store);
      final player = PlayerController(_DummyEngine(), sc, settings, library, store);
      final taste = TasteModel(store);
      final analyzer = BeatAnalyzer(sc, store);
      final dj = DjFlowController(player: player, analyzer: analyzer, store: store);
      final mix = MixBuilder(sc: sc, library: library, player: player, dj: dj, store: store, taste: taste);
      final launcher = LoginLauncher.create();
      final auth = ScAuth(store, client, sc.wrap);
      final account = Account(auth, sc, library, launcher);
      final lyrics = LyricsService(client, wrap: sc.wrap);
      final radio = RadioService(RadioBrowser(client), store, settings, player);
      final syncLog = SyncLog(store, library);
      final sync = SyncService(store: store, log: syncLog);

      Deps? retrievedDeps;

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
              retrievedDeps = context.deps;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(retrievedDeps, isNotNull);
      expect(retrievedDeps!.settings, settings);
      expect(retrievedDeps!.sc, sc);
      expect(retrievedDeps!.updateShouldNotify(retrievedDeps!), isFalse);

      sync.dispose();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('SoundCloud Model edge cases', () {
    test('sized helper replaces artwork sizes properly', () {
      expect(sized('https://img.sndcdn.com/art-large.jpg', 't500x500'), 'https://img.sndcdn.com/art-t500x500.jpg');
      expect(sized('https://img.sndcdn.com/art-crop.png', 't300x300'), 'https://img.sndcdn.com/art-t300x300.png');
      expect(sized(null, 't500x500'), isNull);
    });

    test('Transcoding serialization and getters', () {
      final tHls = const Transcoding(
        url: 'https://stream.url',
        preset: 'aac',
        protocol: 'hls',
        mime: 'audio/mp4',
        snipped: false,
      );
      expect(tHls.isHls, isTrue);
      expect(tHls.isEncrypted, isFalse);

      final tEnc = const Transcoding(
        url: 'https://stream.url',
        preset: 'aac',
        protocol: 'ctr-encrypted-hls',
        mime: 'audio/mp4',
        snipped: false,
      );
      expect(tEnc.isHls, isFalse);
      expect(tEnc.isEncrypted, isTrue);

      final json = tEnc.toJson();
      expect(json['url'], 'https://stream.url');
      expect(json['format']['protocol'], 'ctr-encrypted-hls');

      final deserialized = Transcoding.fromJson(json);
      expect(deserialized.url, tEnc.url);
      expect(deserialized.isEncrypted, isTrue);
    });

    test('ScUser visuals / bannerUrl parsing', () {
      final userWithBanner = ScUser.fromJson({
        'id': 42,
        'username': 'testuser',
        'visuals': {
          'visuals': [
            {'visual_url': 'https://banner.jpg'}
          ]
        }
      });
      expect(userWithBanner.bannerUrl, 'https://banner.jpg');
      expect(userWithBanner.toJson()['id'], 42);
    });

    test('Track equality, hashCode, art, and properties', () {
      final t1 = Track(
        id: 10,
        title: 'Song A',
        user: const ScUser(id: 1, username: 'User1'),
        durationMs: 100000,
        artworkUrl: 'https://img.sndcdn.com/art-large.jpg',
      );
      final t2 = Track(
        id: 10,
        title: 'Song A Modified',
        user: const ScUser(id: 1, username: 'User1'),
        durationMs: 100000,
      );
      final t3 = Track(
        id: 20,
        title: 'Song B',
        user: const ScUser(id: 2, username: 'User2'),
        durationMs: 50000,
      );

      expect(t1 == t2, isTrue);
      expect(t1 == t3, isFalse);
      expect(t1.hashCode, 10.hashCode);
      expect(t1.art(), 'https://img.sndcdn.com/art-t500x500.jpg');
      expect(t2.art(), isNull);
    });

    test('ScPlaylist copyWith and art fallback', () {
      final pl = ScPlaylist(
        id: 1,
        title: 'Playlist',
        user: const ScUser(id: 1, username: 'U', avatarUrl: 'https://avatar-large.jpg'),
        tracks: [
          Track(
            id: 1,
            title: 'T1',
            user: const ScUser(id: 1, username: 'U'),
            durationMs: 10000,
            artworkUrl: 'https://track-art-large.jpg',
          )
        ],
      );

      expect(pl.art(), 'https://track-art-t500x500.jpg');

      final copied = pl.copyWith(tracks: []);
      expect(copied.tracks, isEmpty);
      expect(copied.art(), 'https://avatar-t500x500.jpg');
    });

    test('Resolved sealed class instances', () {
      final tr = Track(id: 1, title: 'T', user: const ScUser(id: 1, username: 'U'), durationMs: 100);
      final pl = ScPlaylist(id: 1, title: 'P', user: const ScUser(id: 1, username: 'U'));
      final usr = const ScUser(id: 1, username: 'U');

      expect(ResolvedTrack(tr).track, tr);
      expect(ResolvedPlaylist(pl).playlist, pl);
      expect(ResolvedUser(usr).user, usr);
    });
  });
}

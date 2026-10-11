import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/core/deps.dart';
import 'package:pounce/core/platform.dart';
import 'package:pounce/core/settings.dart';
import 'package:pounce/core/store.dart';
import 'package:pounce/dj/dj_flow_controller.dart';
import 'package:pounce/dj/mix_builder.dart';
import 'package:pounce/dj/taste.dart';
import 'package:pounce/library/account.dart';
import 'package:pounce/library/library.dart';
import 'package:pounce/lyrics/lyrics_service.dart';
import 'package:pounce/modules/updater/release_provider.dart';
import 'package:pounce/player/player_controller.dart';
import 'package:pounce/radio/radio_service.dart';
import 'package:pounce/sc/soundcloud.dart';
import 'package:pounce/sync/sync_service.dart';

class _FakeSettings extends Fake implements Settings {}
class _FakeSoundCloud extends Fake implements SoundCloud {}
class _FakeLyricsService extends Fake implements LyricsService {}
class _FakeLibrary extends Fake implements Library {}
class _FakePlayerController extends Fake implements PlayerController {}
class _FakeAccount extends Fake implements Account {}
class _FakeDjFlowController extends Fake implements DjFlowController {}
class _FakeMixBuilder extends Fake implements MixBuilder {}
class _FakeTasteModel extends Fake implements TasteModel {}
class _FakeRadioService extends Fake implements RadioService {}
class _FakeStore extends Fake implements Store {}
class _FakeSyncService extends Fake implements SyncService {}

void main() {
  group('Platform getters unit tests', () {
    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test('Platform boolean getters reflect target platforms correctly', () {
      expect(Platform.isWeb, isFalse);
      expect(Platform.isAndroid, isTrue);
      expect(Platform.isDesktop, isFalse);
      expect(Platform.isApple, isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(Platform.isDesktop, isTrue);
      expect(Platform.isAndroid, isFalse);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(Platform.isApple, isTrue);
    });
  });

  group('Deps inherited widget unit tests', () {
    testWidgets('Deps updateShouldNotify returns false', (WidgetTester tester) async {
      final settings = _FakeSettings();
      final sc = _FakeSoundCloud();
      final lyrics = _FakeLyricsService();
      final library = _FakeLibrary();
      final player = _FakePlayerController();
      final account = _FakeAccount();
      final taste = _FakeTasteModel();
      final dj = _FakeDjFlowController();
      final mix = _FakeMixBuilder();
      final radio = _FakeRadioService();
      final store = _FakeStore();
      final sync = _FakeSyncService();

      late Deps depsWidget1;
      late Deps depsWidget2;

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
              depsWidget1 = context.getInheritedWidgetOfExactType<Deps>()!;
              return const SizedBox();
            },
          ),
        ),
      );

      depsWidget2 = Deps(
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
        child: const SizedBox(),
      );

      expect(depsWidget1.updateShouldNotify(depsWidget2), isFalse);
    });
  });
}

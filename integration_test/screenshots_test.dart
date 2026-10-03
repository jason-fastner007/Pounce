import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pounce/app.dart';
import 'package:pounce/core/deps.dart';
import 'package:pounce/main.dart' as app;
import 'package:pounce/ui/widgets/track_tile.dart';

/// README screenshots in a phone layout (English, real content, muted playback).
/// flutter test integration_test/screenshots_test.dart -d linux --dart-define=SHOTS=$PWD/docs/screenshots
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const shots = String.fromEnvironment('SHOTS');

  Future<void> shot(WidgetTester t, String name) async {
    if (shots.isEmpty) return;
    await t.runAsync(() async {
      final img = await captureImage(find.byType(PounceApp).evaluate().first);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      await File('$shots/$name.png').writeAsBytes(png!.buffer.asUint8List());
    });
  }

  Future<void> wait(WidgetTester t, Duration d) async {
    final end = DateTime.now().add(d);
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> until(WidgetTester t, bool Function() cond, {int seconds = 20}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (!cond() && DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('README screenshots', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 2.75;
    app.main();
    await wait(t, const Duration(seconds: 4));
    final deps = Deps.of(t.element(find.byType(PounceApp)));
    deps.settings.locale = const Locale('en');
    deps.settings.setupDone = false;
    await deps.player.setVolume(0);
    await wait(t, const Duration(seconds: 2));

    // Setup wizard
    await shot(t, 'setup-welcome');
    await t.tap(find.text("Let's go"));
    await wait(t, const Duration(seconds: 1));
    await t.tap(find.text('Next')); // sources
    await wait(t, const Duration(seconds: 1));
    await t.tap(find.text('Next')); // account
    await wait(t, const Duration(seconds: 1));
    deps.mix.selected = {'techno', 'house', 'dnb'};
    await wait(t, const Duration(seconds: 1));
    await shot(t, 'setup-dj');
    await t.tap(find.text('Next'));
    await wait(t, const Duration(seconds: 1));
    await shot(t, 'setup-privacy');
    await t.tap(find.text('Start listening'));
    await wait(t, const Duration(seconds: 5));
    await shot(t, 'home');

    // Web radio search
    await t.tap(find.byIcon(Icons.search_rounded).first);
    await wait(t, const Duration(milliseconds: 800));
    await t.enterText(find.byType(SearchBar), 'melodic techno');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await wait(t, const Duration(seconds: 1));
    await t.tap(find.text('Web radio'));
    await wait(t, const Duration(seconds: 6));
    await shot(t, 'radio');

    // Player
    await t.tap(find.text('SoundCloud'));
    await until(t, () => find.byType(TrackTile).evaluate().isNotEmpty);
    await wait(t, const Duration(seconds: 2));
    await t.tap(find.byWidgetPredicate((w) => w is TrackTile && w.track.playable && !w.track.isPreview).first);
    await until(t, () => deps.player.playing && deps.player.position.value > const Duration(seconds: 3), seconds: 30);
    await t.tap(find.text(deps.player.current!.title).last);
    await wait(t, const Duration(seconds: 4));
    await shot(t, 'player');
    await t.tap(find.byIcon(Icons.keyboard_arrow_down_rounded).first);
    await wait(t, const Duration(seconds: 2));

    // DJ tab
    await t.tap(find.text('DJ').last);
    await wait(t, const Duration(seconds: 3));
    await shot(t, 'dj');

    await deps.player.pause();
    t.view.reset();
  });
}

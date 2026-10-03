import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pounce/core/deps.dart';
import 'package:pounce/main.dart' as app;
import 'package:pounce/ui/shell.dart';
import 'package:pounce/ui/widgets/track_tile.dart';
import 'package:material_ui/material_ui.dart';

/// End-to-end: real API, real (muted) playback, screenshots.
/// flutter test integration_test -d linux --dart-define=SHOTS=/path
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const shots = String.fromEnvironment('SHOTS');

  Future<void> shot(WidgetTester t, String name) async {
    if (shots.isEmpty) return;
    await t.runAsync(() async {
      final img = await captureImage(find.byType(Shell).evaluate().first);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      await File('$shots/$name.png').writeAsBytes(png!.buffer.asUint8List());
    });
  }

  /// Like pumpAndSettle, but compatible with endless animations (shimmer, equaliser).
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

  testWidgets('Suchen, abspielen, Player, Lyrics, RTL', (t) async {
    app.main();
    await wait(t, const Duration(seconds: 6));
    final deps = Deps.of(t.element(find.byType(Shell)));
    final player = deps.player;
    deps.settings.locale = const Locale('de');
    await player.setVolume(0);
    await wait(t, const Duration(seconds: 2));
    await shot(t, '01_home');

    // Suche
    await t.tap(find.byIcon(Icons.search_rounded).first);
    await wait(t, const Duration(milliseconds: 600));
    await t.enterText(find.byType(SearchBar), 'Rick Astley Never Gonna Give You Up');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await until(t, () => find.byType(TrackTile).evaluate().isNotEmpty);
    await wait(t, const Duration(seconds: 2));
    await shot(t, '02_search');

    // Play
    // First playable hit (DRM-protected ones are skipped).
    await t.tap(find.byWidgetPredicate((w) => w is TrackTile && w.track.playable).first);
    await until(t, () => player.playing && player.position.value > const Duration(seconds: 2), seconds: 30);
    expect(player.playing, isTrue, reason: 'Wiedergabe startet nicht (${player.error})');
    expect(player.position.value, greaterThan(const Duration(seconds: 2)));
    await shot(t, '03_mini_player');

    // Expand the player
    await t.tap(find.text(player.current!.title).last);
    await wait(t, const Duration(seconds: 2));
    await shot(t, '04_player');

    // Seek
    await player.seek(const Duration(seconds: 60));
    await until(t, () => player.position.value > const Duration(seconds: 61), seconds: 15);
    expect(player.position.value, greaterThan(const Duration(seconds: 60)));
    await wait(t, const Duration(seconds: 3));
    await shot(t, '05_player_lyrics');

    // Arabic -> whole UI mirrored
    deps.settings.locale = const Locale('ar');
    await wait(t, const Duration(seconds: 2));
    await shot(t, '06_rtl_player');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await wait(t, const Duration(seconds: 2));
    await shot(t, '07_rtl_search');

    // Handy-Layout
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 2.75;
    deps.settings.locale = const Locale('de');
    await wait(t, const Duration(seconds: 2));
    await shot(t, '08_phone_search');
    await t.tap(find.text(player.current!.title).last);
    await wait(t, const Duration(seconds: 2));
    await shot(t, '09_phone_player');
    await t.tap(find.byTooltip('Songtext'));
    await wait(t, const Duration(seconds: 4));
    await shot(t, '10_phone_lyrics');

    await player.pause();
    await wait(t, const Duration(seconds: 1));
    expect(player.playing, isFalse);
    t.view.reset();
  });
}

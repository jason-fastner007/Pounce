import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pounce/l10n/gen/app_localizations.dart';
import 'package:pounce/ui/widgets/common.dart';
import 'package:pounce/ui/widgets/studio.dart';
import 'package:pounce/ui/widgets/track_tile.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  testWidgets('StatusTag and Mono widgets render text properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildApp(
        const Column(
          children: [
            StatusTag('DRM', tooltip: 'DRM Protected'),
            Mono('03:45'),
          ],
        ),
      ),
    );

    expect(find.text('DRM'), findsOneWidget);
    expect(find.text('03:45'), findsOneWidget);
  });

  testWidgets('Overline and SectionHeader render headers correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildApp(
        const Column(
          children: [
            Overline('Popular Tracks', index: 1),
            SectionHeader('Featured Playlists'),
          ],
        ),
      ),
    );

    expect(find.text('POPULAR TRACKS'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);
    expect(find.text('Featured Playlists'), findsOneWidget);
  });

  testWidgets('MessageView renders icon and text', (WidgetTester tester) async {
    await tester.pumpWidget(
      buildApp(
        const MessageView(
          icon: Icons.error_outline,
          text: 'Something went wrong',
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}

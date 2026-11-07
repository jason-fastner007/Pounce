import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pounce/ui/widgets/cards.dart';
import 'package:pounce/ui/widgets/track_tile.dart';

void main() {
  testWidgets('PressableCard triggers onTap callback on tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PressableCard(
            onTap: () => tapped = true,
            child: const Text('Test Content'),
          ),
        ),
      ),
    );

    expect(find.text('Test Content'), findsOneWidget);
    await tester.tap(find.text('Test Content'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('StatusTag displays text and configures Tooltip when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusTag('DRM', tooltip: 'Digital Rights Management'),
        ),
      ),
    );

    expect(find.text('DRM'), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Digital Rights Management');
  });

  testWidgets('StatusTag displays text without Tooltip when tooltip is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusTag('30S'),
        ),
      ),
    );

    expect(find.text('30S'), findsOneWidget);
    expect(find.byType(Tooltip), findsNothing);
  });
}

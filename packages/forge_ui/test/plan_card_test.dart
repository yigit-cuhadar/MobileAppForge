import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String? tag,
    VoidCallback? onAction,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: PlanCard(
          title: 'Premium',
          tag: tag,
          benefits: const ['One', 'Two'],
          actionLabel: 'Get Premium',
          onAction: onAction ?? () {},
        ),
      ),
    ),
  );

  testWidgets('shows the tag beside the title when given', (tester) async {
    await pump(tester, tag: '7 days free');

    expect(find.text('Premium'), findsOneWidget);
    expect(find.widgetWithText(ForgeTag, '7 days free'), findsOneWidget);
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('shows no tag without one', (tester) async {
    await pump(tester);

    expect(find.byType(ForgeTag), findsNothing);
  });

  testWidgets('the button runs the action', (tester) async {
    var taps = 0;
    await pump(tester, onAction: () => taps++);

    await tester.tap(find.widgetWithText(ForgeButton, 'Get Premium'));
    expect(taps, 1);
  });
}

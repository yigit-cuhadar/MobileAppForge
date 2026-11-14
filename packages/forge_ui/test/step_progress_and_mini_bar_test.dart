import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  final colors = ForgeTheme.light().extension<ForgeStyle>()!.colors;

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  group('StepProgress', () {
    testWidgets('the done and current parts are accent, the rest line', (
      tester,
    ) async {
      await pump(
        tester,
        const StepProgress(
          count: 9,
          current: 4,
          caption: 'Step 4 of 9 · [STEP NAME]',
        ),
      );

      final parts = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(StepProgress),
              matching: find.byType(Container),
            ),
          )
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      expect(parts, [
        ...List.filled(4, colors.accent),
        ...List.filled(5, colors.line),
      ]);
      expect(find.text('Step 4 of 9 · [STEP NAME]'), findsOneWidget);
    });
  });

  group('MiniBar', () {
    testWidgets('is 56px and a tap opens what runs', (tester) async {
      var taps = 0;
      await pump(
        tester,
        MiniBar(
          icon: ForgeIcons.timer,
          title: 'Ongoing task',
          detail: '1:45 left',
          onTap: () => taps++,
        ),
      );

      expect(tester.getSize(find.byType(MiniBar)).height, MiniBar.height);
      expect(find.text('1:45 left'), findsOneWidget);
      await tester.tap(find.byType(MiniBar));
      expect(taps, 1);
    });
  });
}

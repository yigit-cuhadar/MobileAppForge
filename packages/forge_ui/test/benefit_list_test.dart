import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(body: child),
    ),
  );

  testWidgets('numbered marks each line with its number in mono', (
    tester,
  ) async {
    await pump(tester, const BenefitList.numbered(['One', 'Two', 'Three']));

    final style = ForgeStyle.of(tester.element(find.byType(BenefitList)));
    for (final n in ['1', '2', '3']) {
      final number = tester.widget<Text>(find.text(n));
      expect(number.style!.fontFamily, style.data.fontFamily);
      expect(number.style!.color, style.colors.onAccentSoft);
    }
    expect(find.byType(ForgeIcon), findsNothing);
  });

  testWidgets('checked marks each line with a success check', (tester) async {
    await pump(tester, const BenefitList.checked(['One', 'Two']));

    final colors = ForgeStyle.of(tester.element(find.byType(BenefitList)))
        .colors;
    final checks = tester.widgetList<ForgeIcon>(find.byType(ForgeIcon));
    expect(checks, hasLength(2));
    expect(checks.every((c) => c.color == colors.success), isTrue);
    expect(find.text('1'), findsNothing);
  });
}

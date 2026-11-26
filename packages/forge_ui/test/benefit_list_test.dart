import 'package:material_ui/material_ui.dart';
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

  testWidgets('danger tints the numbers and a line ends with its trailing', (
    tester,
  ) async {
    await pump(
      tester,
      const BenefitList.numbered(
        ['One', 'Two'],
        danger: true,
        trailing: {1: Text('Watch')},
      ),
    );

    final colors = ForgeStyle.of(tester.element(find.byType(BenefitList)))
        .colors;
    expect(
      tester.widget<Text>(find.text('1')).style!.color,
      Color.lerp(colors.ink, colors.danger, 0.7),
    );
    expect(find.text('Watch'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Watch')).dx,
      greaterThan(tester.getTopRight(find.text('Two')).dx),
    );
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

  testWidgets('described gives each an icon tile, a title and a line', (
    tester,
  ) async {
    await pump(
      tester,
      const BenefitList.described([
        (icon: ForgeIcons.star, title: 'One', detail: 'Does one thing'),
        (icon: ForgeIcons.check, title: 'Two', detail: 'Does another'),
      ]),
    );

    expect(find.byType(ForgeIcon), findsNWidgets(2));
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Does another'), findsOneWidget);
  });
}

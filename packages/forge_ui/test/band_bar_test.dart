import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  const fills = BandBarFills(
    below: Color(0xFF000001),
    within: Color(0xFF000002),
    above: Color(0xFF000003),
  );

  Future<Color?> fillOf(
    WidgetTester tester,
    double value, {
    BandBarFills? fills,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Scaffold(
          body: BandBar(
            label: 'Item title',
            valueLabel: '[VALUE]',
            value: value,
            low: 0.4,
            high: 0.8,
            fills: fills,
          ),
        ),
      ),
    );
    final boxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(BandBar),
        matching: find.byType(DecoratedBox),
      ),
    );
    return (boxes.elementAt(1).decoration as BoxDecoration).color;
  }

  testWidgets('takes the app fill for each place of the value', (tester) async {
    expect(await fillOf(tester, 0.2, fills: fills), fills.below);
    expect(await fillOf(tester, 0.6, fills: fills), fills.within);
    expect(await fillOf(tester, 0.9, fills: fills), fills.above);
  });

  testWidgets('without fills, accent within and danger above', (tester) async {
    final colors = ForgeTheme.light().extension<ForgeStyle>()!.colors;

    expect(await fillOf(tester, 0.6), colors.accent);
    expect(await fillOf(tester, 0.9), colors.danger);
  });
}

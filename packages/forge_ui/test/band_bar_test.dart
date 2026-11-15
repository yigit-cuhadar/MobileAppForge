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

  testWidgets('the compact form keeps its ticks under 13/11px labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: const Scaffold(
          body: BandBar.compact(
            label: 'Item title',
            valueLabel: '[VALUE]',
            value: 0.5,
            low: 0.4,
            high: 0.8,
          ),
        ),
      ),
    );
    final colors = ForgeStyle.of(tester.element(find.byType(BandBar))).colors;
    final ticks = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(BandBar),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.color == colors.lineStrong,
        ),
      ),
    );

    expect(ticks, hasLength(2));
    expect(tester.widget<Text>(find.text('Item title')).style!.fontSize, 13);
    expect(tester.widget<Text>(find.text('[VALUE]')).style!.fontSize, 11);
    final label = tester.getRect(find.text('Item title'));
    final track = tester.getRect(
      find
          .descendant(of: find.byType(BandBar), matching: find.byType(Stack))
          .first,
    );
    expect(track.top - label.bottom, Gap.xs);
  });
}

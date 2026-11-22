import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(children: [child]),
        ),
      ),
    ),
  );

  ForgePalette colors(WidgetTester tester) =>
      ForgeStyle.of(tester.element(find.byType(Scaffold))).colors;

  group('StatTile with a chart', () {
    testWidgets('sets the chart at the figure\'s right and still opens', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        StatTile(
          title: 'Metric A',
          onTap: () => taps++,
          figure: '133.5',
          unit: '[UNIT]',
          caption: '[CAPTION]',
          chart: const TrendLine(values: [1, 3, 2, 4]),
        ),
      );

      final chart = tester.getRect(find.byType(TrendLine));
      final figure = tester.getRect(find.text('133.5'));
      expect(chart.width, 140);
      expect(chart.left, greaterThan(figure.right));
      await tester.tap(find.byType(TrendLine));
      expect(taps, 1);
    });
  });

  group('TrendLine', () {
    testWidgets('the plain line is skipped by screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, const TrendLine(values: [1, 2]));

      expect(
        find.descendant(
          of: find.byType(TrendLine),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(find.byType(TrendLine)).height, 48);
      semantics.dispose();
    });

    testWidgets('the scaled line shows its scale and reads its label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(
        tester,
        const TrendLine.scaled(
          values: [72.5, 71, 70.4],
          highLabel: '72.5',
          lowLabel: '70.4',
          startLabel: 'Aug 26',
          endLabel: 'Nov 18',
          semanticLabel: 'Metric, last 12 weeks',
        ),
      );

      for (final label in ['72.5', '70.4', 'Aug 26', 'Nov 18']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Metric, last 12 weeks'), findsOneWidget);
      // The dates sit under the line's ends, right of the values.
      expect(
        tester.getTopLeft(find.text('Aug 26')).dx,
        greaterThan(tester.getTopRight(find.text('72.5')).dx),
      );
      semantics.dispose();
    });
  });

  group('DayBars', () {
    testWidgets('the busiest day takes the full height, an empty day a '
        'short sunken line', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 170,
          child: DayBars(
            days: [
              (label: 'M', value: 0),
              (label: 'T', value: 40),
              (label: 'W', value: 20),
            ],
            color: Color(0xFF2F6E73),
            semanticLabel: '[LABEL]',
          ),
        ),
      );

      final bars = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(DayBars),
              matching: find.byType(Container),
            ),
          )
          .toList();
      double height(int i) => tester.getSize(find.byWidget(bars[i])).height;
      Color? fill(int i) => (bars[i].decoration! as BoxDecoration).color;
      expect([height(0), height(1), height(2)], [3, 40, 20]);
      expect(fill(0), colors(tester).surfaceSunken);
      expect(fill(1), const Color(0xFF2F6E73));
    });
  });

  group('Progress.segmented', () {
    testWidgets('fills the segments before the value and part of the one '
        'it ends in', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 300,
          child: Progress.segmented(value: 1.5 / 4, segments: 4),
        ),
      );

      final shares = tester
          .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .map((box) => box.widthFactor)
          .toList();
      expect(shares, [1, 0.5, 0, 0]);
    });
  });

  group('ColorKey', () {
    testWidgets('shows a swatch in each colour before its label', (
      tester,
    ) async {
      await pump(
        tester,
        const ColorKey(
          entries: [
            ColorKeyEntry(Color(0xFFB9D3C4), 'Under [VALUE] · 4'),
            ColorKeyEntry(Color(0xFFA6473C), 'Over [VALUE] · 0'),
          ],
        ),
      );

      final swatches = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      expect(swatches, const [Color(0xFFB9D3C4), Color(0xFFA6473C)]);
      expect(
        tester.getTopLeft(find.text('Under [VALUE] · 4')).dx,
        greaterThan(tester.getTopLeft(find.byType(Container).first).dx),
      );
    });
  });
}

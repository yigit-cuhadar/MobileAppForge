import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/card_frame.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [child],
        ),
      ),
    ),
  );

  ForgePalette colors(WidgetTester tester) =>
      ForgeStyle.of(tester.element(find.byType(Scaffold))).colors;

  group('Chart.line', () {
    Widget line() => Chart.line(
      title: 'Value',
      detail: '— target [VALUE]',
      values: const [5, 4, 3, 2],
      pointLabel: (i) => 'Point $i',
      target: 1,
      startLabel: '12 weeks ago',
      endLabel: 'now · [VALUE]',
      semanticLabel: 'Value over 12 weeks',
    );

    testWidgets('a tap shows the nearest point in a tag', (tester) async {
      await pump(tester, line());
      expect(find.textContaining('Point'), findsNothing);

      final chart = find.bySemanticsLabel('Value over 12 weeks');
      final box = tester.getRect(chart);
      await tester.tapAt(Offset(box.left + 2, box.center.dy));
      await tester.pump();
      expect(find.text('Point 0'), findsOneWidget);

      await tester.tapAt(Offset(box.right - 2, box.center.dy));
      await tester.pump();
      expect(find.text('Point 0'), findsNothing);
      expect(find.text('Point 3'), findsOneWidget);

      final tag = tester.widget<Container>(
        find.ancestor(
          of: find.text('Point 3'),
          matching: find.byType(Container),
        ),
      );
      expect((tag.decoration! as BoxDecoration).color, colors(tester).ink);
      expect(
        tester.widget<Text>(find.text('Point 3')).style!.color,
        colors(tester).surface,
      );
    });

    testWidgets('the end labels sit under the line', (tester) async {
      await pump(tester, line());
      expect(find.text('12 weeks ago'), findsOneWidget);
      expect(find.text('now · [VALUE]'), findsOneWidget);
    });
  });

  testWidgets('Chart.bar writes values and marks the current bar', (
    tester,
  ) async {
    await pump(
      tester,
      const Chart.bar(
        title: 'Count · this week',
        detail: 'goal [VALUE]',
        bars: [
          ChartBar(label: 'M', value: 8.2, valueLabel: '8.2k'),
          ChartBar(label: 'T', value: 6.2, valueLabel: '6.2k'),
          ChartBar(label: 'W'),
        ],
        current: 1,
        target: 10,
        semanticLabel: 'Count this week',
      ),
    );

    final c = colors(tester);
    expect(tester.widget<Text>(find.text('8.2k')).style?.color, c.inkMuted);
    expect(tester.widget<Text>(find.text('6.2k')).style?.color, c.ink);
    expect(
      tester.widget<Text>(find.text('T')).style?.fontWeight,
      FontWeight.w700,
    );
    expect(find.text('W'), findsOneWidget);
  });

  testWidgets('Chart.bar draws no bar for a negative value', (tester) async {
    await pump(
      tester,
      const Chart.bar(
        title: 'Count · this week',
        bars: [
          ChartBar(label: 'M', value: -2, valueLabel: '-2'),
          ChartBar(label: 'T', value: 4, valueLabel: '4'),
        ],
        semanticLabel: 'Count this week',
      ),
    );

    expect(tester.takeException(), isNull);
    final bar = find.descendant(
      of: find.ancestor(of: find.text('-2'), matching: find.byType(Column)),
      matching: find.byType(Container),
    );
    expect(tester.getSize(bar.first).height, 0);
  });

  group('Chart.barDense', () {
    Widget dense() => Chart.barDense(
      title: 'Last 30 days',
      detail: 'goal [VALUE]',
      bars: [
        for (var i = 0; i < 30; i++)
          ChartBar(
            label: 'Day $i',
            value: 4.0 + i % 7,
            valueLabel: '[VALUE] · Day $i',
          ),
      ],
      current: 29,
      target: 10,
      semanticLabel: 'Count over 30 days',
    );

    testWidgets('shows no values and labels only the ends', (tester) async {
      await pump(tester, dense());
      expect(find.textContaining('[VALUE] ·'), findsNothing);
      expect(find.text('Day 0'), findsOneWidget);
      expect(find.text('Day 29'), findsOneWidget);
      expect(find.text('Day 15'), findsNothing);
    });

    testWidgets('a tap shows that bar in a tag, in accent', (tester) async {
      await pump(tester, dense());
      final box = tester.getRect(find.bySemanticsLabel('Count over 30 days'));
      await tester.tapAt(
        Offset(box.left + box.width * 10.5 / 30, box.bottom - 2),
      );
      await tester.pump();
      expect(find.text('[VALUE] · Day 10'), findsOneWidget);

      final bars = find.descendant(
        of: find.byType(Chart),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).borderRadius ==
                  const BorderRadius.all(Radius.circular(2)),
        ),
      );
      Color fill(int i) =>
          (tester.widget<Container>(bars.at(i)).decoration! as BoxDecoration)
              .color!;
      final c = colors(tester);
      expect(fill(10), c.accent);
      expect(fill(29), c.accent);
      expect(fill(9), c.accent.withValues(alpha: 0.55));
      // 2px apart.
      expect(
        tester.getRect(bars.at(11)).left - tester.getRect(bars.at(10)).right,
        closeTo(2, 0.01),
      );
    });
  });

  group('Chart.bar with a band', () {
    Widget banded({bool card = true}) => Chart.bar(
      title: 'Last 12 weeks',
      bars: const [
        ChartBar(label: '1', value: 8, valueLabel: '8'),
        ChartBar(label: '2', value: 14, valueLabel: '14'),
        ChartBar(label: '3', value: 22, valueLabel: '22'),
      ],
      band: (low: 10, high: 20),
      card: card,
      semanticLabel: 'Count over 12 weeks',
    );

    Color fillOf(WidgetTester tester, String value) {
      final bar = find.descendant(
        of: find.ancestor(of: find.text(value), matching: find.byType(Column)),
        matching: find.byType(Container),
      );
      return (tester.widget<Container>(bar.first).decoration! as BoxDecoration)
          .color!;
    }

    testWidgets('colours each bar by where it lands', (tester) async {
      await pump(tester, banded());
      final c = colors(tester);
      expect(fillOf(tester, '8'), Color.lerp(c.surface, c.accent, 0.4));
      expect(fillOf(tester, '14'), c.accent);
      expect(fillOf(tester, '22'), c.danger);
    });

    testWidgets('the band is a sunken stripe from low to high', (tester) async {
      await pump(tester, banded());
      final stripe = find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == colors(tester).surfaceSunken,
      );
      final bar14 = find.descendant(
        of: find.ancestor(of: find.text('14'), matching: find.byType(Column)),
        matching: find.byType(Container),
      );
      final band = tester.getRect(stripe);
      final bar = tester.getRect(bar14.first);
      // 14 is 40% of the way from 10 to 20.
      expect(bar.top, closeTo(band.bottom - band.height * 0.4, 0.01));
    });

    testWidgets('without its card it keeps the title only', (tester) async {
      await pump(tester, banded(card: false));
      expect(find.byType(CardFrame), findsNothing);
      expect(find.text('Last 12 weeks'), findsOneWidget);
    });
  });

  testWidgets('loading keeps the title and shimmers the rest', (tester) async {
    await pump(tester, const Chart.loading(title: 'Value', detail: '12 weeks'));
    expect(find.text('Value'), findsOneWidget);
    expect(find.byType(SkeletonBar), findsNWidgets(3));
  });

  testWidgets('empty shows its message and actions', (tester) async {
    var adds = 0;
    await pump(
      tester,
      Chart.empty(
        title: 'Value',
        detail: '12 weeks',
        emptyTitle: 'No entries yet',
        message: 'Add an entry to start the line.',
        actions: [
          ForgeButton(
            label: 'Add entry',
            onPressed: () => adds++,
            variant: ForgeButtonVariant.secondary,
          ),
        ],
      ),
    );
    await tester.tap(find.text('Add entry'));
    expect(adds, 1);
  });

  testWidgets('error retries', (tester) async {
    var retries = 0;
    await pump(
      tester,
      Chart.error(
        title: 'Value',
        detail: '12 weeks',
        errorTitle: "Couldn't load the chart",
        message: 'Check your connection and try again.',
        onRetry: () => retries++,
        retryLabel: 'Retry',
      ),
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });

  group('MultiSeriesChart', () {
    String format(double v) => v.toStringAsFixed(1);
    final from = DateTime(2025, 8, 25);
    final to = DateTime(2025, 11, 16);
    ChartPoint at(int day, double value) =>
        (day: DateTime(2025, 8, 25 + day), value: value);

    Widget chart({
      void Function(int)? onSeriesTap,
      VoidCallback? onAdd,
      bool target = false,
      List<ChartSeries>? series,
      Widget? range,
      String? lockedCaption,
      VoidCallback? onLockedCaptionTap,
    }) => MultiSeriesChart(
      title: 'Series',
      detail: '12 weeks',
      series:
          series ??
          [
            ChartSeries(
              label: 'Series A',
              points: [at(0, 3), at(40, 2), at(83, 1)],
              format: format,
              look: SeriesLook.accent,
              target: target ? 1.5 : null,
              targetLabel: target ? 'Target' : null,
            ),
            ChartSeries.bars(
              label: 'Series B',
              points: [at(0, 10), at(35, 20), at(77, 30)],
              format: format,
            ),
          ],
      from: from,
      to: to,
      dateLabel: (day) => 'Day ${day.month}/${day.day}',
      startLabel: 'Aug 25',
      endLabel: 'Nov 16',
      onSeriesTap: onSeriesTap ?? (_) {},
      addLabel: 'Add',
      onAdd: onAdd ?? () {},
      range: range,
      lockedCaption: lockedCaption,
      onLockedCaptionTap: onLockedCaptionTap,
      semanticLabel: 'Series over 12 weeks',
    );

    Rect plot(WidgetTester tester) =>
        tester.getRect(find.bySemanticsLabel('Series over 12 weeks'));

    testWidgets('chips report taps', (tester) async {
      final tapped = <int>[];
      var adds = 0;
      await pump(tester, chart(onSeriesTap: tapped.add, onAdd: () => adds++));

      expect(find.byType(ForgeChip), findsNWidgets(3));
      await tester.tap(find.text('Series B'));
      await tester.tap(find.text('Add'));
      expect(tapped, [1]);
      expect(adds, 1);
    });

    testWidgets('a tap shows each series on the nearest day with an entry', (
      tester,
    ) async {
      await pump(tester, chart());

      final box = plot(tester);
      await tester.tapAt(Offset(box.right - 4, box.bottom - 4));
      await tester.pump();
      expect(find.text('Day 11/16'), findsOneWidget);
      expect(find.text('1.0'), findsOneWidget);
      expect(find.text('30.0'), findsNothing);

      // Day 40 of 84 lies just left of the middle; only Series A has it.
      await tester.tapAt(
        Offset(box.left + box.width * 40.5 / 84, box.center.dy),
      );
      await tester.pump();
      expect(find.text('Day 10/4'), findsOneWidget);
      expect(find.text('2.0'), findsOneWidget);
    });

    testWidgets('a target is labelled in its series colour', (tester) async {
      await pump(tester, chart(target: true));
      expect(
        tester.widget<Text>(find.text('Target')).style?.color,
        colors(tester).accent,
      );
    });

    testWidgets('an averaged series shows its legend and its daily value', (
      tester,
    ) async {
      await pump(
        tester,
        chart(
          series: [
            ChartSeries.averaged(
              label: 'Series A',
              points: [at(0, 3), at(83, 1)],
              average: [at(0, 3), at(83, 2)],
              dailyLabel: 'daily value',
              averageLabel: '7-day average',
              format: format,
              look: SeriesLook.accent,
            ),
          ],
        ),
      );
      expect(find.text('daily value'), findsOneWidget);
      expect(find.text('7-day average'), findsOneWidget);

      final box = plot(tester);
      await tester.tapAt(Offset(box.right - 4, box.center.dy));
      await tester.pump();
      expect(find.text('1.0'), findsOneWidget);
    });

    testWidgets('a failed series keeps its chip and retries on its line', (
      tester,
    ) async {
      var retries = 0;
      await pump(
        tester,
        chart(
          series: [
            ChartSeries(
              label: 'Series A',
              points: [at(0, 3), at(83, 1)],
              format: format,
              look: SeriesLook.accent,
            ),
            ChartSeries.failed(
              label: 'Series B',
              look: SeriesLook.info,
              error: "Couldn't load Series B.",
              retryLabel: 'Retry',
              onRetry: () => retries++,
            ),
          ],
        ),
      );
      expect(find.text('Series B'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text("Couldn't load Series B.")).style?.color,
        colors(tester).danger,
      );
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('the range sits under the chart and the locked caption opens', (
      tester,
    ) async {
      var opened = 0;
      await pump(
        tester,
        chart(
          range: const Text('Range'),
          lockedCaption: 'See older results',
          onLockedCaptionTap: () => opened++,
        ),
      );
      expect(
        tester.getTopLeft(find.text('Range')).dy,
        greaterThan(plot(tester).bottom),
      );
      expect(find.byType(ForgeIcon), findsWidgets);
      await tester.tap(find.text('See older results'));
      expect(opened, 1);
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text('See older results'),
                matching: find.byType(InkWell),
              ),
            )
            .height,
        greaterThanOrEqualTo(ForgeTheme.tapMin),
      );
    });

    testWidgets('a line with no points yet draws nothing and taps safely', (
      tester,
    ) async {
      await pump(
        tester,
        chart(
          series: [
            ChartSeries(
              label: 'Series A',
              points: const [],
              format: format,
              look: SeriesLook.accent,
            ),
          ],
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.tapAt(plot(tester).center);
      await tester.pump();
      expect(find.textContaining('Day'), findsNothing);
    });

    testWidgets('empty keeps the range and the locked caption', (tester) async {
      var opened = 0;
      await pump(
        tester,
        MultiSeriesChart.empty(
          title: 'Series',
          emptyTitle: 'Nothing in this range',
          message: 'Nothing to show in this range yet.',
          range: const Text('Range'),
          lockedCaption: 'See older results',
          onLockedCaptionTap: () => opened++,
        ),
      );
      expect(find.text('Nothing in this range'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Range')).dy,
        greaterThan(
          tester
              .getBottomLeft(find.text('Nothing to show in this range yet.'))
              .dy,
        ),
      );
      await tester.tap(find.text('See older results'));
      expect(opened, 1);
    });

    testWidgets('loading shimmers chips, chart and end labels', (tester) async {
      await pump(
        tester,
        const MultiSeriesChart.loading(title: 'Series', detail: '12 weeks'),
      );
      expect(find.byType(SkeletonBar), findsNWidgets(6));
    });

    testWidgets('error retries', (tester) async {
      var retries = 0;
      await pump(
        tester,
        MultiSeriesChart.error(
          title: 'Series',
          errorTitle: "Couldn't load the chart",
          message: 'Check your connection and try again.',
          onRetry: () => retries++,
          retryLabel: 'Retry',
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });
  });

  group('Sparkline', () {
    testWidgets('the card opens its page', (tester) async {
      var taps = 0;
      await pump(
        tester,
        Sparkline(
          title: 'Trend',
          onTap: () => taps++,
          figure: '[VALUE]',
          caption: '[DETAIL] · Nov 10',
          values: const [5, 4, 4.5, 3],
          startLabel: '12 weeks ago · [VALUE]',
          endLabel: 'now · [VALUE]',
          semanticLabel: 'Value over the last 12 weeks',
        ),
      );
      await tester.tap(find.text('[VALUE]'));
      expect(taps, 1);
    });

    testWidgets('error shows a dash, the message in danger and Retry', (
      tester,
    ) async {
      var retries = 0;
      await pump(
        tester,
        Sparkline.error(
          title: 'Trend',
          message: "Couldn't load the trend",
          onRetry: () => retries++,
          retryLabel: 'Retry',
        ),
      );
      expect(find.text('—'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text("Couldn't load the trend")).style?.color,
        colors(tester).danger,
      );
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('empty and loading', (tester) async {
      await pump(
        tester,
        const Column(
          children: [
            Sparkline.empty(
              title: 'Trend',
              figure: '[VALUE]',
              message: 'Add one more entry to see the trend',
            ),
            Sparkline.loading(title: 'Trend'),
          ],
        ),
      );
      expect(find.text('Add one more entry to see the trend'), findsOneWidget);
      expect(find.byType(SkeletonBar), findsNWidgets(2));
    });

    testWidgets('the empty box stands alone with its message', (tester) async {
      await pump(
        tester,
        const SparklineEmptyBox(message: 'Add one more entry to see the trend'),
      );
      expect(
        find.descendant(
          of: find.byType(SparklineEmptyBox),
          matching: find.text('Add one more entry to see the trend'),
        ),
        findsOneWidget,
      );
    });
  });

  group('StatTile', () {
    testWidgets('the tile opens its page', (tester) async {
      var taps = 0;
      await pump(
        tester,
        StatTile(
          title: 'Metric A',
          detail: 'This week',
          onTap: () => taps++,
          figure: '95',
          unit: 'min',
          caption: '3 entries',
        ),
      );
      await tester.tap(find.text('95'));
      expect(taps, 1);
    });

    testWidgets('the figure form is not a tap target', (tester) async {
      await pump(
        tester,
        const StatTile.figure(
          figure: '5.2',
          unit: '[UNIT]',
          caption: '[DETAIL]',
        ),
      );
      expect(find.byType(InkWell), findsNothing);
      expect(find.byType(ForgeIcon), findsNothing);
    });

    testWidgets('a compact change is coloured by the way that is good', (
      tester,
    ) async {
      await pump(
        tester,
        const Column(
          children: [
            StatTile.compact(
              label: 'Value A',
              figure: '82.4 [UNIT]',
              change: '-1.7',
              changeIsGood: true,
            ),
            StatTile.compact(
              label: 'Value C',
              figure: '105 [UNIT]',
              change: '+1.0',
              changeIsGood: false,
            ),
          ],
        ),
      );
      final c = colors(tester);
      // A true minus sign, not a hyphen.
      expect(tester.widget<Text>(find.text('−1.7')).style?.color, c.success);
      expect(tester.widget<Text>(find.text('+1.0')).style?.color, c.danger);
    });

    testWidgets('a compact change with no good way is ink-muted', (
      tester,
    ) async {
      await pump(
        tester,
        const StatTile.compact(label: 'Value A', figure: '1', change: '+1.0'),
      );
      expect(
        tester.widget<Text>(find.text('+1.0')).style?.color,
        colors(tester).inkMuted,
      );
    });

    testWidgets('a compact tile without a change has no change line', (
      tester,
    ) async {
      await pump(tester, const StatTile.compact(label: 'Value A', figure: '—'));
      final lines = find.descendant(
        of: find.byType(StatTile),
        matching: find.byType(Text),
      );
      expect(lines, findsNWidgets(2));
    });

    testWidgets('compact and change loading shimmer two bars each', (
      tester,
    ) async {
      await pump(
        tester,
        const Column(
          children: [StatTile.compactLoading(), StatTile.changeLoading()],
        ),
      );
      expect(find.byType(SkeletonBar), findsNWidgets(4));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('the change form writes old to new under it', (tester) async {
      await pump(
        tester,
        const StatTile.change(
          label: 'Value A',
          change: '-1.7',
          fromTo: '84.1 → 82.4 [UNIT]',
        ),
      );
      expect(find.text('−1.7'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('84.1 → 82.4 [UNIT]')).style?.color,
        colors(tester).inkMuted,
      );
    });

    testWidgets('error retries without opening the tile', (tester) async {
      var taps = 0;
      var retries = 0;
      await pump(
        tester,
        StatTile.error(
          title: 'Metric A',
          onTap: () => taps++,
          message: "Couldn't load",
          onRetry: () => retries++,
          retryLabel: 'Retry',
        ),
      );
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
      expect(taps, 0);
    });

    testWidgets('loading and empty keep the title row', (tester) async {
      await pump(
        tester,
        Column(
          children: [
            StatTile.loading(title: 'Metric A', onTap: () {}),
            StatTile.empty(
              title: 'Metric B',
              onTap: () {},
              message: 'Nothing yet',
            ),
          ],
        ),
      );
      expect(find.byType(SkeletonBar), findsNWidgets(2));
      expect(find.text('Metric B'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });
  });
}

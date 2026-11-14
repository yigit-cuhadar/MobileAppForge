import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

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

    Widget chart({
      void Function(int)? onSeriesTap,
      VoidCallback? onAdd,
      bool target = false,
    }) => MultiSeriesChart(
      title: 'Series',
      detail: '12 weeks',
      series: [
        ChartSeries(
          label: 'Series A',
          values: const [3, 2, 1],
          format: format,
          look: SeriesLook.accent,
          target: target ? 1.5 : null,
          targetLabel: target ? 'Target' : null,
        ),
        ChartSeries.bars(
          label: 'Series B',
          values: const [10, 20, 30],
          format: format,
        ),
      ],
      dateLabel: (i) => 'Day $i',
      startLabel: 'Aug 25',
      endLabel: 'Nov 10',
      onSeriesTap: onSeriesTap ?? (_) {},
      addLabel: 'Add',
      onAdd: onAdd ?? () {},
      semanticLabel: 'Series over 12 weeks',
    );

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

    testWidgets('a tap shows each series on that day', (tester) async {
      await pump(tester, chart());

      final box = tester.getRect(find.bySemanticsLabel('Series over 12 weeks'));
      await tester.tapAt(Offset(box.right - 4, box.bottom - 4));
      await tester.pump();
      expect(find.text('Day 2'), findsOneWidget);
      expect(find.text('1.0'), findsOneWidget);
      expect(find.text('30.0'), findsOneWidget);
    });

    testWidgets('a target is labelled in its series colour', (tester) async {
      await pump(tester, chart(target: true));
      expect(
        tester.widget<Text>(find.text('Target')).style?.color,
        colors(tester).accent,
      );
    });

    testWidgets('a line with no values yet draws nothing and taps safely', (
      tester,
    ) async {
      await pump(
        tester,
        MultiSeriesChart(
          title: 'Series',
          series: [
            ChartSeries(
              label: 'Series A',
              values: const [],
              format: format,
              look: SeriesLook.accent,
            ),
          ],
          dateLabel: (i) => 'Day $i',
          startLabel: 'Aug 25',
          endLabel: 'Nov 10',
          onSeriesTap: (_) {},
          addLabel: 'Add',
          onAdd: () {},
          semanticLabel: 'Series over 12 weeks',
        ),
      );
      expect(tester.takeException(), isNull);

      final box = tester.getRect(find.bySemanticsLabel('Series over 12 weeks'));
      await tester.tapAt(box.center);
      await tester.pump();
      expect(find.text('Day 0'), findsNothing);
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

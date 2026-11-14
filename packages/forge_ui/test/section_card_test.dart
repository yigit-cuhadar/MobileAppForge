import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Gap.md), child: child),
      ),
    ),
  );

  ForgePalette colors(WidgetTester tester) =>
      ForgeStyle.of(tester.element(find.byType(Scaffold))).colors;

  testWidgets('tapping anywhere on the card opens it', (tester) async {
    var taps = 0;
    await pump(
      tester,
      SectionCard(
        title: 'Section title',
        detail: '[DETAIL]',
        onTap: () => taps++,
        child: const Text('Body'),
      ),
    );

    await tester.tap(find.text('Body'));
    await tester.tap(find.text('[DETAIL]'));
    expect(taps, 2);
  });

  testWidgets('loading shows two skeleton bars', (tester) async {
    await pump(
      tester,
      SectionCard.loading(title: 'Section title', onTap: () {}),
    );

    expect(find.byType(SkeletonBar), findsNWidgets(2));
  });

  testWidgets('Retry retries without opening the card', (tester) async {
    var taps = 0;
    var retries = 0;
    await pump(
      tester,
      SectionCard.error(
        title: 'Section title',
        onTap: () => taps++,
        message: "Couldn't load this section",
        onRetry: () => retries++,
        retryLabel: 'Retry',
      ),
    );

    expect(
      tester.widget<Text>(find.text("Couldn't load this section")).style?.color,
      colors(tester).danger,
    );
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
    expect(taps, 0);
  });

  testWidgets('empty shows its one line', (tester) async {
    await pump(
      tester,
      SectionCard.empty(
        title: 'Section title',
        onTap: () {},
        message: 'Nothing here this week yet',
      ),
    );

    expect(find.text('Nothing here this week yet'), findsOneWidget);
  });

  testWidgets('locked shows the tag and opens the paywall', (tester) async {
    var taps = 0;
    await pump(
      tester,
      SectionCard.locked(
        title: 'Section title',
        onTap: () => taps++,
        tag: const Text('Premium'),
        message: '[PREMIUM FEATURE ONE] with Premium.',
      ),
    );

    await tester.tap(find.text('Premium'));
    expect(taps, 1);
  });

  group('BandBar', () {
    Color fill(WidgetTester tester) {
      final boxes = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(BandBar),
              matching: find.byType(DecoratedBox),
            ),
          )
          .toList();
      // The track first, then the fill.
      return (boxes[1].decoration as BoxDecoration).color!;
    }

    Future<void> band(WidgetTester tester, double value) => pump(
      tester,
      BandBar(
        label: 'Item one',
        valueLabel: '14',
        value: value,
        low: 0.4,
        high: 0.8,
      ),
    );

    testWidgets('within the band the fill is accent', (tester) async {
      await band(tester, 0.56);
      expect(fill(tester), colors(tester).accent);
    });

    testWidgets('above the band the fill is danger', (tester) async {
      await band(tester, 0.88);
      expect(fill(tester), colors(tester).danger);
    });

    testWidgets('the compact form has no ticks', (tester) async {
      await pump(
        tester,
        const BandBar.compact(
          label: 'Item one',
          valueLabel: '14',
          value: 0.56,
          low: 0.4,
          high: 0.8,
        ),
      );

      expect(
        find.descendant(
          of: find.byType(BandBar),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
      expect(fill(tester), colors(tester).accent);
    });

    testWidgets('below the band the fill is a soft accent', (tester) async {
      await band(tester, 0.32);
      final c = colors(tester);
      expect(fill(tester), Color.lerp(c.surface, c.accent, 0.4));
    });
  });
}

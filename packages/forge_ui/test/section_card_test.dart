import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  testWidgets('a long detail ends in an ellipsis at narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(
      tester,
      SectionCard(
        title: 'Section title',
        detail: '[DETAIL] · [DETAIL] · [DETAIL] · [DETAIL]',
        onTap: () {},
        child: const Text('Body'),
      ),
    );

    expect(tester.takeException(), isNull);
    final detail = find.text('[DETAIL] · [DETAIL] · [DETAIL] · [DETAIL]');
    expect(tester.widget<Text>(detail).maxLines, 1);
    expect(tester.widget<Text>(detail).overflow, TextOverflow.ellipsis);
    expect(
      tester.renderObject<RenderParagraph>(detail).didExceedMaxLines,
      isTrue,
    );
  });

  testWidgets('a plain card\'s note is drawn whole after the title, past '
      'half the header', (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const note = '% of weight · reps';
    await pump(
      tester,
      const SectionCard.plain(title: 'Sets', note: note, child: Text('Body')),
    );

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.text(note));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
    expect(text.style?.fontSize, 12);
    expect(text.style?.color, colors(tester).inkMuted);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(note));
    expect(paragraph.didExceedMaxLines, isFalse);
    // One line, wider than half the header, after the title.
    final card = tester.getRect(find.byType(SectionCard));
    final noteRect = tester.getRect(find.text(note));
    expect(noteRect.height, lessThan(20));
    expect(noteRect.width, greaterThan((card.width - 2 * Gap.md) / 2));
    expect(noteRect.left, greaterThan(tester.getRect(find.text('Sets')).right));
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

    testWidgets('the compact form keeps its two ticks', (tester) async {
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
        findsNWidgets(2),
      );
      expect(fill(tester), colors(tester).accent);
    });

    testWidgets('below the band the fill is a soft accent', (tester) async {
      await band(tester, 0.32);
      final c = colors(tester);
      expect(fill(tester), Color.lerp(c.surface, c.accent, 0.4));
    });
  });

  testWidgets('the plain form has no chevron and takes no tap', (tester) async {
    await pump(
      tester,
      const SectionCard.plain(title: 'Section title', child: Text('Body')),
    );

    expect(find.byType(ForgeIcon), findsNothing);
    expect(find.byType(InkWell), findsNothing);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('the plain form\'s action takes taps across a 44px band', (
    tester,
  ) async {
    var edits = 0;
    await pump(
      tester,
      SectionCard.plain(
        title: 'Section title',
        actionLabel: 'Edit',
        onAction: () => edits++,
        child: const Text('Body'),
      ),
    );
    final edit = tester.getRect(find.text('Edit'));

    final label = tester.widget<Text>(find.text('Edit')).style!;
    final colors = ForgeStyle.of(tester.element(find.text('Edit'))).colors;
    expect((label.fontSize, label.fontWeight), (14, FontWeight.w600));
    expect(label.color, colors.accent);
    expect(edit.height, lessThan(ForgeTheme.tapMin));
    await tester.tapAt(edit.center.translate(0, ForgeTheme.tapMin / 2 - 1));
    expect(edits, 1);
    await tester.tap(find.text('Body'));
    expect(edits, 1);
    expect(
      tester.getSemantics(find.text('Edit')),
      matchesSemantics(isButton: true, hasTapAction: true, label: 'Edit'),
    );
  });

  testWidgets('the plain form without content is its header alone', (
    tester,
  ) async {
    var adds = 0;
    await pump(
      tester,
      SectionCard.plain(
        title: 'Section title',
        actionLabel: 'Add',
        onAction: () => adds++,
      ),
    );
    final card = tester.getRect(find.byType(SectionCard));
    final title = tester.getRect(find.text('Section title'));

    expect(card.height, title.height + 2 * Gap.md);
    await tester.tap(find.text('Add'));
    expect(adds, 1);
  });
}

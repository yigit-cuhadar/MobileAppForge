import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/busy_ring.dart';
import 'package:forge_ui/src/widgets/card_frame.dart';

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

  Color? textColor(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style?.color;

  group('Progress', () {
    testWidgets('the bar fills its share of the goal in accent', (
      tester,
    ) async {
      await pump(
        tester,
        const SizedBox(
          width: 200,
          child: Progress.bar(
            value: 31,
            goal: 50,
            figure: '31',
            caption: '19 to go',
          ),
        ),
      );

      final fill = find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(DecoratedBox),
      );
      expect(tester.getSize(fill).width, closeTo(200 * 31 / 50, 0.01));
      expect(
        (tester.widget<DecoratedBox>(fill).decoration as BoxDecoration).color,
        colors(tester).accent,
      );
      expect(textColor(tester, '19 to go'), colors(tester).inkMuted);
    });

    testWidgets('the track is 6px on surface-sunken, thin 4px on line', (
      tester,
    ) async {
      Future<(Size, Color?, double)> track({required bool thin}) async {
        await pump(
          tester,
          SizedBox(width: 200, child: Progress.track(value: 0.64, thin: thin)),
        );
        final box = find.byType(Container).last;
        final fill = find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(DecoratedBox),
        );
        return (
          tester.getSize(box),
          (tester.widget<Container>(box).decoration! as BoxDecoration).color,
          tester.getSize(fill).width,
        );
      }

      final (size, color, fill) = await track(thin: false);
      expect(size, const Size(200, 6));
      expect(color, colors(tester).surfaceSunken);
      expect(fill, closeTo(200 * 0.64, 0.01));

      final (thinSize, thinColor, _) = await track(thin: true);
      expect(thinSize, const Size(200, 4));
      expect(thinColor, colors(tester).line);
    });

    testWidgets('a track with a goal fills toward it, success once reached', (
      tester,
    ) async {
      Future<(double, Color?)> fill(double value) async {
        await pump(
          tester,
          SizedBox(
            width: 200,
            child: Progress.track(value: value, goal: 10000),
          ),
        );
        final fill = find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(DecoratedBox),
        );
        return (
          tester.getSize(fill).width,
          (tester.widget<DecoratedBox>(fill).decoration as BoxDecoration).color,
        );
      }

      final (part, partColor) = await fill(6400);
      expect(part, closeTo(200 * 0.64, 0.01));
      expect(partColor, colors(tester).accent);

      final (full, fullColor) = await fill(10400);
      expect(full, 200);
      expect(fullColor, colors(tester).success);
    });

    testWidgets('reaching the goal turns the caption success', (tester) async {
      await pump(
        tester,
        const Progress.ring(
          value: 50,
          goal: 50,
          figure: '50',
          caption: 'Goal reached',
        ),
      );

      expect(textColor(tester, 'Goal reached'), colors(tester).success);
      expect(tester.getSize(find.byType(Progress)), const Size(136, 136));
    });

    testWidgets('the ring loading is a shimmering circle of its size', (
      tester,
    ) async {
      await pump(tester, const Center(child: Progress.ringLoading()));
      expect(find.byType(SkeletonBar), findsOneWidget);
      expect(tester.getSize(find.byType(Progress)), const Size(136, 136));
    });

    testWidgets('the indeterminate line runs full width, still with less '
        'motion, and is read out', (tester) async {
      await pump(tester, const Progress.indeterminate(label: 'Saving'));
      Rect runner() => tester.getRect(
        find
            .descendant(
              of: find.byType(Progress),
              matching: find.byType(DecoratedBox),
            )
            .last,
      );

      final line = tester.getRect(find.byType(Progress));
      expect(line.height, 3);
      expect(line.width, 800 - 2 * Gap.md);
      expect(find.bySemanticsLabel('Saving'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      final moving = runner();
      await tester.pump(const Duration(milliseconds: 300));
      expect(runner(), isNot(moving));

      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: Progress.indeterminate(label: 'Saving')),
          ),
        ),
      );
      final still = runner();
      await tester.pump(const Duration(milliseconds: 300));
      expect(runner(), still);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('state views', () {
    testWidgets('loading is three skeleton cards, no spinner', (tester) async {
      await pump(tester, const LoadingView());

      expect(find.byType(SkeletonBar), findsNWidgets(9));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(BusyRing), findsNothing);
    });

    testWidgets('error shows the cloud-off icon and offers Retry', (
      tester,
    ) async {
      var retries = 0;
      await pump(
        tester,
        ErrorView(
          retryLabel: 'Retry',
          title: "Couldn't load this",
          message: 'Check your connection and try again.',
          onRetry: () => retries++,
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is ForgeIcon && w.icon == ForgeIcons.cloudOff,
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(ForgeButton, 'Retry'));
      expect(retries, 1);
    });

    testWidgets('the compact form sits tighter', (tester) async {
      Widget view({required bool compact}) => ErrorView(
        retryLabel: 'Retry',
        title: "Couldn't load the chart",
        message: 'Check your connection and try again.',
        onRetry: () {},
        compact: compact,
      );
      await pump(tester, view(compact: false));
      final full = tester.getSize(find.byType(Column).first).height;
      await pump(tester, view(compact: true));
      final compact = tester.getSize(find.byType(Column).first).height;

      // 8px instead of 16px twice.
      expect(full - compact, 2 * (Gap.md - Gap.sm));
    });

    testWidgets('empty shows its actions', (tester) async {
      await pump(
        tester,
        EmptyView(
          title: 'Nothing here yet',
          message: 'Items you add show up here.',
          actions: [
            FilledButton(onPressed: () {}, child: const Text('Add item')),
            ElevatedButton(onPressed: () {}, child: const Text('Browse')),
          ],
        ),
      );

      expect(find.text('Add item'), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);
    });

    testWidgets('empty without a title shows only its line and action', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        EmptyView(
          message: 'Add items to get started.',
          actions: [ForgeButton(label: 'Add item', onPressed: () => taps++)],
        ),
      );

      expect(
        find.descendant(
          of: find.byType(EmptyView),
          matching: find.byType(Text),
        ),
        findsNWidgets(2),
      );
      expect(find.text('Add items to get started.'), findsOneWidget);
      await tester.tap(find.text('Add item'));
      expect(taps, 1);
    });

    testWidgets('working shows the ring for work the user started', (
      tester,
    ) async {
      await pump(
        tester,
        const WorkingView(
          title: 'Preparing your item',
          message: 'This takes a few seconds.',
        ),
      );

      expect(find.byType(BusyRing), findsOneWidget);
    });

    testWidgets('the shimmer stops when animations are off', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: SkeletonBar(width: 40, height: 10)),
          ),
        ),
      );

      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('the card form pads 24/16 in place of a page', (tester) async {
      await pump(
        tester,
        const Column(
          children: [
            EmptyView(
              title: 'Nothing here yet',
              message: 'Items you add show up here.',
              card: true,
            ),
          ],
        ),
      );

      final card = tester.getRect(find.byType(CardFrame));
      final icon = tester.getRect(
        find.descendant(
          of: find.byType(EmptyView),
          matching: find.byType(ForgeIcon),
        ),
      );
      final line = tester.getRect(find.text('Items you add show up here.'));
      // The 44px circle around the 22px icon starts 24 below the card.
      expect(icon.top - card.top, 24 + 11);
      expect(card.bottom - line.bottom, 24);
      expect(card.width, tester.getSize(find.byType(Column).first).width);
    });

    testWidgets('the compact card pads 16 for a section', (tester) async {
      var retries = 0;
      await pump(
        tester,
        Column(
          children: [
            ErrorView(
              title: "Couldn't load this",
              message: 'Check your connection and try again.',
              retryLabel: 'Retry',
              onRetry: () => retries++,
              compact: true,
              card: true,
            ),
          ],
        ),
      );

      final card = tester.getRect(find.byType(CardFrame));
      final retry = tester.getRect(find.byType(ForgeButton));
      // The 40px button in its 44px tap band.
      expect(card.bottom - retry.bottom, 16);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('the card forms lay out at ${scale}x text', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ForgeTheme.light(),
            builder: (context, page) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: page!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 390,
                  child: Column(
                    children: [
                      EmptyView(
                        title: 'No items match',
                        message: 'Try another search or fewer filters.',
                        actions: [
                          ForgeButton(label: 'Add item', onPressed: () {}),
                        ],
                        card: true,
                      ),
                      ErrorView(
                        title: "Couldn't load this",
                        message: 'Check your connection and try again.',
                        retryLabel: 'Retry',
                        onRetry: () {},
                        compact: true,
                        card: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('NoticeBanner', () {
    testWidgets('its one action is full width', (tester) async {
      var taps = 0;
      await pump(
        tester,
        NoticeBanner(
          icon: ForgeIcons.notificationsOff,
          title: 'Notifications are off',
          message: "Reminders can't reach you until you turn them on.",
          action: ElevatedButton(
            onPressed: () => taps++,
            child: const Text('Open settings'),
          ),
        ),
      );

      await tester.tap(find.text('Open settings'));
      expect(taps, 1);
      final card = tester.getSize(find.byType(NoticeBanner)).width;
      expect(
        tester.getSize(find.byType(ElevatedButton)).width,
        card - 2 * Gap.md,
      );
    });

    testWidgets('without an action the card ends after the message', (
      tester,
    ) async {
      await pump(
        tester,
        const NoticeBanner(
          icon: ForgeIcons.cloudOff,
          title: 'Item title',
          message: 'One line of message.',
        ),
      );

      expect(find.byType(ForgeButton), findsNothing);
      expect(
        tester.getBottomLeft(find.byType(NoticeBanner)).dy -
            tester.getBottomLeft(find.text('One line of message.')).dy,
        Gap.md,
      );
    });

    testWidgets('the line form is its message alone, in ink, beside the '
        'icon', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 360,
          child: NoticeBanner.line(
            icon: ForgeIcons.warning,
            message: 'One line.',
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('One line.'));
      final context = tester.element(find.byType(NoticeBanner));
      expect(text.style?.color, ForgeStyle.of(context).colors.ink);
      expect(find.byType(ForgeButton), findsNothing);
      // One line, centred on the 36px icon circle, 12px inside the card.
      expect(tester.getSize(find.byType(NoticeBanner)).height, 36 + 2 * 12);
      expect(
        tester.getCenter(find.text('One line.')).dy,
        tester.getCenter(find.byType(NoticeBanner)).dy,
      );
    });
  });

  group('TipBanner', () {
    testWidgets('Got it closes it', (tester) async {
      var dismissed = 0;
      await pump(
        tester,
        TipBanner(
          message: 'Optional: a short hint.',
          dismissLabel: 'Got it',
          onDismiss: () => dismissed++,
        ),
      );

      await tester.tap(find.text('Got it'));
      expect(dismissed, 1);
    });

    testWidgets('swiping the reminder away closes it', (tester) async {
      var dismissed = 0;
      await pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => dismissed > 0
              ? const SizedBox()
              : TipBanner.action(
                  icon: ForgeIcons.straighten,
                  title: 'Reminder title',
                  detail: 'One line of detail',
                  action: FilledButton(
                    onPressed: () {},
                    child: const Text('Start'),
                  ),
                  onDismiss: () => setState(() => dismissed++),
                ),
        ),
      );

      await tester.fling(
        find.text('Reminder title'),
        const Offset(-400, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });
  });
}

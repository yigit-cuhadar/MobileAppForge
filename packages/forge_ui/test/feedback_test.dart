import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/busy_ring.dart';

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
  });

  group('state views', () {
    testWidgets('loading is three skeleton cards, no spinner', (tester) async {
      await pump(tester, const LoadingView());

      expect(find.byType(SkeletonBar), findsNWidgets(9));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(BusyRing), findsNothing);
    });

    testWidgets('error offers Retry', (tester) async {
      var retries = 0;
      await pump(
        tester,
        ErrorView(
          title: "Couldn't load this",
          message: 'Check your connection and try again.',
          onRetry: () => retries++,
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
      expect(retries, 1);
    });

    testWidgets('the compact form sits tighter', (tester) async {
      Widget view({required bool compact}) => ErrorView(
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

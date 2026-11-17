import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/busy_ring.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(theme: ForgeTheme.light(), home: child),
    );
    // The footer is measured after the first frame.
    await tester.pump();
  }

  const yearlyTerms =
      'Then [YEARLY PRICE] a year. Cancel anytime in your store settings.';
  const allPlans = [
    SubscriptionPlan(
      name: 'Yearly',
      price: '[YEARLY PRICE] / year',
      terms: yearlyTerms,
      detail: '7 days free',
      tag: 'Best value',
    ),
    SubscriptionPlan(
      name: 'Monthly',
      price: '[MONTHLY PRICE] / month',
      terms: 'Renews at [MONTHLY PRICE] a month.',
      detail: 'billed monthly',
    ),
  ];

  SubscriptionPlans paywall(
    List<String> taps, {
    SubscriptionLayout layout = SubscriptionLayout.rows,
    List<SubscriptionPlan> plans = allPlans,
    bool loading = false,
    String? purchasing,
    String? restoring,
    SubscriptionMessage? message,
  }) => SubscriptionPlans(
    onClose: () => taps.add('close'),
    title: '[APP NAME] Premium',
    benefits: const ['[PREMIUM FEATURE ONE]'],
    layout: layout,
    plans: plans,
    selected: 0,
    onSelected: (i) => taps.add('plan $i'),
    purchaseLabel: 'Start 7-day free trial',
    onPurchase: () => taps.add('purchase'),
    restoreLabel: 'Restore purchases',
    onRestore: () => taps.add('restore'),
    termsLabel: 'Terms of Use',
    onTerms: () => taps.add('terms'),
    privacyLabel: 'Privacy Policy',
    onPrivacy: () => taps.add('privacy'),
    alternativeLabel: layout == SubscriptionLayout.single
        ? 'See monthly plan'
        : null,
    onAlternative: layout == SubscriptionLayout.single
        ? () => taps.add('alternative')
        : null,
    loading: loading,
    purchasing: purchasing,
    restoring: restoring,
    message: message,
  );

  Finder inScroll(Finder finder) =>
      find.ancestor(of: finder, matching: find.byType(Scrollable));

  ForgeButton button(WidgetTester tester, String label) =>
      tester.widget<ForgeButton>(find.widgetWithText(ForgeButton, label));

  testWidgets('rows pick a plan, purchase, restore, open links and close', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, paywall(taps));

    expect(find.text('Best value'), findsOneWidget);
    expect(find.text(yearlyTerms), findsOneWidget);
    await tester.tap(find.text('Monthly'));
    await tester.tap(find.text('Start 7-day free trial'));
    await tester.tap(find.text('Restore purchases'));
    await tester.tap(find.text('Terms of Use'));
    await tester.tap(find.text('Privacy Policy'));
    await tester.tap(find.bySemanticsLabel('Close'));
    expect(taps, [
      'plan 1',
      'purchase',
      'restore',
      'terms',
      'privacy',
      'close',
    ]);
  });

  testWidgets('the selected tile reads as selected', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, paywall([], layout: SubscriptionLayout.tiles));

    expect(find.text('7 days free'), findsOneWidget);
    expect(find.text('Best value'), findsNothing);
    expect(find.byType(RadioMark), findsNothing);
    expect(
      tester.getSemantics(find.text('Yearly')),
      matchesSemantics(
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
        label: 'Yearly\n[YEARLY PRICE] / year\n7 days free',
      ),
    );
    semantics.dispose();
  });

  testWidgets('single shows the selected plan and its link to the other', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, paywall(taps, layout: SubscriptionLayout.single));

    expect(find.text('Monthly'), findsNothing);
    expect(find.text('7 days free'), findsOneWidget);
    await tester.tap(find.text('See monthly plan'));
    expect(taps, ['alternative']);
  });

  testWidgets('loading is a skeleton with Restore and the links', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, paywall(taps, plans: const [], loading: true));

    expect(find.byType(SkeletonBar), findsWidgets);
    expect(find.text('[APP NAME] Premium'), findsNothing);
    expect(find.text('Start 7-day free trial'), findsNothing);
    await tester.tap(find.text('Restore purchases'));
    await tester.tap(find.text('Terms of Use'));
    expect(taps, ['restore', 'terms']);
  });

  testWidgets('purchasing spins the main button and holds plans and Restore', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(
      tester,
      paywall(taps, purchasing: 'Confirming with the App Store'),
    );

    expect(button(tester, 'Confirming with the App Store').loading, isTrue);
    await tester.tap(find.text('Monthly'));
    await tester.tap(find.text('Restore purchases'), warnIfMissed: false);
    await tester.tap(find.text('Confirming with the App Store'));
    expect(taps, isEmpty);
  });

  testWidgets('restoring turns the main button off and spins Restore', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, paywall(taps, restoring: 'Restoring purchases'));

    expect(button(tester, 'Start 7-day free trial').onPressed, isNull);
    expect(find.byType(BusyRing), findsOneWidget);
    await tester.tap(find.text('Restoring purchases'));
    await tester.tap(find.text('Monthly'));
    expect(taps, isEmpty);
  });

  testWidgets('failed prices: Retry, a disabled main button and no terms', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(
      tester,
      paywall(
        taps,
        plans: const [],
        message: SubscriptionMessage.failed(
          title: "Couldn't load plans",
          message: 'Check your connection.',
          actionLabel: 'Retry',
          onAction: () => taps.add('retry'),
        ),
      ),
    );

    expect(find.text(yearlyTerms), findsNothing);
    expect(button(tester, 'Retry').variant, ForgeButtonVariant.outline);
    expect(button(tester, 'Start 7-day free trial').onPressed, isNull);
    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Restore purchases'));
    expect(taps, ['retry', 'restore']);
  });

  testWidgets('store unavailable: one line, Retry, no plans or terms', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(
      tester,
      paywall(
        taps,
        message: SubscriptionMessage.unavailable(
          message: 'Purchases are not available yet. Try again later.',
          actionLabel: 'Retry',
          onAction: () => taps.add('retry'),
        ),
      ),
    );

    expect(find.text('Yearly'), findsNothing);
    expect(find.text(yearlyTerms), findsNothing);
    expect(button(tester, 'Start 7-day free trial').onPressed, isNull);
    await tester.tap(find.text('Retry'));
    expect(taps, ['retry']);
  });

  testWidgets('waiting for approval keeps the terms; Got it goes on', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(
      tester,
      paywall(
        taps,
        message: SubscriptionMessage.pending(
          title: 'Waiting for approval',
          message: 'Premium unlocks as soon as it is approved.',
          actionLabel: 'Got it',
          onAction: () => taps.add('ok'),
        ),
      ),
    );

    expect(find.text('Yearly'), findsNothing);
    expect(find.text(yearlyTerms), findsOneWidget);
    expect(button(tester, 'Got it').variant, ForgeButtonVariant.secondary);
    await tester.tap(find.text('Start 7-day free trial'));
    await tester.tap(find.text('Got it'));
    expect(taps, ['ok']);
  });

  testWidgets('the footer is pinned while it takes at most half the page', (
    tester,
  ) async {
    await pump(tester, paywall([]));

    expect(inScroll(find.text('Restore purchases')), findsNothing);
    expect(inScroll(find.text('Yearly')), findsWidgets);
  });

  testWidgets('a footer taller than half the page scrolls with it', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 420)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, paywall([]));

    expect(inScroll(find.text('Restore purchases')), findsWidgets);
    await tester.scrollUntilVisible(find.text('Privacy Policy'), 100);
    expect(tester.takeException(), isNull);
  });
}

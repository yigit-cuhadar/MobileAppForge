import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_ui/src/widgets/busy_ring.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  const plans = [
    SubscriptionPlan(
      name: 'Yearly',
      price: '[YEARLY PRICE] / year',
      detail: '7-day free trial, then billed yearly',
      tag: 'Best value',
    ),
    SubscriptionPlan(
      name: 'Monthly',
      price: '[MONTHLY PRICE] / month',
      detail: 'Cancel any time',
    ),
  ];

  SubscriptionPlans paywall(
    List<String> taps, {
    SubscriptionLayout layout = SubscriptionLayout.rows,
    bool loading = false,
    String? purchasing,
    String? restoring,
    SubscriptionMessage? message,
  }) => SubscriptionPlans(
    title: '[APP NAME] Premium',
    benefits: const ['[PREMIUM FEATURE ONE]'],
    layout: layout,
    plans: loading || message != null ? const [] : plans,
    selected: 0,
    onSelected: (i) => taps.add('plan $i'),
    purchaseLabel: 'Start 7-day free trial',
    onPurchase: () => taps.add('purchase'),
    restoreLabel: 'Restore purchases',
    onRestore: () => taps.add('restore'),
    alternativeLabel: layout == SubscriptionLayout.single
        ? 'Or monthly, [MONTHLY PRICE] / month'
        : null,
    onAlternative: layout == SubscriptionLayout.single
        ? () => taps.add('alternative')
        : null,
    loading: loading,
    purchasing: purchasing,
    restoring: restoring,
    message: message,
  );

  testWidgets('rows pick a plan, purchase and restore', (tester) async {
    final taps = <String>[];
    await pump(tester, paywall(taps));

    expect(find.text('Best value'), findsOneWidget);
    await tester.tap(find.text('Monthly'));
    await tester.tap(find.text('Start 7-day free trial'));
    await tester.tap(find.text('Restore purchases'));
    expect(taps, ['plan 1', 'purchase', 'restore']);
  });

  testWidgets('the selected plan reads as selected', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, paywall([], layout: SubscriptionLayout.tiles));

    expect(
      tester.getSemantics(find.text('Yearly')),
      matchesSemantics(
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
        label:
            'Yearly\nBest value\n[YEARLY PRICE] / year\n'
            '7-day free trial, then billed yearly',
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
    await tester.tap(find.text('Or monthly, [MONTHLY PRICE] / month'));
    expect(taps, ['alternative']);
  });

  testWidgets('loading prices is a skeleton; Restore stays', (tester) async {
    final taps = <String>[];
    await pump(tester, paywall(taps, loading: true));

    expect(find.byType(SkeletonBar), findsWidgets);
    expect(find.text('Start 7-day free trial'), findsNothing);
    await tester.tap(find.text('Restore purchases'));
    expect(taps, ['restore']);
  });

  testWidgets('purchasing shows the spinner and holds the other actions', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, paywall(taps, purchasing: 'Confirming with the store'));

    final main = tester.widget<ForgeButton>(
      find.widgetWithText(ForgeButton, 'Confirming with the store'),
    );
    expect(main.loading, isTrue);
    await tester.tap(find.text('Monthly'));
    await tester.tap(find.text('Restore purchases'));
    expect(taps, isEmpty);
  });

  testWidgets('restoring turns the main button off and spins Restore', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(tester, paywall(taps, restoring: 'Restoring purchases…'));

    final main = tester.widget<ForgeButton>(
      find.widgetWithText(ForgeButton, 'Start 7-day free trial'),
    );
    expect(main.onPressed, isNull);
    expect(find.byType(BusyRing), findsOneWidget);
    await tester.tap(find.text('Restoring purchases…'));
    expect(taps, isEmpty);
  });

  testWidgets('a failed load offers Retry and keeps Restore', (tester) async {
    final taps = <String>[];
    await pump(
      tester,
      paywall(
        taps,
        message: SubscriptionMessage.failed(
          title: "Couldn't load plans",
          message: 'Check your connection.',
          actionLabel: 'Retry',
          onAction: () => taps.add('retry'),
        ),
      ),
    );

    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Restore purchases'));
    expect(taps, ['retry', 'restore']);
  });

  testWidgets('pending approval lets the user go on, without Restore', (
    tester,
  ) async {
    final taps = <String>[];
    await pump(
      tester,
      paywall(
        taps,
        message: SubscriptionMessage.pending(
          title: 'Waiting for approval',
          message: 'Premium turns on as soon as it is approved.',
          actionLabel: 'Got it',
          onAction: () => taps.add('ok'),
        ),
      ),
    );

    expect(find.text('Restore purchases'), findsNothing);
    await tester.tap(find.text('Got it'));
    expect(taps, ['ok']);
  });
}

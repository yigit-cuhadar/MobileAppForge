import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _yearlyTerms =
    'Then [YEARLY PRICE] a year. Cancel anytime in your store settings.';
const _monthlyTerms =
    'Renews at [MONTHLY PRICE] a month. Cancel anytime in your store '
    'settings.';

/// The plans as the app words them for each layout.
List<SubscriptionPlan> _plans(SubscriptionLayout layout) => switch (layout) {
  SubscriptionLayout.rows => const [
    SubscriptionPlan(
      name: 'Yearly',
      price: '[YEARLY PRICE] / year',
      terms: _yearlyTerms,
      tag: 'Best value',
    ),
    SubscriptionPlan(
      name: 'Monthly',
      price: '[MONTHLY PRICE] / month',
      terms: _monthlyTerms,
    ),
  ],
  SubscriptionLayout.tiles => const [
    SubscriptionPlan(
      name: 'Yearly',
      price: '[YEARLY PRICE]',
      terms: _yearlyTerms,
      detail: '7 days free',
    ),
    SubscriptionPlan(
      name: 'Monthly',
      price: '[MONTHLY PRICE]',
      terms: _monthlyTerms,
      detail: 'billed monthly',
    ),
  ],
  SubscriptionLayout.single => const [
    SubscriptionPlan(
      name: 'Yearly · 7 days free',
      price: '[YEARLY PRICE] / year',
      terms: _yearlyTerms,
      detail: 'That is [MONTHLY EQUIVALENT] a month.',
    ),
    SubscriptionPlan(
      name: 'Monthly',
      price: '[MONTHLY PRICE] / month',
      terms: _monthlyTerms,
      detail: 'Billed monthly.',
    ),
  ],
};

SubscriptionPlans _paywall(
  BuildContext context, {
  required SubscriptionLayout layout,
  int selected = 0,
  String purchaseLabel = 'Start 7-day free trial',
  bool noPlans = false,
  bool loading = false,
  String? purchasing,
  String? restoring,
  SubscriptionMessage? message,
  bool closable = true,
}) {
  final single = layout == SubscriptionLayout.single;
  return SubscriptionPlans(
    onClose: closable ? () {} : null,
    title: '[APP NAME] Premium',
    benefits: const [
      '[PREMIUM FEATURE ONE]',
      '[PREMIUM FEATURE TWO]',
      '[PREMIUM FEATURE THREE]',
      '[PREMIUM FEATURE FOUR]',
    ],
    layout: layout,
    plans: loading || noPlans ? const [] : _plans(layout),
    selected: selected,
    onSelected: (_) {},
    purchaseLabel: purchaseLabel,
    onPurchase: () {},
    restoreLabel: 'Restore purchases',
    onRestore: () {},
    termsLabel: 'Terms of Use',
    onTerms: () {},
    privacyLabel: 'Privacy Policy',
    onPrivacy: () {},
    alternativeLabel: single ? 'See monthly plan' : null,
    onAlternative: single ? () {} : null,
    loading: loading,
    purchasing: purchasing,
    restoring: restoring,
    message: message,
  );
}

SubscriptionLayout _layout(BuildContext context) =>
    context.knobs.object.segmented(
      label: 'Layout',
      options: SubscriptionLayout.values,
      labelBuilder: (layout) => layout.name,
    );

@widgetbook.UseCase(name: 'A · rows', type: SubscriptionPlans)
Widget rowsPaywall(BuildContext context) =>
    _paywall(context, layout: SubscriptionLayout.rows);

@widgetbook.UseCase(name: 'B · tiles', type: SubscriptionPlans)
Widget tilesPaywall(BuildContext context) =>
    _paywall(context, layout: SubscriptionLayout.tiles);

@widgetbook.UseCase(name: 'C · single plan', type: SubscriptionPlans)
Widget singlePaywall(BuildContext context) =>
    _paywall(context, layout: SubscriptionLayout.single);

/// A paywall the store setup marks as not dismissible: no close button.
@widgetbook.UseCase(name: 'Not dismissible', type: SubscriptionPlans)
Widget hardPaywall(BuildContext context) =>
    _paywall(context, layout: _layout(context), closable: false);

/// At 3x text the footer outgrows half the page and scrolls with it.
@widgetbook.UseCase(name: 'Large text', type: SubscriptionPlans)
Widget largeTextPaywall(BuildContext context) =>
    MediaQuery.withClampedTextScaling(
      minScaleFactor: 3,
      maxScaleFactor: 3,
      child: _paywall(context, layout: _layout(context)),
    );

/// A plan without a trial chosen: its own button label and terms.
@widgetbook.UseCase(name: 'Plan without a trial', type: SubscriptionPlans)
Widget noTrialPaywall(BuildContext context) => _paywall(
  context,
  layout: SubscriptionLayout.rows,
  selected: 1,
  purchaseLabel: 'Subscribe',
);

@widgetbook.UseCase(name: 'Loading', type: SubscriptionPlans)
Widget loadingPaywall(BuildContext context) =>
    _paywall(context, layout: _layout(context), loading: true);

@widgetbook.UseCase(name: 'Purchasing', type: SubscriptionPlans)
Widget purchasingPaywall(BuildContext context) => _paywall(
  context,
  layout: _layout(context),
  purchasing: 'Confirming with the store',
);

@widgetbook.UseCase(name: 'Restoring', type: SubscriptionPlans)
Widget restoringPaywall(BuildContext context) => _paywall(
  context,
  layout: _layout(context),
  restoring: 'Restoring purchases',
);

@widgetbook.UseCase(name: "Couldn't load plans", type: SubscriptionPlans)
Widget failedPaywall(BuildContext context) => _paywall(
  context,
  layout: SubscriptionLayout.rows,
  noPlans: true,
  purchaseLabel: 'Subscribe',
  message: SubscriptionMessage.failed(
    title: "Couldn't load plans",
    message: 'Check your connection. Everything free keeps working.',
    actionLabel: 'Retry',
    onAction: () {},
  ),
);

@widgetbook.UseCase(name: 'Store unavailable', type: SubscriptionPlans)
Widget unavailablePaywall(BuildContext context) => _paywall(
  context,
  layout: SubscriptionLayout.rows,
  message: SubscriptionMessage.unavailable(
    message: 'Purchases are not available yet. Try again later.',
    actionLabel: 'Retry',
    onAction: () {},
  ),
);

@widgetbook.UseCase(name: 'Waiting for approval', type: SubscriptionPlans)
Widget pendingPaywall(BuildContext context) => _paywall(
  context,
  layout: SubscriptionLayout.rows,
  message: SubscriptionMessage.pending(
    title: 'Waiting for approval',
    message:
        "Your purchase is waiting for approval. Premium unlocks as soon as "
        "it's approved.",
    actionLabel: 'Got it',
    onAction: () {},
  ),
);

/// The app's snackbar after Restore found nothing; the plans stay.
@widgetbook.UseCase(name: 'Nothing to restore', type: SubscriptionPlans)
Widget nothingToRestorePaywall(BuildContext context) => Stack(
  children: [
    _paywall(context, layout: _layout(context)),
    const PositionedDirectional(
      start: Gap.md,
      end: Gap.md,
      bottom: Gap.md,
      child: ForgeSnackbar(message: 'Nothing to restore.'),
    ),
  ],
);

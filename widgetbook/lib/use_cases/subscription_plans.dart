import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(Widget child) =>
    ListView(padding: const EdgeInsets.all(Gap.md), children: [child]);

/// The plans as the app words them for each layout.
List<SubscriptionPlan> _plans(SubscriptionLayout layout) =>
    layout == SubscriptionLayout.tiles
    ? const [
        SubscriptionPlan(
          name: 'Yearly',
          price: '[YEARLY PRICE]',
          detail: 'per year, 7-day free trial',
          tag: 'Best value',
        ),
        SubscriptionPlan(
          name: 'Monthly',
          price: '[MONTHLY PRICE]',
          detail: 'per month, cancel any time',
        ),
      ]
    : const [
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

SubscriptionPlans _paywall(
  BuildContext context, {
  required SubscriptionLayout layout,
  bool loading = false,
  String? purchasing,
  String? restoring,
  SubscriptionMessage? message,
}) {
  final single = layout == SubscriptionLayout.single;
  return SubscriptionPlans(
    title: '[APP NAME] Premium',
    benefits: const [
      '[PREMIUM FEATURE ONE]',
      '[PREMIUM FEATURE TWO]',
      '[PREMIUM FEATURE THREE]',
    ],
    layout: layout,
    plans: loading || message != null ? const [] : _plans(layout),
    selected: context.knobs.int.slider(
      label: 'Selected plan',
      initialValue: 0,
      max: 1,
    ),
    onSelected: (_) {},
    purchaseLabel: 'Start 7-day free trial',
    onPurchase: () {},
    restoreLabel: 'Restore purchases',
    onRestore: () {},
    alternativeLabel: single ? 'Or monthly, [MONTHLY PRICE] / month' : null,
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
    _page(_paywall(context, layout: SubscriptionLayout.rows));

@widgetbook.UseCase(name: 'B · tiles', type: SubscriptionPlans)
Widget tilesPaywall(BuildContext context) =>
    _page(_paywall(context, layout: SubscriptionLayout.tiles));

@widgetbook.UseCase(name: 'C · single plan', type: SubscriptionPlans)
Widget singlePaywall(BuildContext context) =>
    _page(_paywall(context, layout: SubscriptionLayout.single));

@widgetbook.UseCase(name: 'Loading prices', type: SubscriptionPlans)
Widget loadingPaywall(BuildContext context) =>
    _page(_paywall(context, layout: _layout(context), loading: true));

@widgetbook.UseCase(name: 'Purchasing', type: SubscriptionPlans)
Widget purchasingPaywall(BuildContext context) => _page(
  _paywall(
    context,
    layout: _layout(context),
    purchasing: 'Confirming with the store',
  ),
);

@widgetbook.UseCase(name: "Couldn't load plans", type: SubscriptionPlans)
Widget failedPaywall(BuildContext context) => _page(
  _paywall(
    context,
    layout: SubscriptionLayout.rows,
    message: SubscriptionMessage.failed(
      title: "Couldn't load plans",
      message: 'Check your connection. Everything free keeps working.',
      actionLabel: 'Retry',
      onAction: () {},
    ),
  ),
);

@widgetbook.UseCase(name: 'Waiting for approval', type: SubscriptionPlans)
Widget pendingPaywall(BuildContext context) => _page(
  _paywall(
    context,
    layout: SubscriptionLayout.rows,
    message: SubscriptionMessage.pending(
      title: 'Waiting for approval',
      message:
          "Your purchase needs approval. Premium turns on as soon as it's "
          'approved; everything free keeps working meanwhile.',
      actionLabel: 'Got it',
      onAction: () {},
    ),
  ),
);

@widgetbook.UseCase(name: 'Approved later', type: SubscriptionPlans)
Widget approvedPaywall(BuildContext context) => _page(
  _paywall(
    context,
    layout: SubscriptionLayout.rows,
    message: SubscriptionMessage.approved(
      title: 'Premium is on',
      message: 'Your purchase was approved.',
      actionLabel: 'Continue',
      onAction: () {},
    ),
  ),
);

@widgetbook.UseCase(name: 'Restoring', type: SubscriptionPlans)
Widget restoringPaywall(BuildContext context) => _page(
  _paywall(
    context,
    layout: _layout(context),
    restoring: 'Restoring purchases…',
  ),
);

/// The app's snackbar after Restore: on success the paywall has closed.
@widgetbook.UseCase(name: 'Restored', type: SubscriptionPlans)
Widget restoredPaywall(BuildContext context) =>
    _page(const ForgeSnackbar(message: 'Premium restored.'));

/// The app's snackbar after Restore found nothing; the plans stay.
@widgetbook.UseCase(name: 'Nothing to restore', type: SubscriptionPlans)
Widget nothingToRestorePaywall(BuildContext context) => Scaffold(
  body: _page(_paywall(context, layout: _layout(context))),
  bottomNavigationBar: const Padding(
    padding: EdgeInsets.all(Gap.md),
    child: ForgeSnackbar(message: 'Nothing to restore.'),
  ),
);

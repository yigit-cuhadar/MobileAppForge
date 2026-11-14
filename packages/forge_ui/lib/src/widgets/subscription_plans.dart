import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'benefit_list.dart';
import 'busy_ring.dart';
import 'card_frame.dart';
import 'forge_button.dart';
import 'forge_tag.dart';
import 'pressable.dart';
import 'radio_mark.dart';
import 'skeleton.dart';

/// How [SubscriptionPlans] lays out its plans; one is picked per user for
/// an A/B/C test.
enum SubscriptionLayout {
  /// Rows one under another, each with a radio.
  rows,

  /// Tiles side by side.
  tiles,

  /// The selected plan alone, with a link to the other one.
  single,
}

/// One plan as the app words it for the layout in use.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.name,
    required this.price,
    required this.detail,
    this.tag,
  });

  final String name;
  final String price;
  final String detail;

  /// A short record tag after the name ("Best value").
  final String? tag;
}

enum _MessageKind { failed, pending, approved }

/// A message in the place of the plans, with one button.
class SubscriptionMessage {
  /// The prices could not be loaded; [onAction] retries.
  const SubscriptionMessage.failed({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  }) : _kind = _MessageKind.failed;

  /// A purchase waits for approval (Ask to Buy); [onAction] lets the user
  /// go on.
  const SubscriptionMessage.pending({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  }) : _kind = _MessageKind.pending;

  /// A purchase that waited was approved: Premium is on.
  const SubscriptionMessage.approved({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  }) : _kind = _MessageKind.approved;

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final _MessageKind _kind;
}

/// The paywall: the [title] and a checked [BenefitList] of [benefits], then
/// a card with the [plans] in the given [layout], the main purchase button
/// and Restore purchases. While prices are [loading] the plans and the
/// main button are a shimmer skeleton. [purchasing] and [restoring] name
/// the work running, shown with a spinner; a [message] replaces the plans.
/// The app shows Restore's result as a snackbar and closes the paywall on
/// success.
class SubscriptionPlans extends StatelessWidget {
  const SubscriptionPlans({
    super.key,
    required this.title,
    required this.benefits,
    required this.layout,
    required this.plans,
    required this.selected,
    required this.onSelected,
    required this.purchaseLabel,
    required this.onPurchase,
    required this.restoreLabel,
    required this.onRestore,
    this.alternativeLabel,
    this.onAlternative,
    this.loading = false,
    this.purchasing,
    this.restoring,
    this.message,
  }) : assert(
         (alternativeLabel == null) == (onAlternative == null),
         'Give the single layout\'s link a label and an action together.',
       );

  final String title;
  final List<String> benefits;
  final SubscriptionLayout layout;

  /// Empty while [loading] or showing a [message].
  final List<SubscriptionPlan> plans;

  /// The index of the chosen plan; the single layout shows only this one.
  final int selected;
  final ValueChanged<int> onSelected;
  final String purchaseLabel;
  final VoidCallback onPurchase;
  final String restoreLabel;
  final VoidCallback onRestore;

  /// The single layout's link to the other plan ("Or monthly, …").
  final String? alternativeLabel;
  final VoidCallback? onAlternative;
  final bool loading;

  /// While a purchase runs: the main button's label ("Confirming with the
  /// store"), next to a spinner.
  final String? purchasing;

  /// While purchases are restored: Restore's label, next to a spinner; the
  /// main button is off.
  final String? restoring;
  final SubscriptionMessage? message;

  // Plan boxes drawn while prices load, before the app knows its plans.
  static const _skeletonPlans = 2;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: text.headlineMedium!.copyWith(
            fontSize: 24,
            height: 28 / 24,
            letterSpacing: -0.48,
          ),
        ),
        const SizedBox(height: Gap.sm),
        BenefitList.checked(benefits),
        const SizedBox(height: Gap.md),
        CardFrame(
          child: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Gap.md,
              children: _body(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _body() {
    final busy = purchasing != null || restoring != null;
    final restore = _RestoreButton(
      label: restoring ?? restoreLabel,
      busy: restoring != null,
      onTap: busy ? null : onRestore,
    );
    if (message case final message?) {
      return [
        _Message(message),
        if (message._kind == _MessageKind.failed) restore,
      ];
    }
    if (loading) {
      return [
        _plans(
          layout == SubscriptionLayout.single ? 1 : _skeletonPlans,
          (_) => _PlanSkeleton(radio: layout.radio),
        ),
        const SkeletonBar(widthFactor: 1, height: ForgeTheme.buttonHeightLg),
        restore,
      ];
    }
    final alternativeLabel = this.alternativeLabel;
    return [
      _plans(
        layout == SubscriptionLayout.single ? 1 : plans.length,
        (i) => _PlanBox(
          plan: layout == SubscriptionLayout.single
              ? plans[selected]
              : plans[i],
          look: layout == SubscriptionLayout.single
              ? _PlanLook.single
              : i == selected
              ? _PlanLook.chosen
              : _PlanLook.unchosen,
          radio: layout.radio,
          onTap: busy || layout == SubscriptionLayout.single
              ? null
              : () => onSelected(i),
        ),
      ),
      ForgeButton(
        label: purchasing ?? purchaseLabel,
        onPressed: restoring == null ? onPurchase : null,
        loading: purchasing != null,
        size: ForgeButtonSize.large,
      ),
      if (layout == SubscriptionLayout.single && alternativeLabel != null)
        Center(
          child: ForgeButton(
            label: alternativeLabel,
            onPressed: busy ? null : onAlternative,
            variant: ForgeButtonVariant.text,
          ),
        ),
      restore,
    ];
  }

  Widget _plans(int count, Widget Function(int index) box) =>
      layout == SubscriptionLayout.tiles
      ? IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Gap.sm,
            children: [for (var i = 0; i < count; i++) Expanded(child: box(i))],
          ),
        )
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.sm,
          children: [for (var i = 0; i < count; i++) box(i)],
        );
}

extension on SubscriptionLayout {
  bool get radio => this == SubscriptionLayout.rows;
}

enum _PlanLook { chosen, unchosen, single }

class _PlanBox extends StatelessWidget {
  const _PlanBox({
    required this.plan,
    required this.look,
    required this.radio,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final _PlanLook look;
  final bool radio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final chosen = look == _PlanLook.chosen;
    final (fill, border) = switch (look) {
      _PlanLook.chosen => (
        colors.accentSoft,
        BorderSide(color: colors.accent, width: 2),
      ),
      _PlanLook.unchosen => (
        colors.surface,
        BorderSide(color: colors.lineStrong),
      ),
      _PlanLook.single => (
        colors.surface,
        BorderSide(color: colors.accent, width: 1.5),
      ),
    };
    final tag = plan.tag;
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        selected: look != _PlanLook.unchosen,
        inMutuallyExclusiveGroup: look != _PlanLook.single,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Gap.md),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(style.radii.md),
              border: Border.fromBorderSide(border),
            ),
            child: Row(
              crossAxisAlignment: radio
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              spacing: Gap.md,
              children: [
                if (radio) RadioMark(selected: chosen),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Gap.xs,
                    children: [
                      // A narrow tile puts the tag under the name.
                      Wrap(
                        spacing: Gap.sm,
                        runSpacing: Gap.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(plan.name, style: text.titleMedium),
                          if (tag != null)
                            ForgeTag(tag, kind: ForgeTagKind.record),
                        ],
                      ),
                      Text(
                        plan.price,
                        style: style.data.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.ink,
                        ),
                      ),
                      Text(
                        plan.detail,
                        style: text.labelMedium!.copyWith(
                          fontWeight: FontWeight.w400,
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanSkeleton extends StatelessWidget {
  const _PlanSkeleton({required this.radio});

  final bool radio;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(style.radii.md),
        border: Border.all(color: style.colors.line),
      ),
      child: Row(
        spacing: Gap.md,
        children: [
          if (radio)
            const SkeletonBar(width: RadioMark.size, height: RadioMark.size),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Gap.sm,
              children: [
                SkeletonBar(widthFactor: 0.30, height: 12),
                SkeletonBar(widthFactor: 0.50, height: 10),
                SkeletonBar(widthFactor: 0.65, height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Restore purchases: a quiet 40px link in ink-muted; while [busy] it is
/// ink with a spinner, and while a purchase runs its label fades to
/// line-strong.
class _RestoreButton extends StatelessWidget {
  const _RestoreButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final ink = busy
        ? colors.ink
        : onTap == null
        ? colors.lineStrong
        : colors.inkMuted;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: Pressable(
        onTap: onTap,
        height: ForgeTheme.buttonHeight,
        builder: (context, _) => SizedBox(
          height: ForgeTheme.buttonHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: Gap.sm,
            children: [
              if (busy) BusyRing(size: 16, stroke: 2, sweep: 0.75, color: ink),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall!
                      .copyWith(fontWeight: FontWeight.w500, color: ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The centred message in the card: an icon in a sunken circle, a title,
/// one line and its button.
class _Message extends StatelessWidget {
  const _Message(this.message);

  final SubscriptionMessage message;

  static const double _circle = 44;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    final (icon, iconColor, variant) = switch (message._kind) {
      _MessageKind.failed => (
        ForgeIcons.cloudOff,
        colors.danger,
        ForgeButtonVariant.outline,
      ),
      _MessageKind.pending => (
        ForgeIcons.hourglassEmpty,
        colors.inkMuted,
        ForgeButtonVariant.secondary,
      ),
      _MessageKind.approved => (
        ForgeIcons.check,
        colors.success,
        ForgeButtonVariant.primary,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
      child: Column(
        spacing: Gap.sm,
        children: [
          Container(
            width: _circle,
            height: _circle,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceSunken,
            ),
            child: ForgeIcon(icon, size: 22, color: iconColor),
          ),
          Column(
            spacing: Gap.xs,
            children: [
              Text(
                message.title,
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
              Text(
                message.message,
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ],
          ),
          ForgeButton(
            label: message.actionLabel,
            onPressed: message.onAction,
            variant: variant,
          ),
        ],
      ),
    );
  }
}

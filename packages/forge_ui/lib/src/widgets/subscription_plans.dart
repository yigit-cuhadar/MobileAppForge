import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'benefit_list.dart';
import 'card_frame.dart';
import 'forge_app_bar.dart';
import 'forge_button.dart';
import 'forge_tag.dart';
import 'radio_mark.dart';
import 'skeleton.dart';

/// How [SubscriptionPlans] lays out its plans; one is picked per user for
/// an A/B/C test.
enum SubscriptionLayout {
  /// Rows one under another, each with a radio.
  rows,

  /// Tiles side by side, no radio.
  tiles,

  /// The selected plan alone, with a link to the other one.
  single,
}

/// One plan as the app words it for the layout in use.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.name,
    required this.price,
    required this.terms,
    this.detail,
    this.tag,
  });

  /// "Yearly"; in the single layout the muted line over the price
  /// ("Yearly · 7 days free").
  final String name;

  /// In mono: "$59.99 / year" in rows and single, "$59.99" in tiles.
  final String price;

  /// The full renewal terms under the main button while this plan is
  /// chosen.
  final String terms;

  /// The line under the price in tiles ("7 days free") and single ("That
  /// is $5.00 a month."); rows draw none.
  final String? detail;

  /// A record tag at the end of a row ("Best value"); rows only.
  final String? tag;
}

enum _MessageKind { failed, unavailable, pending }

/// A card in the place of the plans, with one button. The main button is
/// off while it shows.
class SubscriptionMessage {
  /// The prices could not be loaded: the card sits under the header, and
  /// the main button shows without the terms.
  const SubscriptionMessage.failed({
    required String this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  }) : _kind = _MessageKind.failed;

  /// The store cannot sell here (a ban icon and one line); no terms.
  const SubscriptionMessage.unavailable({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  }) : title = null,
       _kind = _MessageKind.unavailable;

  /// A purchase waits for approval (Ask to Buy); [onAction] ("Got it") lets
  /// the user go on.
  const SubscriptionMessage.pending({
    required String this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  }) : _kind = _MessageKind.pending;

  final String? title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final _MessageKind _kind;
}

/// The paywall page: close (unless [onClose] is null) on the left of an
/// untitled bar, the [title] and
/// a checked [BenefitList] of [benefits], the [plans] in the given [layout]
/// at the bottom of the scrolling part, then the footer: the main button,
/// the chosen plan's terms, Restore and the Terms and Privacy links. The
/// footer is pinned while it takes at most half the page; taller (large
/// text) it scrolls with the page, last.
///
/// While prices are [loading] the header, plans and main button are a
/// skeleton. [purchasing] and [restoring] name the work running, shown
/// with a spinner on its button; a [message] replaces the plans. The app
/// shows Restore's result as a snackbar and closes the paywall on success.
class SubscriptionPlans extends StatelessWidget {
  const SubscriptionPlans({
    super.key,
    this.onClose,
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
    required this.termsLabel,
    required this.onTerms,
    required this.privacyLabel,
    required this.onPrivacy,
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

  /// Null hides the close button (a paywall that cannot be dismissed);
  /// the bar keeps its height.
  final VoidCallback? onClose;
  final String title;
  final List<String> benefits;
  final SubscriptionLayout layout;

  /// Empty while [loading] or when the prices failed.
  final List<SubscriptionPlan> plans;

  /// The index of the chosen plan; the single layout shows only this one.
  final int selected;
  final ValueChanged<int> onSelected;

  /// "Start 7-day free trial", "Subscribe".
  final String purchaseLabel;
  final VoidCallback onPurchase;
  final String restoreLabel;
  final VoidCallback onRestore;
  final String termsLabel;
  final VoidCallback onTerms;
  final String privacyLabel;
  final VoidCallback onPrivacy;

  /// The single layout's link to the other plan ("See monthly plan").
  final String? alternativeLabel;
  final VoidCallback? onAlternative;
  final bool loading;

  /// While a purchase runs: the main button's label ("Confirming with the
  /// store"), next to a spinner. Plan choice and Restore take no taps.
  final String? purchasing;

  /// While purchases are restored: Restore's label, next to a spinner; the
  /// main button is off.
  final String? restoring;
  final SubscriptionMessage? message;

  // Plan boxes drawn while prices load, before the app knows its plans.
  static const _skeletonPlans = 2;

  bool get _busy => purchasing != null || restoring != null;

  SubscriptionPlan? get _chosen =>
      selected >= 0 && selected < plans.length ? plans[selected] : null;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    final failed = message?._kind == _MessageKind.failed;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: ForgeAppBar.height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                child: onClose == null
                    ? null
                    : Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ForgeAppBarAction.icon(
                          icon: ForgeIcons.close,
                          label: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          onPressed: onClose,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: _PinOrScroll(
                top: [
                  if (loading) const _HeaderSkeleton() else _header(context),
                  if (failed) ...[
                    const SizedBox(height: Gap.md),
                    _MessageCard(message!),
                  ],
                ],
                bottom: message != null && !failed
                    ? _MessageCard(message)
                    : failed
                    ? null
                    : _plans(),
                footer: _footer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.sm, Gap.xs, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Gap.sm,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium!
              .copyWith(fontSize: 26, height: 30 / 26, letterSpacing: -0.52),
        ),
        BenefitList.checked(benefits),
      ],
    ),
  );

  Widget _plans() {
    if (loading) {
      return _arrange(
        layout == SubscriptionLayout.single ? 1 : _skeletonPlans,
        (_) => _PlanSkeleton(radio: layout == SubscriptionLayout.rows),
      );
    }
    final alternativeLabel = this.alternativeLabel;
    if (layout == SubscriptionLayout.single) {
      final plan = _chosen;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: [
          if (plan != null) _SinglePlan(plan),
          if (alternativeLabel != null)
            Center(
              child: ForgeButton(
                label: alternativeLabel,
                onPressed: _busy ? null : onAlternative,
                variant: ForgeButtonVariant.text,
                size: ForgeButtonSize.small,
              ),
            ),
        ],
      );
    }
    return _arrange(
      plans.length,
      (i) => _PlanBox(
        plan: plans[i],
        chosen: i == selected,
        tile: layout == SubscriptionLayout.tiles,
        onTap: _busy ? null : () => onSelected(i),
      ),
    );
  }

  Widget _arrange(int count, Widget Function(int index) box) =>
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

  Widget _footer() {
    final kind = message?._kind;
    final terms =
        loading ||
            kind == _MessageKind.failed ||
            kind == _MessageKind.unavailable
        ? null
        : _chosen?.terms;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.xs,
        children: [
          if (loading)
            const SkeletonBar(
              widthFactor: 1,
              height: ForgeTheme.buttonHeightLg,
              radius: ForgeRadii.button,
            )
          else
            ForgeButton(
              label: purchasing ?? purchaseLabel,
              onPressed: restoring == null && message == null
                  ? onPurchase
                  : null,
              loading: purchasing != null,
              size: ForgeButtonSize.large,
            ),
          if (terms != null) _Terms(terms),
          IgnorePointer(
            ignoring: purchasing != null,
            child: ForgeButton(
              label: restoring ?? restoreLabel,
              onPressed: onRestore,
              loading: restoring != null,
              variant: ForgeButtonVariant.text,
            ),
          ),
          // Large text wraps the links instead of cutting them.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: Gap.md,
            children: [
              ForgeButton(
                label: termsLabel,
                onPressed: onTerms,
                variant: ForgeButtonVariant.text,
                size: ForgeButtonSize.small,
              ),
              ForgeButton(
                label: privacyLabel,
                onPressed: onPrivacy,
                variant: ForgeButtonVariant.text,
                size: ForgeButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The page above [footer]: [top] at the top and [bottom] (the plans) at
/// the foot of the room left. The footer is pinned to the bottom while it
/// takes at most half the height; taller, the whole page scrolls as one,
/// the footer last. Either way the page scrolls when it does not fit, so
/// nothing is left under the footer.
class _PinOrScroll extends StatefulWidget {
  const _PinOrScroll({
    required this.top,
    required this.bottom,
    required this.footer,
  });

  final List<Widget> top;
  final Widget? bottom;
  final Widget footer;

  @override
  State<_PinOrScroll> createState() => _PinOrScrollState();
}

class _PinOrScrollState extends State<_PinOrScroll> {
  final _footer = GlobalKey();
  bool _pinned = false;
  double _height = 0;

  /// Runs after layout, when the footer's height is known; starts unpinned
  /// so the first frame never overflows.
  void _measure() {
    if (!mounted) return;
    final footer = _footer.currentContext?.size?.height;
    if (footer == null) return;
    final pinned = footer <= _height / 2;
    if (pinned != _pinned) setState(() => _pinned = pinned);
  }

  void _remeasure() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _height = constraints.maxHeight;
      _remeasure();
      final footer = NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          _remeasure();
          return true;
        },
        child: SizeChangedLayoutNotifier(
          child: KeyedSubtree(key: _footer, child: widget.footer),
        ),
      );
      // At least the viewport's height, so the plans sit at its foot, and
      // as tall as its content otherwise. No intrinsic sizes: they can
      // come out short and cut the content off.
      final page = LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewport.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.top,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(Gap.md),
                      child: widget.bottom,
                    ),
                    if (!_pinned) footer,
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (!_pinned) return page;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: page),
          // A footer that grows past half the page (plans arriving at a
          // large text size) is clipped for the frame until it is measured
          // at its full height and moves into the page.
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _height / 2),
            child: UnconstrainedBox(
              constrainedAxis: Axis.horizontal,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: footer,
            ),
          ),
        ],
      );
    },
  );
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(Gap.xs, Gap.sm, Gap.xs, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Gap.sm + Gap.xs,
      children: [
        SkeletonBar(widthFactor: 0.70, height: 22),
        SkeletonBar(widthFactor: 0.60, height: 10),
        SkeletonBar(widthFactor: 0.52, height: 10),
        SkeletonBar(widthFactor: 0.64, height: 10),
      ],
    ),
  );
}

/// The box of a row or a tile: surface in the card border, or accent-soft
/// in a 1.5px accent border while [chosen].
class _PlanBox extends StatelessWidget {
  const _PlanBox({
    required this.plan,
    required this.chosen,
    required this.tile,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool chosen;
  final bool tile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final price = Text(
      plan.price,
      style: style.data.copyWith(
        fontSize: 13,
        height: 18 / 13,
        color: colors.ink,
      ),
    );
    final detail = plan.detail;
    final tag = plan.tag;
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        selected: chosen,
        inMutuallyExclusiveGroup: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(Gap.md),
            decoration: BoxDecoration(
              color: chosen ? colors.accentSoft : colors.surface,
              borderRadius: BorderRadius.circular(style.radii.lg),
              border: chosen
                  ? Border.all(color: colors.accent, width: 1.5)
                  : style.cardBorder == 0
                  ? null
                  : Border.all(color: colors.line, width: style.cardBorder),
            ),
            child: tile
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: Gap.xs,
                    children: [
                      Text(
                        plan.name,
                        textAlign: TextAlign.center,
                        style: text.titleMedium,
                      ),
                      price,
                      if (detail != null)
                        Text(
                          detail,
                          textAlign: TextAlign.center,
                          style: text.labelSmall!.copyWith(
                            fontWeight: FontWeight.w400,
                            color: colors.inkMuted,
                          ),
                        ),
                    ],
                  )
                : Row(
                    spacing: Gap.sm + Gap.xs,
                    children: [
                      RadioMark(selected: chosen),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Text(plan.name, style: text.titleMedium),
                            price,
                          ],
                        ),
                      ),
                      // At the row's end; large text shortens the tag
                      // before the plan's name.
                      if (tag != null)
                        Flexible(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: ForgeTag(tag, kind: ForgeTagKind.record),
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

/// The single layout's plan: the name line, a large mono price and the
/// detail, in a 1.5px accent outline.
class _SinglePlan extends StatelessWidget {
  const _SinglePlan(this.plan);

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final detail = plan.detail;
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(style.radii.lg),
        border: Border.all(color: colors.accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.xs,
        children: [
          Text(
            plan.name,
            style: text.labelMedium!.copyWith(
              fontWeight: FontWeight.w400,
              color: colors.inkMuted,
            ),
          ),
          Text(plan.price, style: style.dataLg.copyWith(color: colors.ink)),
          if (detail != null) Text(detail, style: text.bodySmall),
        ],
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
        color: style.colors.surface,
        borderRadius: BorderRadius.circular(style.radii.lg),
        border: Border.all(color: style.colors.line),
      ),
      child: Row(
        spacing: Gap.sm + Gap.xs,
        children: [
          if (radio)
            SkeletonBar(
              width: RadioMark.size,
              height: RadioMark.size,
              radius: style.radii.sm,
            ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Gap.sm,
              children: [
                SkeletonBar(widthFactor: 0.30, height: 12),
                SkeletonBar(widthFactor: 0.55, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The renewal terms: 11px ink-muted, centred.
class _Terms extends StatelessWidget {
  const _Terms(this.terms);

  final String terms;

  @override
  Widget build(BuildContext context) => Text(
    terms,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.labelSmall!.copyWith(
      height: 15 / 11,
      fontWeight: FontWeight.w400,
      color: ForgeStyle.of(context).colors.inkMuted,
    ),
  );
}

/// The card in place of the plans: an icon in a sunken circle, the title
/// and its line (or the one line alone, as the title), and its button.
class _MessageCard extends StatelessWidget {
  const _MessageCard(this.message);

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
      _MessageKind.unavailable => (
        ForgeIcons.block,
        colors.danger,
        ForgeButtonVariant.outline,
      ),
      _MessageKind.pending => (
        ForgeIcons.hourglassEmpty,
        colors.inkMuted,
        ForgeButtonVariant.secondary,
      ),
    };
    final title = message.title;
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.md,
          vertical: Gap.lg,
        ),
        child: Column(
          spacing: Gap.sm + Gap.xs,
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
            if (title != null)
              Column(
                spacing: Gap.xs,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: text.titleMedium,
                  ),
                  Text(
                    message.message,
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
                  ),
                ],
              )
            else
              Text(
                message.message,
                textAlign: TextAlign.center,
                style: text.titleMedium,
              ),
            ForgeButton(
              label: message.actionLabel,
              onPressed: message.onAction,
              variant: variant,
            ),
          ],
        ),
      ),
    );
  }
}

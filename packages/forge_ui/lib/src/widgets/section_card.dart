import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'forge_button.dart';
import 'tap_band.dart';
import 'skeleton.dart';

/// A card for one section of a page: the [title], a [detail] in data
/// ink-muted and a chevron; the whole card opens the section's page.
/// [SectionCard.plain] only holds its content.
class SectionCard extends StatelessWidget {
  /// Filled: [child] holds the content (BandBars, rows).
  const SectionCard({
    super.key,
    required this.title,
    this.detail,
    required this.onTap,
    required Widget this.child,
  }) : _state = _State.filled,
       message = null,
       onRetry = null,
       retryLabel = null,
       tag = null,
       actionLabel = null,
       onAction = null;

  /// Shimmering skeleton bars while the content loads.
  const SectionCard.loading({
    super.key,
    required this.title,
    required this.onTap,
  }) : _state = _State.loading,
       detail = null,
       child = null,
       message = null,
       onRetry = null,
       retryLabel = null,
       tag = null,
       actionLabel = null,
       onAction = null;

  /// Loading failed: [message] in danger and an outline Retry.
  const SectionCard.error({
    super.key,
    required this.title,
    required this.onTap,
    required String this.message,
    required VoidCallback this.onRetry,
    required String this.retryLabel,
  }) : _state = _State.error,
       detail = null,
       child = null,
       tag = null,
       actionLabel = null,
       onAction = null;

  /// Nothing yet: one muted [message].
  const SectionCard.empty({
    super.key,
    required this.title,
    required this.onTap,
    required String this.message,
  }) : _state = _State.empty,
       detail = null,
       child = null,
       onRetry = null,
       retryLabel = null,
       tag = null,
       actionLabel = null,
       onAction = null;

  /// Premium: the Premium [tag] (Tags) before the chevron and one muted
  /// [message]; [onTap] opens the paywall.
  const SectionCard.locked({
    super.key,
    required this.title,
    required this.onTap,
    required Widget this.tag,
    required String this.message,
  }) : _state = _State.locked,
       detail = null,
       child = null,
       onRetry = null,
       retryLabel = null,
       actionLabel = null,
       onAction = null;

  /// The [title] over [child], no chevron and no tap; an optional text
  /// action in accent ([actionLabel], such as "Edit") ends the header.
  const SectionCard.plain({
    super.key,
    required this.title,
    required Widget this.child,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null)),
       _state = _State.filled,
       onTap = null,
       detail = null,
       message = null,
       onRetry = null,
       retryLabel = null,
       tag = null;

  final String title;
  final String? detail;
  final VoidCallback? onTap;
  final Widget? child;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final Widget? tag;
  final String? actionLabel;
  final VoidCallback? onAction;
  final _State _state;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final body = switch (_state) {
      _State.filled => child!,
      _State.loading => const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.sm,
        children: [
          SkeletonBar(widthFactor: 0.8, height: 10),
          SkeletonBar(widthFactor: 0.55, height: 10),
        ],
      ),
      _State.error => Row(
        spacing: Gap.sm,
        children: [
          Expanded(
            child: Text(
              message!,
              style: text.bodySmall!.copyWith(color: colors.danger),
            ),
          ),
          ForgeButton(
            label: retryLabel!,
            onPressed: onRetry,
            variant: ForgeButtonVariant.outline,
          ),
        ],
      ),
      _State.empty || _State.locked => Text(message!, style: text.bodySmall),
    };
    final action = actionLabel == null ? null : TapBandLink();
    Widget card = Padding(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.md,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Row(
              spacing: Gap.sm,
              children: [
                Expanded(child: Text(title, style: text.titleMedium)),
                if (detail != null)
                  // A long detail ends in an ellipsis at half the header.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth / 2,
                    ),
                    child: Text(
                      detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style.data.copyWith(color: colors.inkMuted),
                    ),
                  ),
                ?tag,
                if (actionLabel case final label?)
                  TapBandTarget(
                    link: action!,
                    child: Semantics(
                      button: true,
                      child: GestureDetector(
                        onTap: onAction,
                        child: Text(
                          label,
                          style: text.labelLarge!.copyWith(
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (onTap != null)
                  ForgeIcon(
                    ForgeIcons.chevronRight,
                    size: 18,
                    color: colors.inkMuted,
                  ),
              ],
            ),
          ),
          body,
        ],
      ),
    );
    if (action != null) card = TapBandArea(links: [action], child: card);
    return CardFrame(
      child: onTap == null ? card : InkWell(onTap: onTap, child: card),
    );
  }
}

enum _State { filled, loading, error, empty, locked }

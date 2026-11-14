import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'forge_button.dart';
import 'skeleton.dart';

/// A card for one section of a page: the [title], a [detail] in data
/// ink-muted and a chevron; the whole card opens the section's page.
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
       tag = null;

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
       tag = null;

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
       tag = null;

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
       tag = null;

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
       retryLabel = null;

  final String title;
  final String? detail;
  final VoidCallback onTap;
  final Widget? child;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final Widget? tag;
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
    return CardFrame(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Gap.md,
            children: [
              Row(
                spacing: Gap.sm,
                children: [
                  Expanded(child: Text(title, style: text.titleMedium)),
                  if (detail != null)
                    Text(
                      detail!,
                      style: style.data.copyWith(color: colors.inkMuted),
                    ),
                  ?tag,
                  ForgeIcon(
                    ForgeIcons.chevronRight,
                    size: 18,
                    color: colors.inkMuted,
                  ),
                ],
              ),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

enum _State { filled, loading, error, empty, locked }

import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'busy_ring.dart';
import 'card_frame.dart';
import 'forge_button.dart';
import 'skeleton.dart';

/// Content loading: card-shaped skeletons under a slow shimmer, never a
/// spinner.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  // Bar widths of each card: a title line, then two text lines.
  static const _cards = [
    [0.45, 0.85, 0.60],
    [0.35, 0.75, 0.50],
    [0.50, 0.80, 0.40],
  ];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, widths) in _cards.indexed) ...[
        if (i > 0) const SizedBox(height: Gap.sm),
        CardFrame(
          child: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBar(widthFactor: widths[0], height: 12),
                const SizedBox(height: Gap.sm),
                SkeletonBar(widthFactor: widths[1], height: 10),
                const SizedBox(height: Gap.sm),
                SkeletonBar(widthFactor: widths[2], height: 10),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

/// Loading failed: a danger icon, what went wrong, and Retry.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  /// The tighter form inside a card (a chart, a plan list): 8px apart.
  final bool compact;

  @override
  Widget build(BuildContext context) => _Message(
    icon: ForgeIcons.error,
    iconColor: ForgeStyle.of(context).colors.danger,
    title: title,
    message: message,
    actions: [
      ForgeButton(
        label: retryLabel,
        onPressed: onRetry,
        variant: ForgeButtonVariant.outline,
      ),
    ],
    compact: compact,
  );
}

/// Nothing to show yet: an icon, a title, one line and up to two [actions]
/// (Buttons), or none.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.icon = ForgeIcons.inbox,
    required this.title,
    required this.message,
    this.actions = const [],
    this.compact = false,
  });

  final ForgeIconData icon;
  final String title;
  final String message;
  final List<Widget> actions;

  /// The tighter form inside a card (a chart, a plan list): 8px apart.
  final bool compact;

  @override
  Widget build(BuildContext context) => _Message(
    icon: icon,
    iconColor: ForgeStyle.of(context).colors.inkMuted,
    title: title,
    message: message,
    actions: actions,
    compact: compact,
  );
}

/// Work the user started (preparing, saving): the small ring, a title and a
/// line under it.
class WorkingView extends StatelessWidget {
  const WorkingView({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    return _Centred(
      top: BusyRing(
        size: 28,
        stroke: 3,
        sweep: 0.25,
        color: colors.accent,
        track: colors.surfaceSunken,
      ),
      title: title,
      message: message,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actions,
    required this.compact,
  });

  final ForgeIconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final List<Widget> actions;
  final bool compact;

  static const _circle = 44.0;

  @override
  Widget build(BuildContext context) => _Centred(
    top: Container(
      width: _circle,
      height: _circle,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ForgeStyle.of(context).colors.surfaceSunken,
      ),
      child: ForgeIcon(icon, size: 22, color: iconColor),
    ),
    title: title,
    message: message,
    actions: actions,
    compact: compact,
  );
}

class _Centred extends StatelessWidget {
  const _Centred({
    required this.top,
    required this.title,
    required this.message,
    this.actions = const [],
    this.compact = false,
  });

  final Widget top;
  final String title;
  final String message;
  final List<Widget> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final gap = compact ? Gap.sm : Gap.md;
    return Center(
      child: Padding(
        padding: compact
            ? const EdgeInsets.symmetric(vertical: Gap.sm)
            : const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            top,
            SizedBox(height: gap),
            Text(title, textAlign: TextAlign.center, style: text.titleMedium),
            const SizedBox(height: Gap.xs),
            Text(message, textAlign: TextAlign.center, style: text.bodySmall),
            if (actions.isNotEmpty) ...[
              SizedBox(height: gap),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: Gap.sm,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

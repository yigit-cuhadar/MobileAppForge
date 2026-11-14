import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';

/// A calm card about one thing that is off or over (a permission turned
/// off, Premium ended) with one [action]: the [icon] in danger in a
/// surface-sunken circle, a [title], one or two lines of [message] and the
/// action (Button's secondary form) across the full width.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final ForgeIconData icon;
  final String title;
  final String message;
  final Widget action;

  static const _circle = 36.0;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.sm,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Gap.md,
              children: [
                Container(
                  width: _circle,
                  height: _circle,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceSunken,
                  ),
                  child: ForgeIcon(icon, size: 18, color: colors.danger),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(title, style: text.titleMedium),
                      Text(message, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            action,
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';

/// A soft accent band with a one-time hint.
class TipBanner extends StatelessWidget {
  /// A light bulb and the [message]; [dismissLabel] ("Got it") at the
  /// bottom right closes it for good through [onDismiss].
  const TipBanner({
    super.key,
    required String this.message,
    required String this.dismissLabel,
    required this.onDismiss,
  }) : icon = null,
       title = null,
       detail = null,
       action = null;

  /// A reminder: the [icon], a bold [title], a [detail] line and a small
  /// primary [action] (Button) in place of "Got it". Swiping it away
  /// closes it through [onDismiss].
  const TipBanner.action({
    super.key,
    required ForgeIconData this.icon,
    required String this.title,
    required String this.detail,
    required Widget this.action,
    required this.onDismiss,
  }) : message = null,
       dismissLabel = null;

  final String? message;
  final String? dismissLabel;
  final ForgeIconData? icon;
  final String? title;
  final String? detail;
  final Widget? action;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final on = style.colors.onAccentSoft;
    final text = Theme.of(context).textTheme;
    final decoration = BoxDecoration(
      color: style.colors.accentSoft,
      borderRadius: BorderRadius.circular(style.radii.md),
    );

    if (action != null) {
      return Dismissible(
        key: ValueKey(title),
        onDismissed: (_) => onDismiss(),
        child: Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: decoration,
          child: Row(
            spacing: Gap.md,
            children: [
              ForgeIcon(icon!, size: 20, color: on),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(title!, style: text.labelLarge!.copyWith(color: on)),
                    Text(
                      detail!,
                      style: text.labelMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        color: on.withValues(alpha: on.a * 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              action!,
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.md, Gap.md, Gap.sm),
      decoration: decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 2,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Gap.sm,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: ForgeIcon(ForgeIcons.lightbulb, size: 18, color: on),
              ),
              Expanded(
                child: Text(
                  message!,
                  style: text.bodySmall!.copyWith(height: 19 / 13, color: on),
                ),
              ),
            ],
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: on,
                padding: const EdgeInsets.symmetric(horizontal: Gap.md),
              ),
              child: Text(dismissLabel!),
            ),
          ),
        ],
      ),
    );
  }
}

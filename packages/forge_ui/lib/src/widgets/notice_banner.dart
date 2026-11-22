import 'package:material_ui/material_ui.dart';

import '../icons/forge_icon.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';

/// A calm card about one thing that is off or over (a permission turned
/// off, Premium ended): the [icon] in danger in a surface-sunken circle, a
/// [title], one or two lines of [message] and an optional [action]
/// (Button's secondary form) across the full width.
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.icon,
    required String this.title,
    required this.message,
    this.action,
  });

  /// The compact form: the [message] alone, one line in ink next to the
  /// icon ("No exercise fits your answers for: [ITEMS]"), and no action.
  const NoticeBanner.line({
    super.key,
    required this.icon,
    required this.message,
  }) : title = null,
       action = null;

  final ForgeIconData icon;
  final String? title;
  final String message;
  final Widget? action;

  static const _circle = 36.0;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    final circle = Container(
      width: _circle,
      height: _circle,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceSunken,
      ),
      child: ForgeIcon(icon, size: 18, color: colors.danger),
    );
    final title = this.title;
    if (title == null) {
      return CardFrame(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              circle,
              Expanded(
                child: Padding(
                  // The first line centred on the circle.
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(message, style: text.bodyMedium),
                ),
              ),
            ],
          ),
        ),
      );
    }
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
                circle,
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
            ?action,
          ],
        ),
      ),
    );
  }
}

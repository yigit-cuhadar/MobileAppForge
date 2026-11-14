import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';

enum ForgeTagKind {
  /// A plain mark on surface-sunken.
  neutral,

  /// A category on accent-soft.
  category,

  /// A record, on a soft success tint.
  record,

  /// Where a record came from, on a soft info tint.
  source,

  /// Filled accent with a lock, the same everywhere.
  premium,

  /// No fill, the label in ink-muted.
  plain,
}

/// A small soft-filled label: 22px tall, 11px semibold, with an optional
/// [icon] before the label in the label's colour.
class ForgeTag extends StatelessWidget {
  const ForgeTag(
    this.label, {
    super.key,
    this.kind = ForgeTagKind.neutral,
    this.icon,
  });

  final String label;
  final ForgeTagKind kind;
  final ForgeIconData? icon;

  static const double height = 22;

  @override
  Widget build(BuildContext context) {
    final p = ForgeStyle.of(context).colors;
    // A tinted fill takes the role mixed toward ink as its text, for 4.5:1.
    (Color, Color) tint(Color role, double amount) =>
        (Color.lerp(p.surface, role, amount)!, Color.lerp(p.ink, role, 0.7)!);
    final (fill, ink) = switch (kind) {
      ForgeTagKind.neutral => (p.surfaceSunken, p.inkMuted),
      ForgeTagKind.category => (p.accentSoft, p.onAccentSoft),
      ForgeTagKind.record => tint(p.success, 0.16),
      ForgeTagKind.source => tint(p.info, 0.14),
      ForgeTagKind.premium => (p.accent, p.onAccent),
      ForgeTagKind.plain => (null, p.inkMuted),
    };
    final premium = kind == ForgeTagKind.premium;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (premium) ...[
            ForgeIcon(ForgeIcons.lock, size: 11, weight: 2.6, color: ink),
            const SizedBox(width: Gap.xs),
          ] else if (icon case final icon?) ...[
            ForgeIcon(icon, size: 12, color: ink),
            const SizedBox(width: Gap.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: ink,
                fontWeight: premium ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

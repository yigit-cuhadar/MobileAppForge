import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';

/// Steps through a week, month or year: arrows on both sides, the [period]
/// in the middle. Tapping the period calls [onPeriodTap] (the app opens a
/// date picker). In the current period [onNext] is null and the forward
/// arrow fades.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.period,
    required this.onPrevious,
    required this.onNext,
    required this.onPeriodTap,
    required this.previousLabel,
    required this.nextLabel,
  });

  final String period;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onPeriodTap;

  /// The arrows' names for screen readers.
  final String previousLabel;
  final String nextLabel;

  static const double _fadedOpacity = 0.3;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    // The arrows point outward: previous toward the start side.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: ForgeTheme.tapMin,
      padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
      decoration: BoxDecoration(
        color: style.colors.surface,
        borderRadius: BorderRadius.circular(style.radii.md),
        border: Border.all(color: style.colors.line),
      ),
      child: Row(
        children: [
          _Arrow(
            icon: rtl ? ForgeIcons.chevronRight : ForgeIcons.chevronLeft,
            label: previousLabel,
            onTap: onPrevious,
          ),
          Expanded(
            child: Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPeriodTap,
                child: Center(
                  child: Text(
                    period,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: onNext == null ? _fadedOpacity : 1,
            child: _Arrow(
              icon: rtl ? ForgeIcons.chevronLeft : ForgeIcons.chevronRight,
              label: nextLabel,
              onTap: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});

  final ForgeIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox.square(
        dimension: ForgeTheme.tapMin,
        child: Center(
          child: ForgeIcon(
            icon,
            size: 20,
            color: ForgeStyle.of(context).colors.ink,
          ),
        ),
      ),
    ),
  );
}

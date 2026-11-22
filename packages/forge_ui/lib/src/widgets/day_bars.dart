import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';

/// One small bar for each of the [days] of a week, its value in the app's
/// [color] over its label (a letter); a day with nothing is a short
/// surface-sunken line. The tallest bar takes the full height. Screen
/// readers hear [semanticLabel].
class DayBars extends StatelessWidget {
  const DayBars({
    super.key,
    required this.days,
    required this.color,
    required this.semanticLabel,
  });

  final List<({String label, double value})> days;
  final Color color;
  final String semanticLabel;

  static const double _height = 40;
  static const double _empty = 3;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final top = days.fold(0.0, (top, day) => math.max(top, day.value));
    final radius = BorderRadius.circular(_empty);
    final labelStyle = Theme.of(context).textTheme.labelSmall!
        .copyWith(fontWeight: FontWeight.w400, color: colors.inkMuted);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: Gap.sm,
          children: [
            for (final (:label, :value) in days)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Gap.xs,
                  children: [
                    Container(
                      height: value > 0
                          ? math.max(_empty, value / top * _height)
                          : _empty,
                      decoration: BoxDecoration(
                        color: value > 0 ? color : colors.surfaceSunken,
                        borderRadius: radius,
                      ),
                    ),
                    Text(label, maxLines: 1, style: labelStyle),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

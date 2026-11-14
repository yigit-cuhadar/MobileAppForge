import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';

/// A labelled progress bar with ticks at a band's [low] and [high] ends.
/// The fill says where [value] is: accent within the band, a soft accent
/// below it, danger above it. [value], [low] and [high] are shares of the
/// track (0–1); [valueLabel] is the figure shown at the right.
class BandBar extends StatelessWidget {
  const BandBar({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.low,
    required this.high,
  }) : assert(0 <= low && low <= high && high <= 1),
       _compact = false;

  /// The tighter form inside a SectionCard: no ticks, the bar 4px under
  /// the label.
  const BandBar.compact({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.low,
    required this.high,
  }) : assert(0 <= low && low <= high && high <= 1),
       _compact = true;

  final String label;
  final String valueLabel;
  final double value;
  final double low;
  final double high;
  final bool _compact;

  static const _height = 6.0;
  static const _tickWidth = 1.5;
  static const _tickHeight = 12.0;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final fill = value > high
        ? colors.danger
        : value < low
        ? Color.lerp(colors.surface, colors.accent, 0.4)!
        : colors.accent;
    const radius = BorderRadius.all(Radius.circular(_height / 2));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: _compact ? Gap.xs : Gap.sm,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              valueLabel,
              style: style.data.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
        SizedBox(
          height: _height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              Widget tick(double at) => Positioned(
                left: at * width,
                top: (_height - _tickHeight) / 2,
                child: Container(
                  width: _tickWidth,
                  height: _tickHeight,
                  color: colors.lineStrong,
                ),
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surfaceSunken,
                        borderRadius: radius,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: value.clamp(0.0, 1.0) * width,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: radius,
                      ),
                    ),
                  ),
                  if (!_compact) ...[tick(low), tick(high)],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

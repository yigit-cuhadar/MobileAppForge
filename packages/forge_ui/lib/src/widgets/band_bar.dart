import 'package:material_ui/material_ui.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';

/// The fill colours of a [BandBar] for each place of its value.
class BandBarFills {
  const BandBarFills({
    required this.below,
    required this.within,
    required this.above,
  });

  final Color below;
  final Color within;
  final Color above;
}

/// A labelled progress bar with ticks at a band's [low] and [high] ends.
/// The fill says where [value] is: accent within the band, a soft accent
/// below it, danger above it, or the app's [fills]. [value], [low] and
/// [high] are shares of the track (0–1); [valueLabel] is the figure shown
/// at the right.
class BandBar extends StatelessWidget {
  const BandBar({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.low,
    required this.high,
    this.fills,
    this.muted = false,
  }) : assert(0 <= low && low <= high && high <= 1),
       _compact = false;

  /// The tighter form inside a SectionCard: a 13px label, an 11px figure
  /// and the bar 4px under them.
  const BandBar.compact({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.low,
    required this.high,
    this.fills,
    this.muted = false,
  }) : assert(0 <= low && low <= high && high <= 1),
       _compact = true;

  final String label;
  final String valueLabel;
  final double value;
  final double low;
  final double high;
  final BandBarFills? fills;

  /// The label in ink-muted, for an entry with nothing in it yet (a zero
  /// listed last).
  final bool muted;
  final bool _compact;

  static const _height = 6.0;
  static const _tickWidth = 1.5;
  static const _tickHeight = 12.0;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final fills =
        this.fills ??
        BandBarFills(
          below: Color.lerp(colors.surface, colors.accent, 0.4)!,
          within: colors.accent,
          above: colors.danger,
        );
    final fill = value > high
        ? fills.above
        : value < low
        ? fills.below
        : fills.within;
    const radius = BorderRadius.all(Radius.circular(_height / 2));
    final text = Theme.of(context).textTheme;
    final labelStyle = (_compact ? text.bodySmall! : text.bodyMedium!).copyWith(
      color: muted ? colors.inkMuted : colors.ink,
    );
    final valueStyle = _compact
        ? style.data.copyWith(fontSize: 11, height: 14 / 11)
        : style.data;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: _compact ? Gap.xs : Gap.sm,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: labelStyle)),
            Text(
              valueLabel,
              style: valueStyle.copyWith(color: colors.inkMuted),
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
                  tick(low),
                  tick(high),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

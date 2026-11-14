import 'dart:math';

import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';

/// Progress toward a goal as a thin bar or a ring on surface-sunken, with
/// the [figure] and a [caption]. Reaching the [goal] turns the fill and the
/// caption success.
class Progress extends StatelessWidget {
  /// A 6px bar under the figure, the caption at the right.
  const Progress.bar({
    super.key,
    required this.value,
    required this.goal,
    required this.figure,
    required this.caption,
  }) : _ring = false;

  /// A 136px ring with an 8px stroke, the figure and caption inside.
  const Progress.ring({
    super.key,
    required this.value,
    required this.goal,
    required this.figure,
    required this.caption,
  }) : _ring = true;

  final double value;
  final double goal;
  final String figure;
  final String caption;
  final bool _ring;

  static const _barHeight = 6.0;
  static const _ringSize = 136.0;
  static const _ringStroke = 8.0;

  bool get _reached => value >= goal;

  double get _share => goal <= 0 ? 1 : (value / goal).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    final fill = _reached ? colors.success : colors.accent;
    // stat-style, in sans at 22px.
    final figureStyle = text.titleMedium!.copyWith(
      fontSize: 22,
      height: 26 / 22,
      letterSpacing: -0.44,
    );
    if (_ring) {
      return SizedBox.square(
        dimension: _ringSize,
        child: CustomPaint(
          painter: _RingPainter(
            share: _share,
            track: colors.surfaceSunken,
            fill: fill,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 2,
            children: [
              Text(figure, style: figureStyle),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: text.labelSmall!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: _reached ? colors.success : colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    const radius = BorderRadius.all(Radius.circular(_barHeight / 2));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Gap.sm,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(figure, style: figureStyle)),
            Text(
              caption,
              style: text.labelMedium!.copyWith(
                fontWeight: _reached ? FontWeight.w600 : FontWeight.w400,
                color: _reached ? colors.success : colors.inkMuted,
              ),
            ),
          ],
        ),
        Container(
          height: _barHeight,
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: radius,
          ),
          child: FractionallySizedBox(
            widthFactor: _share,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: fill, borderRadius: radius),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.share,
    required this.track,
    required this.fill,
  });

  final double share;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(Progress._ringStroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Progress._ringStroke;
    canvas.drawOval(rect, paint..color = track);
    if (share > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        share * 2 * pi,
        false,
        paint
          ..color = fill
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.share != share || old.track != track || old.fill != fill;
}

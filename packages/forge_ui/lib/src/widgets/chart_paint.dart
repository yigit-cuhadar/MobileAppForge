import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'skeleton.dart';

/// [path] cut into dashes of [dash] with [gap] between them, as SVG's
/// stroke-dasharray draws it.
Path dashed(Path path, double dash, double gap) {
  final out = Path();
  for (final metric in path.computeMetrics()) {
    var at = 0.0;
    while (at < metric.length) {
      out.addPath(
        metric.extractPath(at, math.min(at + dash, metric.length)),
        Offset.zero,
      );
      at += dash + gap;
    }
  }
  return out;
}

/// [count] evenly spaced x positions from [left] to [right]; the middle when
/// there is one.
List<double> spreadX(int count, double left, double right) => [
  for (var i = 0; i < count; i++)
    count == 1 ? (left + right) / 2 : left + (right - left) * i / (count - 1),
];

/// [value] placed between [bottom] (at [min]) and [top] (at [max]); the
/// middle when the range has no height.
double scaleY(double value, double min, double max, double top, double bottom) {
  if (max == min) return (top + bottom) / 2;
  return bottom - (value - min) / (max - min) * (bottom - top);
}

/// The index of the x in [xs] nearest to [x].
int nearest(List<double> xs, double x) {
  var best = 0;
  for (var i = 1; i < xs.length; i++) {
    if ((xs[i] - x).abs() < (xs[best] - x).abs()) best = i;
  }
  return best;
}

/// A dashed rounded outline in [color], [dash] long and [gap] apart, drawn
/// inside the edge as a CSS dashed border is.
class DashedOutlinePainter extends CustomPainter {
  const DashedOutlinePainter({
    required this.color,
    required this.width,
    required this.radius,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double width;

  /// Corner radius; half the side draws a circle.
  final double radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ).deflate(width / 2),
      );
    canvas.drawPath(
      dashed(path, dash, gap),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(DashedOutlinePainter old) =>
      old.color != color ||
      old.width != width ||
      old.radius != radius ||
      old.dash != dash ||
      old.gap != gap;
}

/// A dashed rounded outline in [color], 4px dashes 3px apart.
class DashedBorderPainter extends DashedOutlinePainter {
  const DashedBorderPainter({
    required super.color,
    required super.width,
    required super.radius,
  }) : super(dash: 4, gap: 3);
}

/// The title row of a chart card: the [title] and a [detail] in data
/// ink-muted at 11px.
class ChartTitleRow extends StatelessWidget {
  const ChartTitleRow({super.key, required this.title, required this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: Gap.sm,
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (detail != null)
          Text(
            detail!,
            style: style.data.copyWith(
              fontSize: 11,
              color: style.colors.inkMuted,
            ),
          ),
      ],
    );
  }
}

/// Two labels at the ends of a chart, in data ink-muted at [size].
class ChartEndLabels extends StatelessWidget {
  const ChartEndLabels({
    super.key,
    required this.start,
    required this.end,
    required this.size,
  });

  final String start;
  final String end;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final text = style.data.copyWith(
      fontSize: size,
      color: style.colors.inkMuted,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: Gap.sm,
      children: [
        Text(start, style: text),
        Text(end, style: text),
      ],
    );
  }
}

/// Two short skeleton bars where a chart's end labels will be.
class ChartEndSkeletons extends StatelessWidget {
  const ChartEndSkeletons({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      SkeletonBar(width: width, height: 10),
      SkeletonBar(width: width, height: 10),
    ],
  );
}

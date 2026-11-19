import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'chart_paint.dart';

/// A small 2px accent line through [values], oldest first, spread evenly
/// across, its last point marked with a dot: the shape of a trend whose
/// numbers show beside it. Decorative, so screen readers skip it.
class TrendLine extends StatelessWidget {
  const TrendLine({super.key, required this.values})
    : highLabel = null,
      lowLabel = null,
      startLabel = null,
      endLabel = null,
      semanticLabel = null;

  /// The line with its scale: [highLabel] and [lowLabel] (the highest and
  /// lowest value) at the left of faint lines at those values,
  /// [startLabel] and [endLabel] (the first and last point's dates) under
  /// its ends. Screen readers hear [semanticLabel].
  const TrendLine.scaled({
    super.key,
    required this.values,
    required String this.highLabel,
    required String this.lowLabel,
    required String this.startLabel,
    required String this.endLabel,
    required String this.semanticLabel,
  });

  final List<double> values;
  final String? highLabel;
  final String? lowLabel;
  final String? startLabel;
  final String? endLabel;
  final String? semanticLabel;

  static const double _height = 48;
  static const double _scaledHeight = 72;

  /// The line height of a label whose style sets none.
  static const double _lineHeight = 1.2;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    Widget line({required bool guides, required double height}) => SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendPainter(
          values: values,
          color: colors.accent,
          guides: guides ? colors.surfaceSunken : null,
        ),
      ),
    );
    final highLabel = this.highLabel;
    if (highLabel == null) {
      return ExcludeSemantics(child: line(guides: false, height: _height));
    }
    final label = style.data.copyWith(fontSize: 11, color: colors.inkMuted);
    // Larger text grows the line so its two labels still fit beside it.
    final labelHeight = MediaQuery.textScalerOf(context)
        .scale(label.fontSize! * (label.height ?? _lineHeight));
    final height = math.max(_scaledHeight, 2 * labelHeight + Gap.sm);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: Gap.sm,
          children: [
            SizedBox(
              height: height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(highLabel, style: label),
                  Text(lowLabel!, style: label),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  line(guides: true, height: height),
                  // The end date goes under the start when both do not fit.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: Gap.sm,
                    children: [
                      Text(startLabel!, style: label),
                      Text(endLabel!, style: label),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.values,
    required this.color,
    required this.guides,
  });

  final List<double> values;
  final Color color;

  /// The colour of the faint lines at the highest and lowest value; none
  /// when null.
  final Color? guides;

  static const _strokeWidth = 2.0;
  static const _dotRadius = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    // Room for the dot, so it is never cut at the edges.
    const inset = _dotRadius;
    if (guides case final guides?) {
      final paint = Paint()
        ..color = guides
        ..strokeWidth = 1;
      // At the highest and the lowest value.
      for (final y in [inset, size.height - inset]) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final xs = spreadX(values.length, inset, size.width - inset);
    final points = [
      for (final (i, value) in values.indexed)
        Offset(xs[i], scaleY(value, min, max, inset, size.height - inset)),
    ];
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(Path()..addPolygon(points, false), paint)
      ..drawCircle(points.last, _dotRadius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.color != color ||
      old.guides != guides ||
      !listEquals(old.values, values);
}

import 'package:flutter/material.dart';

import '../theme/forge_style.dart';
import 'chart_paint.dart';

/// Neutral day states drawn by WeekStrip and MonthGrid; the app maps its
/// own meanings onto them.
enum DayState {
  /// Nothing on the day: a plain number.
  none,

  /// Filled accent.
  done,

  /// Filled accent-soft.
  light,

  /// A dashed line-strong ring.
  planned,

  /// A 1.5px danger ring.
  missed,

  /// A 2.5px ink ring.
  today,

  /// Today and done: the done circle with the today ring 2px outside it.
  /// Drawn on days only, not as a legend mark.
  todayDone,
}

/// One day as a circle in its [state]: a 34px day with its [number], or a
/// 12px legend mark with none. A [selected] day gains a 1.5px accent ring
/// 2px outside its mark; a day with no mark becomes accent-soft inside the
/// ring's place. A [disabled] day, one that cannot be picked, has its
/// number in line-strong.
class DayCircle extends StatelessWidget {
  const DayCircle({
    super.key,
    required this.state,
    required String this.number,
    this.selected = false,
    this.disabled = false,
  }) : size = daySize;

  const DayCircle.legend({super.key, required this.state})
    : assert(state != DayState.todayDone),
      number = null,
      size = legendSize,
      selected = false,
      disabled = false;

  final DayState state;
  final String? number;
  final double size;
  final bool selected;
  final bool disabled;

  static const double daySize = 34;
  static const double legendSize = 12;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    final number = this.number;
    final plainSelected = selected && state == DayState.none;
    final (fill, ink, ring, ringWidth) = switch (state) {
      DayState.none when plainSelected => (p.accentSoft, p.ink, p.accent, 1.5),
      DayState.none => (null, p.ink, null, 0.0),
      DayState.done || DayState.todayDone => (p.accent, p.onAccent, null, 0.0),
      DayState.light => (p.accentSoft, p.onAccentSoft, null, 0.0),
      DayState.planned => (null, p.inkMuted, null, 0.0),
      DayState.missed => (null, p.danger, p.danger, 1.5),
      // The legend mark's ring is 2px.
      DayState.today => (null, p.ink, p.ink, number == null ? 2.0 : 2.5),
    };
    Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: ring == null ? null : Border.all(color: ring, width: ringWidth),
      ),
      child: number == null
          ? null
          : Text(
              number,
              maxLines: 1,
              style: style.data.copyWith(
                fontSize: 13,
                color: disabled ? p.lineStrong : ink,
                fontWeight: state == DayState.today ? FontWeight.w600 : null,
              ),
            ),
    );
    if (state == DayState.todayDone) {
      circle = CustomPaint(
        foregroundPainter: _OuterRing(color: p.ink, width: 2.5),
        child: circle,
      );
    }
    if (selected && !plainSelected) {
      circle = CustomPaint(
        foregroundPainter: _OuterRing(color: p.accent, width: 1.5),
        child: circle,
      );
    }
    if (state == DayState.planned) {
      circle = CustomPaint(
        painter: DashedBorderPainter(
          color: p.lineStrong,
          width: 1.5,
          radius: size / 2,
        ),
        child: circle,
      );
    }
    return circle;
  }
}

/// A ring drawn outside the circle it paints over, leaving a gap.
class _OuterRing extends CustomPainter {
  const _OuterRing({required this.color, required this.width});

  final Color color;
  final double width;

  static const _gap = 2.0;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(
    size.center(Offset.zero),
    size.shortestSide / 2 + _gap + width / 2,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = color,
  );

  @override
  bool shouldRepaint(_OuterRing old) =>
      old.color != color || old.width != width;
}

import 'dart:math';

import 'package:flutter/widgets.dart';

/// A turning arc for work the user started; never for loading content.
/// Draws [sweep] of a circle in [color] over an optional full [track].
class BusyRing extends StatefulWidget {
  const BusyRing({
    super.key,
    required this.size,
    required this.stroke,
    required this.color,
    required this.sweep,
    this.track,
  });

  final double size;
  final double stroke;
  final Color color;

  /// Share of the circle the arc covers.
  final double sweep;
  final Color? track;

  @override
  State<BusyRing> createState() => _BusyRingState();
}

class _BusyRingState extends State<BusyRing>
    with SingleTickerProviderStateMixin {
  late final _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: CustomPaint(
      painter: _RingPainter(
        _turn,
        stroke: widget.stroke,
        color: widget.color,
        sweep: widget.sweep,
        track: widget.track,
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(
    this.turn, {
    required this.stroke,
    required this.color,
    required this.sweep,
    this.track,
  }) : super(repaint: turn);

  final Animation<double> turn;
  final double stroke;
  final Color color;
  final double sweep;
  final Color? track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    if (track != null) canvas.drawOval(rect, paint..color = track!);
    canvas.drawArc(
      rect,
      -pi / 2 + turn.value * 2 * pi,
      sweep * 2 * pi,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.stroke != stroke ||
      old.color != color ||
      old.sweep != sweep ||
      old.track != track;
}

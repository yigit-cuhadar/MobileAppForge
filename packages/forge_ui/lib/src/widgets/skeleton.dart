import 'package:flutter/material.dart';

import '../theme/forge_style.dart';

/// A grey placeholder bar where content will load, under a slow soft
/// shimmer: a light band crosses it every 1.2 s. Give it a fixed [width] or
/// a [widthFactor] of the space it gets; its ends are fully rounded unless
/// it stands for a block (a chart, a box) with a [radius] of its own.
class SkeletonBar extends StatefulWidget {
  const SkeletonBar({
    super.key,
    this.width,
    this.widthFactor,
    required this.height,
    this.radius,
  }) : assert((width == null) != (widthFactor == null));

  final double? width;
  final double? widthFactor;
  final double height;
  final double? radius;

  static const period = Duration(milliseconds: 1200);

  @override
  State<SkeletonBar> createState() => _SkeletonBarState();
}

class _SkeletonBarState extends State<SkeletonBar>
    with SingleTickerProviderStateMixin {
  late final _shimmer = AnimationController(
    vsync: this,
    duration: SkeletonBar.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shimmer.stop();
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final bar = SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: _ShimmerPainter(
          _shimmer,
          base: colors.surfaceSunken,
          light: colors.surface,
          radius: widget.radius,
        ),
      ),
    );
    return widget.widthFactor == null
        ? bar
        : FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: widget.widthFactor,
            child: bar,
          );
  }
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter(
    this.shimmer, {
    required this.base,
    required this.light,
    required this.radius,
  }) : super(repaint: shimmer);

  final Animation<double> shimmer;
  final Color base;
  final Color light;
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final bar = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius ?? size.height / 2),
    );
    final paint = Paint()..color = base;
    if (w > 0) {
      // The band's centre runs from half a width before the bar to half a
      // width after it, so it enters and leaves unseen and the loop is
      // seamless.
      final centre = -w / 2 + shimmer.value * 2 * w;
      final band = Rect.fromLTWH(centre - 0.3 * w, 0, 0.6 * w, size.height);
      paint.shader = LinearGradient(colors: [base, light, base])
          .createShader(band);
    }
    canvas.drawRRect(bar, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.base != base ||
      old.light != light ||
      old.shimmer != shimmer ||
      old.radius != radius;
}

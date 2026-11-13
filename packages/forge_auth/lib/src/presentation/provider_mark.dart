import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/auth_user.dart';

/// The provider's logo shown before a social sign-in button's label. Sized
/// from the button's text and faded with it while the button is disabled.
class ProviderMark extends StatelessWidget {
  const ProviderMark(this.provider, {super.key});

  final SocialProvider provider;

  @override
  Widget build(BuildContext context) {
    // Google's button pairs 14 px text with a 20 px "G".
    final fontSize = DefaultTextStyle.of(context).style.fontSize ?? 14;
    final size = MediaQuery.textScalerOf(context).scale(fontSize) * 20 / 14;
    return ExcludeSemantics(
      child: switch (provider) {
        SocialProvider.google => Opacity(
          opacity: IconTheme.of(context).color?.a ?? 1,
          child: CustomPaint(
            size: Size.square(size),
            painter: const _GoogleGPainter(),
          ),
        ),
        SocialProvider.apple => Icon(Icons.apple, size: size),
      },
    );
  }
}

/// The standard colour "G" from Google's Sign in with Google assets
/// (developers.google.com/static/identity/images/signin-assets.zip), drawn in
/// its 20 x 20 box. Its brand colours are the one allowed exception to theme
/// colours: Google's branding guidelines forbid recolouring it.
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();

  static final _g = Path()
    ..moveTo(19.3987, 8.1814)
    ..lineTo(9.9849, 8.1814)
    ..lineTo(9.9849, 12.0445)
    ..lineTo(15.3598, 12.0445)
    ..cubicTo(15.1286, 13.294, 14.4294, 14.3596, 13.3676, 15.0712)
    ..cubicTo(12.4746, 15.6716, 11.3266, 16.0211, 9.9849, 16.0211)
    ..cubicTo(7.3864, 16.0211, 5.1823, 14.2666, 4.3947, 11.9004)
    ..cubicTo(4.1952, 11.2989, 4.0853, 10.6599, 4.0853, 9.9983)
    ..cubicTo(4.0853, 9.3367, 4.1952, 8.6966, 4.3947, 8.0962)
    ..cubicTo(5.1823, 5.7311, 7.3864, 3.9755, 9.9849, 3.9755)
    ..cubicTo(11.4524, 3.9755, 12.767, 4.4816, 13.8039, 5.4713)
    ..lineTo(16.6653, 2.6057)
    ..cubicTo(14.936, 0.9908, 12.6786, 0, 9.9849, 0)
    ..cubicTo(6.0832, 0, 2.705, 2.2414, 1.0618, 5.5076)
    ..cubicTo(0.383, 6.8592, 0, 8.3834, 0, 9.9994)
    ..cubicTo(0, 11.6155, 0.383, 13.1396, 1.0618, 14.4913)
    ..cubicTo(2.705, 17.7597, 6.0832, 20, 9.9849, 20)
    ..cubicTo(12.6797, 20, 14.9485, 19.1137, 16.6018, 17.5861)
    ..cubicTo(18.4887, 15.8452, 19.5732, 13.2702, 19.5732, 10.2275)
    ..cubicTo(19.5732, 9.5182, 19.5131, 8.835, 19.3987, 8.1825)
    ..close();

  static const _red = Color(0xFFFF4641);
  static const _blue = Color(0xFF3186FF);
  static const _yellow = Color(0xFFFFCC00);

  static const _sweepCenter = Offset(9.6819, 9.7927);
  static const _sweep = [
    (0.0, _red),
    (4.14555, _red),
    (39.154, _blue),
    (72.0044, _blue),
    (96.7463, Color(0xFF00A5B7)),
    (120.897, Color(0xFF0EBC5F)),
    (154.722, Color(0xFF0EBC5F)),
    (179.136, Color(0xFF6CC400)),
    (203.588, _yellow),
    (226.915, Color(0xFFFFD314)),
    (251.688, _yellow),
    (273.129, Color(0xFFFF6A2B)),
    (289.305, Color(0xFFFD4641)),
    (359.593, _red),
    (360.0, _red),
  ];

  /// Soft highlights over the sweep: centre, radii, rotation in degrees.
  static const _blobs = [
    (Offset(10.0496, 10.2413), 5.39634, 2.83537, 24.4473, _blue),
    (Offset(23.3538, 8.2155), 7.43918, 3.09357, 0.0, _blue),
    (Offset(15.2744, 6.2195), 7.40854, 2.37805, 0.0, _red),
    (Offset(19.5427, 2.9268), 7.40854, 2.37805, 0.0, Color(0xFFFF5B8B)),
    (Offset(14.4817, 9.878), 8.5061, 3.10976, 0.0, _blue),
    (Offset(15.1842, 4.0197), 4.53882, 2.37805, -28.6599, _red),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 20, size.height / 20);
    // Room for the blur, so the G's edges stay sharp.
    final bounds = const Rect.fromLTWH(0, 0, 20, 20).inflate(4);
    final rotation = Matrix4.identity()
      ..translateByDouble(_sweepCenter.dx, _sweepCenter.dy, 0, 1)
      ..rotateZ(-math.pi / 4)
      ..translateByDouble(-_sweepCenter.dx, -_sweepCenter.dy, 0, 1);
    final blur = ui.ImageFilter.blur(sigmaX: 1, sigmaY: 1);

    canvas
      ..saveLayer(bounds, Paint())
      ..saveLayer(bounds, Paint()..imageFilter = blur)
      ..drawOval(
        Rect.fromCenter(
          center: const Offset(10.1283, 9.7927),
          width: 25.7382,
          height: 25.772,
        ),
        Paint()
          ..shader = ui.Gradient.sweep(
            _sweepCenter,
            [for (final s in _sweep) s.$2],
            [for (final s in _sweep) s.$1 / 360],
            TileMode.clamp,
            0,
            2 * math.pi,
            rotation.storage,
          ),
      )
      ..restore();
    for (final (center, rx, ry, degrees, color) in _blobs) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(degrees * math.pi / 180)
        ..drawOval(
          Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
          Paint()
            ..color = color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
        )
        ..restore();
    }
    // A layer, as a path drawn with dstIn would leave the outside untouched.
    canvas
      ..saveLayer(bounds, Paint()..blendMode = BlendMode.dstIn)
      ..drawPath(_g, Paint())
      ..restore()
      ..restore();
  }

  @override
  bool shouldRepaint(_GoogleGPainter oldDelegate) => false;
}

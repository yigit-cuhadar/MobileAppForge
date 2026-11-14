import 'package:flutter/widgets.dart';

/// One line icon: SVG markup on a 24×24 grid (`path`, `circle`, `rect`),
/// stroked with round caps and joins. A shape with `fill="currentColor"` is
/// filled instead.
class ForgeIconData {
  const ForgeIconData(this.svg, {this.weight = 2});

  final String svg;

  /// Stroke width on the 24px grid when the icon is not given one.
  final double weight;
}

/// Draws a [ForgeIconData] in the surrounding [IconTheme]'s colour and size.
/// A heavier [weight] marks the selected tab.
class ForgeIcon extends StatelessWidget {
  const ForgeIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.weight,
    this.filled = false,
    this.semanticLabel,
  });

  final ForgeIconData icon;
  final double? size;
  final Color? color;

  /// Stroke width on the 24px grid; the icon's own by default.
  final double? weight;

  /// Fills the closed shapes too (a set favourite).
  final bool filled;
  final String? semanticLabel;

  /// Stroke width of the selected tab's icon.
  static const double selectedWeight = 2.6;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = this.size ?? theme.size ?? 24;
    final color = this.color ?? theme.color ?? const Color(0xFF000000);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _IconPainter(
            _shapes(icon.svg),
            color.withValues(alpha: color.a * (theme.opacity ?? 1)),
            weight ?? icon.weight,
            filled,
          ),
        ),
      ),
    );
  }

  static final _cache = <String, List<_Shape>>{};

  static List<_Shape> _shapes(String svg) =>
      _cache.putIfAbsent(svg, () => _parse(svg));
}

class _Shape {
  const _Shape(this.path, {required this.fill});

  final Path path;
  final bool fill;
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.shapes, this.color, this.weight, this.filled);

  final List<_Shape> shapes;
  final Color color;
  final double weight;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = weight
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final shape in shapes) {
      if (shape.fill || filled) canvas.drawPath(shape.path, fill);
      if (!shape.fill) canvas.drawPath(shape.path, stroke);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.shapes != shapes ||
      old.color != color ||
      old.weight != weight ||
      old.filled != filled;
}

final _element = RegExp(r'<(path|circle|rect)\b([^>]*)>');
final _attribute = RegExp(r'([\w-]+)="([^"]*)"');

List<_Shape> _parse(String svg) => [
  for (final match in _element.allMatches(svg))
    _shape(match.group(1)!, {
      for (final a in _attribute.allMatches(match.group(2)!))
        a.group(1)!: a.group(2)!,
    }),
];

_Shape _shape(String element, Map<String, String> a) {
  double n(String key) => double.parse(a[key] ?? '0');
  final fill = a['fill'] == 'currentColor';
  return switch (element) {
    'circle' => _Shape(
      Path()..addOval(
        Rect.fromCircle(center: Offset(n('cx'), n('cy')), radius: n('r')),
      ),
      fill: fill,
    ),
    'rect' => _Shape(
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(n('x'), n('y'), n('width'), n('height')),
          Radius.circular(n('rx')),
        ),
      ),
      fill: fill,
    ),
    _ => _Shape(_pathData(a['d'] ?? ''), fill: fill),
  };
}

final _token = RegExp(r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?');

/// SVG path data: M L H V C S A Z, absolute and relative.
Path _pathData(String d) {
  final path = Path();
  final tokens = [for (final m in _token.allMatches(d)) m.group(0)!];
  var i = 0;
  var command = '';
  var current = Offset.zero;
  var start = Offset.zero;
  Offset? lastControl;
  bool isCommand(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double next() => double.parse(tokens[i++]);
  // Arc flags may be written without separators ("0 011 2" is 0, 0, 1, 2).
  bool flag() {
    final t = tokens[i];
    if (t.length > 1) {
      tokens[i] = t.substring(1);
      return t[0] == '1';
    }
    i++;
    return t == '1';
  }

  while (i < tokens.length) {
    if (isCommand(tokens[i])) command = tokens[i++];
    final relative = command == command.toLowerCase();
    final base = relative ? current : Offset.zero;
    switch (command.toUpperCase()) {
      case 'M':
        current = base + Offset(next(), next());
        start = current;
        path.moveTo(current.dx, current.dy);
        // Pairs after a moveto are linetos.
        command = relative ? 'l' : 'L';
        lastControl = null;
      case 'L':
        current = base + Offset(next(), next());
        path.lineTo(current.dx, current.dy);
        lastControl = null;
      case 'H':
        current = Offset((relative ? current.dx : 0) + next(), current.dy);
        path.lineTo(current.dx, current.dy);
        lastControl = null;
      case 'V':
        current = Offset(current.dx, (relative ? current.dy : 0) + next());
        path.lineTo(current.dx, current.dy);
        lastControl = null;
      case 'C':
        final c1 = base + Offset(next(), next());
        final c2 = base + Offset(next(), next());
        current = base + Offset(next(), next());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, current.dx, current.dy);
        lastControl = c2;
      case 'S':
        final c1 = lastControl == null ? current : current * 2 - lastControl;
        final c2 = base + Offset(next(), next());
        current = base + Offset(next(), next());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, current.dx, current.dy);
        lastControl = c2;
      case 'A':
        final rx = next();
        final ry = next();
        final rotation = next();
        final large = flag();
        final sweep = flag();
        current = base + Offset(next(), next());
        path.arcToPoint(
          current,
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: large,
          clockwise: sweep,
        );
        lastControl = null;
      case 'Z':
        path.close();
        current = start;
        lastControl = null;
      default:
        throw FormatException('Unsupported path command $command', d);
    }
  }
  return path;
}

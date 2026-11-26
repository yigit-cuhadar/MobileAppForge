import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../widget/model_viewer_controller.dart';
import 'mesh_renderer.dart';

class ModelPainter extends CustomPainter {
  ModelPainter({
    required this.renderer,
    required this.controller,
    required this.baseColor,
    required this.partColors,
    required this.highlightedPart,
    required this.highlightColor,
    required this.outlinedParts,
    required this.groundParts,
    required this.outlineColor,
    required this.outlineWidth,
    required this.markers,
    required this.markerPoints,
    required this.markerColor,
    required this.markerRadius,
    required this.motionTime,
  }) : super(repaint: Listenable.merge([controller, motionTime]));

  final MeshRenderer renderer;
  final ModelViewerController controller;
  final Color baseColor;
  final Map<String, Color> partColors;
  final String? highlightedPart;
  final Color highlightColor;
  final Set<String> outlinedParts;
  final Set<String> groundParts;
  final Color outlineColor;
  final double outlineWidth;

  /// Model-space x, y, z per marker, as sampled at [motionTime].
  final Float32List markers;

  /// Holds the markers' screen x, y while painting.
  final Float32List markerPoints;

  final Color markerColor;
  final double markerRadius;

  /// Notifies once the motion is sampled at a new time.
  final Listenable motionTime;

  final _paint = Paint();
  late final _markerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = markerColor;
  // Each triangle replaces what is under it, so the mask keeps only what
  // stays visible of the outlined parts.
  final _maskPaint = Paint()..blendMode = BlendMode.src;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final names = renderer.model.partNames;
    for (var i = 0; i < names.length; i++) {
      renderer.groundParts[i] = groundParts.contains(names[i]) ? 1 : 0;
    }
    renderer.update(
      size.width,
      size.height,
      controller.yaw,
      controller.pitch,
      controller.zoom,
    );
    if (renderer.drawIndexCount > 0) {
      final argb = renderer.partColors;
      for (var i = 0; i < names.length; i++) {
        final name = names[i];
        final color = name == highlightedPart
            ? highlightColor
            : partColors[name] ?? baseColor;
        argb[i] = color.toARGB32();
      }
      renderer.shade();
      _draw(canvas, _paint);
      if (outlinedParts.isNotEmpty) _outline(canvas, Offset.zero & size);
    }
    final points = markerPoints;
    renderer.project(markers, points);
    for (var i = 0; i < points.length; i += 2) {
      canvas.drawCircle(
        Offset(points[i], points[i + 1]),
        markerRadius,
        _markerPaint,
      );
    }
  }

  void _draw(Canvas canvas, Paint paint) {
    final vertices = Vertices.raw(
      VertexMode.triangles,
      renderer.screen,
      colors: renderer.colors,
      indices: Uint16List.sublistView(
        renderer.drawIndices,
        0,
        renderer.drawIndexCount,
      ),
    );
    // BlendMode.dst keeps the vertex colours and ignores the paint's.
    canvas.drawVertices(vertices, BlendMode.dst, paint);
    vertices.dispose();
  }

  /// Draws a ring [outlineWidth] wide around what is visible of the
  /// outlined parts: the mask of those pixels grown by the width, minus the
  /// mask itself.
  void _outline(Canvas canvas, Rect bounds) {
    final names = renderer.model.partNames;
    final argb = renderer.partColors;
    final outline = outlineColor.toARGB32();
    for (var i = 0; i < names.length; i++) {
      argb[i] = outlinedParts.contains(names[i]) ? outline : 0;
    }
    renderer.fill();
    canvas.saveLayer(bounds, _paint);
    canvas.saveLayer(
      bounds,
      Paint()
        ..imageFilter = ImageFilter.dilate(
          radiusX: outlineWidth,
          radiusY: outlineWidth,
        ),
    );
    _draw(canvas, _maskPaint);
    canvas.restore();
    canvas.saveLayer(bounds, Paint()..blendMode = BlendMode.dstOut);
    _draw(canvas, _maskPaint);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(ModelPainter oldDelegate) =>
      oldDelegate.renderer != renderer ||
      oldDelegate.controller != controller ||
      oldDelegate.markers != markers ||
      oldDelegate.motionTime != motionTime ||
      oldDelegate.markerColor != markerColor ||
      oldDelegate.markerRadius != markerRadius ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightedPart != highlightedPart ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.outlineWidth != outlineWidth ||
      !mapEquals(oldDelegate.partColors, partColors) ||
      !setEquals(oldDelegate.outlinedParts, outlinedParts) ||
      !setEquals(oldDelegate.groundParts, groundParts);
}

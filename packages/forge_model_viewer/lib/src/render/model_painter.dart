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
    required this.outlineColor,
    required this.outlineWidth,
  }) : super(repaint: controller);

  final MeshRenderer renderer;
  final ModelViewerController controller;
  final Color baseColor;
  final Map<String, Color> partColors;
  final String? highlightedPart;
  final Color highlightColor;
  final Set<String> outlinedParts;
  final Color outlineColor;
  final double outlineWidth;

  final _paint = Paint();
  // Each triangle replaces what is under it, so the mask keeps only what
  // stays visible of the outlined parts.
  final _maskPaint = Paint()..blendMode = BlendMode.src;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    renderer.update(
      size.width,
      size.height,
      controller.yaw,
      controller.pitch,
      controller.zoom,
    );
    if (renderer.drawIndexCount == 0) return;
    final names = renderer.model.partNames;
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
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightedPart != highlightedPart ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.outlineColor != outlineColor ||
      oldDelegate.outlineWidth != outlineWidth ||
      !mapEquals(oldDelegate.partColors, partColors) ||
      !setEquals(oldDelegate.outlinedParts, outlinedParts);
}

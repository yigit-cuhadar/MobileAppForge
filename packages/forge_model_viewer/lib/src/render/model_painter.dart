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
  }) : super(repaint: controller);

  final MeshRenderer renderer;
  final ModelViewerController controller;
  final Color baseColor;
  final Map<String, Color> partColors;
  final String? highlightedPart;
  final Color highlightColor;

  final _paint = Paint();

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
    canvas.drawVertices(vertices, BlendMode.dst, _paint);
    vertices.dispose();
  }

  @override
  bool shouldRepaint(ModelPainter oldDelegate) =>
      oldDelegate.renderer != renderer ||
      oldDelegate.controller != controller ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.highlightedPart != highlightedPart ||
      oldDelegate.highlightColor != highlightColor ||
      !mapEquals(oldDelegate.partColors, partColors);
}

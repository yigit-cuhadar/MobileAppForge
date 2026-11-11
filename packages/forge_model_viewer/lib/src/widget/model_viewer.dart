import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model.dart';
import '../render/mesh_renderer.dart';
import '../render/model_painter.dart';
import 'model_viewer_controller.dart';

/// Shows a [Model3D], lit from the camera, filling its parent.
///
/// When [interactive], one finger rotates, a pinch zooms, a double tap
/// returns to the controller's initial view, a tap reports the part under the
/// finger to [onPartTap], and a long press followed by a slide reports the
/// part under the finger to [onScrub] each time it changes (starting from
/// none) and to [onScrubEnd] on release. Only parts accepted by [selectable]
/// are reported; the others still hide the parts behind them.
///
/// When not [interactive] the viewer takes no gestures at all, for static
/// previews; a [controller] can still move the camera.
class ModelViewer extends StatefulWidget {
  const ModelViewer({
    super.key,
    required this.model,
    this.controller,
    this.baseColor,
    this.partColors = const {},
    this.highlightedPart,
    this.highlightColor,
    this.selectable,
    this.onPartTap,
    this.onScrub,
    this.onScrubEnd,
    this.interactive = true,
    this.semanticLabel,
  });

  final Model3D model;

  /// The camera. When null the viewer keeps its own, starting at the front.
  final ModelViewerController? controller;

  /// Colour of parts missing from [partColors]. Defaults to the theme's
  /// outline colour.
  final Color? baseColor;

  /// Colour per part name.
  final Map<String, Color> partColors;

  /// A part drawn in [highlightColor] instead of its own colour.
  final String? highlightedPart;

  /// Defaults to the theme's primary colour.
  final Color? highlightColor;

  /// Which parts can be tapped or scrubbed. Defaults to all.
  final bool Function(String part)? selectable;

  final ValueChanged<String>? onPartTap;
  final ValueChanged<String?>? onScrub;
  final ValueChanged<String?>? onScrubEnd;
  final bool interactive;

  /// Describes the model to screen readers.
  final String? semanticLabel;

  @override
  State<ModelViewer> createState() => _ModelViewerState();
}

class _ModelViewerState extends State<ModelViewer> {
  late MeshRenderer _renderer = MeshRenderer(widget.model);
  ModelViewerController? _ownController;
  double _scaleStartZoom = 1;
  String? _scrubPart;

  ModelViewerController get _controller =>
      widget.controller ?? (_ownController ??= ModelViewerController());

  @override
  void didUpdateWidget(ModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      _renderer = MeshRenderer(widget.model);
    }
    if (widget.controller != null && _ownController != null) {
      _ownController!.dispose();
      _ownController = null;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  String? _partAt(Offset position) {
    final size = context.size!;
    final controller = _controller;
    _renderer.update(
      size.width,
      size.height,
      controller.yaw,
      controller.pitch,
      controller.zoom,
    );
    return _renderer.pick(
      position.dx,
      position.dy,
      widget.selectable ?? _selectAll,
    );
  }

  static bool _selectAll(String part) => true;

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final controller = _controller;
    if (details.pointerCount > 1) {
      controller.zoom = _scaleStartZoom * details.scale;
      return;
    }
    // Dragging across the shorter side turns the model half way round.
    final radiansPerPixel = math.pi / context.size!.shortestSide;
    controller
      ..yaw += details.focalPointDelta.dx * radiansPerPixel
      ..pitch += details.focalPointDelta.dy * radiansPerPixel;
  }

  void _scrubTo(Offset position) {
    final part = _partAt(position);
    if (part == _scrubPart) return;
    _scrubPart = part;
    widget.onScrub?.call(part);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget viewer = RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: ModelPainter(
          renderer: _renderer,
          controller: _controller,
          baseColor: widget.baseColor ?? colors.outline,
          partColors: widget.partColors,
          highlightedPart: widget.highlightedPart,
          highlightColor: widget.highlightColor ?? colors.primary,
        ),
      ),
    );
    if (widget.interactive) {
      final scrubs = widget.onScrub != null || widget.onScrubEnd != null;
      viewer = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (_) => _scaleStartZoom = _controller.zoom,
        onScaleUpdate: _onScaleUpdate,
        onDoubleTap: () => _controller.animateTo(
          _controller.initialYaw,
          _controller.initialPitch,
          _controller.initialZoom,
        ),
        onTapUp: widget.onPartTap == null
            ? null
            : (details) {
                final part = _partAt(details.localPosition);
                if (part != null) widget.onPartTap!(part);
              },
        onLongPressStart: scrubs
            ? (details) {
                _scrubPart = null;
                _scrubTo(details.localPosition);
              }
            : null,
        onLongPressMoveUpdate: scrubs
            ? (details) => _scrubTo(details.localPosition)
            : null,
        onLongPressEnd: scrubs
            ? (_) => widget.onScrubEnd?.call(_scrubPart)
            : null,
        child: viewer,
      );
    }
    if (widget.semanticLabel == null) return viewer;
    return Semantics(label: widget.semanticLabel, image: true, child: viewer);
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../model.dart';
import '../render/mesh_renderer.dart';
import '../render/model_painter.dart';
import 'model_viewer_controller.dart';
import 'viewer_gesture_recognizer.dart';

/// Shows a [Model3D], lit from the camera, filling its parent.
///
/// When [interactive], gestures that start on the viewer belong to it, even
/// inside a scrollable: one finger rotates, a pinch zooms, a tap reports the
/// part under the finger to [onPartTap] on release, and a long press followed
/// by a slide reports the part under the finger to [onScrub] each time it
/// changes (starting from none) and, exactly once, to [onScrubEnd] when the
/// scrub ends: with the part under the finger on release, with null when the
/// scrub was interrupted. Only parts accepted by [selectable] are
/// reported; the others still hide the parts behind them.
///
/// Screen readers get only [semanticLabel]; apps that let users pick parts
/// should also offer them as a list.
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
  late MeshRenderer _renderer = MeshRenderer(meshOf(widget.model));
  ModelViewerController? _ownController;
  double _pinchStartZoom = 1;
  bool _scrubbing = false;
  String? _scrubPart;

  ModelViewerController get _controller =>
      widget.controller ?? (_ownController ??= ModelViewerController());

  bool get _scrubs => widget.onScrub != null || widget.onScrubEnd != null;

  @override
  void didUpdateWidget(ModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      _renderer = MeshRenderer(meshOf(widget.model));
    }
    if (widget.controller != null && _ownController != null) {
      _ownController!.dispose();
      _ownController = null;
    }
    if (!widget.interactive || !_scrubs) {
      _endScrub(
        widget.onScrubEnd ?? oldWidget.onScrubEnd,
        deferred: true,
        cancelled: true,
      );
    }
  }

  @override
  void dispose() {
    _endScrub(widget.onScrubEnd, deferred: true, cancelled: true);
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

  void _onTap(Offset position) {
    final onPartTap = widget.onPartTap;
    if (onPartTap == null) return;
    final part = _partAt(position);
    if (part != null) onPartTap(part);
  }

  void _onRotate(Offset delta) {
    // Dragging across the shorter side turns the model half way round.
    final radiansPerPixel = math.pi / context.size!.shortestSide;
    _controller
      ..yaw += delta.dx * radiansPerPixel
      ..pitch += delta.dy * radiansPerPixel;
  }

  void _onScrubStart(Offset position) {
    if (!_scrubs) return;
    _scrubbing = true;
    _scrubPart = null;
    _onScrubUpdate(position);
  }

  void _onScrubUpdate(Offset position) {
    if (!_scrubbing) return;
    final part = _partAt(position);
    if (part == _scrubPart) return;
    _scrubPart = part;
    widget.onScrub?.call(part);
  }

  /// Ends a running scrub. [deferred] delays the callback past the current
  /// build or unmount, where the app could not call setState. A [cancelled]
  /// scrub reports no part, so apps do not act on an interrupted gesture.
  void _endScrub(
    ValueChanged<String?>? onScrubEnd, {
    bool deferred = false,
    bool cancelled = false,
  }) {
    if (!_scrubbing) return;
    _scrubbing = false;
    final part = cancelled ? null : _scrubPart;
    _scrubPart = null;
    if (onScrubEnd == null) return;
    if (deferred) {
      scheduleMicrotask(() => onScrubEnd(part));
    } else {
      onScrubEnd(part);
    }
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
      final scrubs = _scrubs;
      viewer = RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        gestures: {
          ViewerGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ViewerGestureRecognizer>(
                () => ViewerGestureRecognizer(debugOwner: this),
                (recognizer) => recognizer
                  ..onTap = _onTap
                  ..onRotate = _onRotate
                  ..onZoomStart = (() => _pinchStartZoom = _controller.zoom)
                  ..onZoom = ((scale) =>
                      _controller.zoom = _pinchStartZoom * scale)
                  ..onScrubStart = scrubs ? _onScrubStart : null
                  ..onScrubUpdate = _onScrubUpdate
                  ..onScrubEnd = (() => _endScrub(widget.onScrubEnd))
                  ..onScrubCancel = (() =>
                      _endScrub(widget.onScrubEnd, cancelled: true)),
              ),
        },
        child: viewer,
      );
    }
    if (widget.semanticLabel == null) return viewer;
    return Semantics(label: widget.semanticLabel, image: true, child: viewer);
  }
}

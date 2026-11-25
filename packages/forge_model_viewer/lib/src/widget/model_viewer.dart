import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

import '../clip.dart';
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
///
/// With [autoTurn] the model turns slowly round its vertical axis, one turn
/// in [turnPeriod]: it holds still while a finger is on the viewer, while
/// the viewer's tickers are muted (a covered route, a hidden tab) and when
/// the platform asks for reduced motion. It moves the [controller]'s yaw, so
/// it cuts short a running `animateTo`.
///
/// With a [clip] the model plays it in a loop, framed by the clip's bounds.
/// It pauses while the viewer's tickers are muted and holds the first frame
/// when the platform asks for reduced motion.
class ModelViewer extends StatefulWidget {
  const ModelViewer({
    super.key,
    required this.model,
    this.controller,
    this.baseColor,
    this.partColors = const {},
    this.highlightedPart,
    this.highlightColor,
    this.outlinedParts = const {},
    this.outlineColor,
    this.outlineWidth = 2,
    this.selectable,
    this.onPartTap,
    this.onScrub,
    this.onScrubEnd,
    this.interactive = true,
    this.autoTurn = false,
    this.clip,
    this.semanticLabel,
  });

  /// How long one full [autoTurn] takes.
  static const turnPeriod = Duration(seconds: 20);

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

  /// Parts ringed by an [outlineColor] line [outlineWidth] wide around what
  /// is visible of them, over their own colour.
  final Set<String> outlinedParts;

  /// Defaults to the theme's error colour.
  final Color? outlineColor;

  /// In logical pixels.
  final double outlineWidth;

  /// Which parts can be tapped or scrubbed. Defaults to all.
  final bool Function(String part)? selectable;

  final ValueChanged<String>? onPartTap;
  final ValueChanged<String?>? onScrub;
  final ValueChanged<String?>? onScrubEnd;
  final bool interactive;
  final bool autoTurn;

  /// Animates a skinned [model]; must have its [Model3D.jointCount].
  final ModelClip? clip;

  /// Describes the model to screen readers.
  final String? semanticLabel;

  @override
  State<ModelViewer> createState() => _ModelViewerState();
}

class _ModelViewerState extends State<ModelViewer>
    with TickerProviderStateMixin {
  late MeshRenderer _renderer;
  late Float32List _pose;
  late final Ticker _turn = createTicker(_onTurn);
  late final Ticker _play = createTicker(_onPlay);
  Duration _turnedTo = Duration.zero;
  Duration _playedTo = Duration.zero;
  final _clipTime = ValueNotifier(Duration.zero);
  int _pointers = 0;
  ModelViewerController? _ownController;
  double _pinchStartZoom = 1;
  bool _scrubbing = false;
  String? _scrubPart;

  ModelViewerController get _controller =>
      widget.controller ?? (_ownController ??= ModelViewerController());

  bool get _scrubs => widget.onScrub != null || widget.onScrubEnd != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTickers();
  }

  @override
  void didUpdateWidget(ModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model || widget.clip != oldWidget.clip) {
      _load();
    }
    _syncTickers();
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
    _turn.dispose();
    _play.dispose();
    _clipTime.dispose();
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

  void _load() {
    final clip = widget.clip;
    assert(
      clip == null || clip.jointCount == widget.model.jointCount,
      'The clip moves ${clip.jointCount} joints, '
      'the model has ${widget.model.jointCount}',
    );
    _renderer = MeshRenderer(
      meshOf(widget.model),
      bounds: clip == null ? null : boundsOf(clip),
    );
    _pose = Float32List((clip?.jointCount ?? 0) * 12);
    _clipTime.value = Duration.zero;
  }

  void _syncTickers() {
    // iOS reports Reduce Motion apart from disableAnimations.
    final moves =
        !MediaQuery.disableAnimationsOf(context) &&
        !View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;
    if (!widget.interactive) _pointers = 0;
    final turns = widget.autoTurn && moves;
    if (turns != _turn.isActive) {
      if (turns) {
        _turnedTo = Duration.zero;
        _turn.start();
      } else {
        _turn.stop();
      }
    }
    final plays = widget.clip != null && moves;
    if (plays != _play.isActive) {
      if (plays) {
        _playedTo = Duration.zero;
        _play.start();
      } else {
        _play.stop();
        _clipTime.value = Duration.zero;
      }
    }
  }

  void _onTurn(Duration elapsed) {
    // A muted ticker keeps counting; resume from where the model stood.
    final step = elapsed - _turnedTo;
    _turnedTo = elapsed;
    if (_pointers > 0 || step > const Duration(milliseconds: 100)) return;
    _controller.yaw +=
        2 *
        math.pi *
        step.inMicroseconds /
        ModelViewer.turnPeriod.inMicroseconds;
  }

  void _onPlay(Duration elapsed) {
    // A muted ticker keeps counting; resume from where the clip stood.
    final step = elapsed - _playedTo;
    _playedTo = elapsed;
    if (step > const Duration(milliseconds: 100)) return;
    _clipTime.value += step;
  }

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
          outlinedParts: widget.outlinedParts,
          outlineColor: widget.outlineColor ?? colors.error,
          outlineWidth: widget.outlineWidth,
          clip: widget.clip,
          clipTime: _clipTime,
          pose: _pose,
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
      // Fingers on the viewer hold an auto turn.
      viewer = Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        onPointerCancel: (_) => _pointers--,
        child: viewer,
      );
    }
    if (widget.semanticLabel == null) return viewer;
    return Semantics(label: widget.semanticLabel, image: true, child: viewer);
  }
}

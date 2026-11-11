import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// The camera of a `ModelViewer`: [yaw] and [pitch] in radians, [zoom] as a
/// scale where 1 fits the whole model in the view.
///
/// Yaw is free; pitch is clamped to ±[maxPitch] and zoom to
/// [minZoom]..[maxZoom]. The values given to the constructor are the view
/// that [reset] and a double tap return to.
class ModelViewerController extends ChangeNotifier {
  ModelViewerController({
    double yaw = 0,
    double pitch = 0,
    double zoom = 1,
    this.minZoom = 1,
    this.maxZoom = 4,
    this.maxPitch = math.pi * 0.45,
  }) : assert(0 < minZoom && minZoom <= maxZoom),
       initialYaw = yaw,
       initialPitch = pitch.clamp(-maxPitch, maxPitch),
       initialZoom = zoom.clamp(minZoom, maxZoom) {
    _yaw = initialYaw;
    _pitch = initialPitch;
    _zoom = initialZoom;
  }

  static const _animationDuration = Duration(milliseconds: 350);

  final double minZoom;
  final double maxZoom;
  final double maxPitch;
  final double initialYaw;
  final double initialPitch;
  final double initialZoom;

  late double _yaw, _pitch, _zoom;
  Ticker? _ticker;
  Completer<void>? _animation;

  double get yaw => _yaw;
  double get pitch => _pitch;
  double get zoom => _zoom;

  set yaw(double value) => _jumpTo(value, _pitch, _zoom);
  set pitch(double value) => _jumpTo(_yaw, value, _zoom);
  set zoom(double value) => _jumpTo(_yaw, _pitch, value);

  void _jumpTo(double yaw, double pitch, double zoom) {
    _stopAnimation();
    _set(yaw, pitch, zoom);
  }

  /// Returns to the initial view at once.
  void reset() => _jumpTo(initialYaw, initialPitch, initialZoom);

  /// Animates to the given view, turning the shorter way round in yaw. The
  /// future completes when the animation ends or is interrupted.
  Future<void> animateTo(double yaw, double pitch, double zoom) {
    _stopAnimation();
    final fromYaw = _yaw, fromPitch = _pitch, fromZoom = _zoom;
    final turn = (yaw - fromYaw + math.pi) % (2 * math.pi) - math.pi;
    final toPitch = pitch.clamp(-maxPitch, maxPitch);
    final toZoom = zoom.clamp(minZoom, maxZoom);
    final animation = _animation = Completer<void>();
    final ticker = _ticker = Ticker((elapsed) {
      final t = math.min(
        1.0,
        elapsed.inMicroseconds / _animationDuration.inMicroseconds,
      );
      final e = Curves.easeInOut.transform(t);
      _set(
        t == 1 ? yaw : fromYaw + turn * e,
        fromPitch + (toPitch - fromPitch) * e,
        fromZoom + (toZoom - fromZoom) * e,
      );
      if (t == 1) _stopAnimation();
    });
    unawaited(ticker.start());
    return animation.future;
  }

  void _set(double yaw, double pitch, double zoom) {
    final p = pitch.clamp(-maxPitch, maxPitch);
    final z = zoom.clamp(minZoom, maxZoom);
    if (yaw == _yaw && p == _pitch && z == _zoom) return;
    _yaw = yaw;
    _pitch = p;
    _zoom = z;
    notifyListeners();
  }

  void _stopAnimation() {
    _ticker?.dispose();
    _ticker = null;
    _animation?.complete();
    _animation = null;
  }

  @override
  void dispose() {
    _stopAnimation();
    super.dispose();
  }
}

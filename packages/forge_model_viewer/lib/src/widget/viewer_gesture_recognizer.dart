import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

enum _Mode { idle, pending, rotating, pinching, scrubbing, done }

/// One recognizer for every viewer gesture, so they cannot compete with each
/// other or lose to an enclosing scrollable: it claims each pointer as soon
/// as it goes down.
///
/// One finger: up before moving [kTouchSlop] is a tap (reported at once),
/// moving further rotates, holding still for [kLongPressTimeout] starts a
/// scrub that follows the finger until it lifts. A second finger before the
/// scrub starts turns the gesture into a pinch.
class ViewerGestureRecognizer extends OneSequenceGestureRecognizer {
  ViewerGestureRecognizer({super.debugOwner});

  ValueChanged<Offset>? onTap;
  ValueChanged<Offset>? onRotate;
  VoidCallback? onZoomStart;
  ValueChanged<double>? onZoom;

  /// Null disables scrubbing; holding still then does nothing.
  ValueChanged<Offset>? onScrubStart;
  ValueChanged<Offset>? onScrubUpdate;
  VoidCallback? onScrubEnd;

  /// The scrub was interrupted rather than released.
  VoidCallback? onScrubCancel;

  var _mode = _Mode.idle;
  final _positions = <int, Offset>{};
  int _primary = 0;
  Offset _primaryLocal = Offset.zero;
  Offset _last = Offset.zero;
  double _pinchStartDistance = 1;
  Timer? _longPress;

  @override
  String get debugDescription => 'model viewer';

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolvePointer(event.pointer, GestureDisposition.accepted);
    _positions[event.pointer] = event.position;
    switch (_mode) {
      case _Mode.idle:
        _mode = _Mode.pending;
        _primary = event.pointer;
        _primaryLocal = event.localPosition;
        _last = event.position;
        if (onScrubStart != null) {
          _longPress = Timer(kLongPressTimeout, _startScrub);
        }
      case _Mode.pending || _Mode.rotating:
        _startPinch();
      case _Mode.pinching || _Mode.scrubbing || _Mode.done:
        break;
    }
  }

  void _startScrub() {
    _longPress = null;
    if (_mode != _Mode.pending) return;
    _mode = _Mode.scrubbing;
    onScrubStart?.call(_primaryLocal);
  }

  void _startPinch() {
    _cancelLongPress();
    _mode = _Mode.pinching;
    _pinchStartDistance = _pinchDistance();
    onZoomStart?.call();
  }

  double _pinchDistance() {
    final points = _positions.values.take(2).toList();
    final distance = (points[0] - points[1]).distance;
    return distance > 0 ? distance : 1;
  }

  @override
  void handleEvent(PointerEvent event) {
    final pointer = event.pointer;
    if (event is PointerMoveEvent) {
      _positions[pointer] = event.position;
      if (pointer == _primary) _primaryLocal = event.localPosition;
      switch (_mode) {
        case _Mode.pending when pointer == _primary:
          if ((event.position - _last).distance > kTouchSlop) {
            _cancelLongPress();
            _mode = _Mode.rotating;
            _last = event.position;
          }
        case _Mode.rotating when pointer == _primary:
          onRotate?.call(event.position - _last);
          _last = event.position;
        case _Mode.scrubbing when pointer == _primary:
          onScrubUpdate?.call(event.localPosition);
        case _Mode.pinching:
          onZoom?.call(_pinchDistance() / _pinchStartDistance);
        default:
          break;
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _positions.remove(pointer);
      if (pointer == _primary) {
        if (_mode == _Mode.pending && event is PointerUpEvent) {
          _mode = _Mode.done;
          onTap?.call(_primaryLocal);
        } else if (_mode == _Mode.scrubbing) {
          _mode = _Mode.done;
          (event is PointerUpEvent ? onScrubEnd : onScrubCancel)?.call();
        }
      }
      if (_mode == _Mode.pinching && _positions.length == 1) {
        // The finger left on the screen carries on rotating.
        _mode = _Mode.rotating;
        _primary = _positions.keys.single;
        _last = _positions.values.single;
      }
      stopTrackingPointer(pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    // Only happens when another recognizer won the arena eagerly first.
    _positions.remove(pointer);
    if (pointer == _primary && _mode == _Mode.scrubbing) onScrubCancel?.call();
    if (pointer == _primary) _mode = _Mode.done;
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _cancelLongPress();
    _positions.clear();
    _mode = _Mode.idle;
  }

  void _cancelLongPress() {
    _longPress?.cancel();
    _longPress = null;
  }

  @override
  void dispose() {
    _cancelLongPress();
    super.dispose();
  }
}

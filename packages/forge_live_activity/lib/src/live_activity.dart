import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:forge_core/forge_core.dart';

/// A button on the Live Activity pressed without opening the app. The app
/// may have been woken for it alone and be put back to sleep once it is
/// answered, so [handled] is called once it is applied and what follows
/// from it is done (at most [LiveActivity.pressWait] is waited for).
final class LiveActivityPress {
  LiveActivityPress(this.action, {this._onHandled});

  /// The app's name for the button, as its intent passes it.
  final String action;
  final void Function()? _onHandled;

  void handled() => _onHandled?.call();
}

/// The app's one Live Activity on iOS 16.2+; below that nothing shows and
/// nothing fails. Only for iOS: there is no other platform side.
class LiveActivity {
  const LiveActivity();

  static const _channel = MethodChannel('forge_live_activity');
  static const _presses = MethodChannel('forge_live_activity/presses');

  /// How long a press is waited for before it is answered anyway.
  static const pressWait = Duration(seconds: 5);

  /// Starts the activity or updates the one running with [content], which
  /// the extension decodes as JSON (dates as milliseconds since the
  /// epoch). From [staleAt] on the activity is stale, so the extension can
  /// draw it differently by itself while the app does not run. Fails with
  /// Live Activities turned off, or while the app may not start one (not
  /// in front), so it is worth trying again.
  Future<Result<void>> show(
    Map<String, Object?> content, {
    DateTime? staleAt,
  }) => guard(() async {
    final shown = await _channel.invokeMethod<bool>('show', {
      'json': jsonEncode(content),
      'staleAt': staleAt?.millisecondsSinceEpoch,
    });
    if (shown == false) {
      throw const UnknownFailure('Live Activity not shown: turned off');
    }
  });

  /// Removes the activity, if any.
  Future<Result<void>> end() => guard(() => _channel.invokeMethod<void>('end'));

  /// Taps that open the app through the activity's widgetURL, including
  /// the one that launched it; for one listener. The plugin keeps a tap
  /// until it is taken: taken when listening starts and whenever the
  /// plugin says one came.
  Stream<void> taps() {
    late final StreamController<void> controller;
    Future<void> take() async {
      try {
        if (await _channel.invokeMethod<bool>('takeTap') ?? false) {
          controller.add(null);
        }
      } on PlatformException catch (error) {
        Log.e('live_activity', 'Tap not taken: ${error.message}');
      }
    }

    controller = StreamController(
      onListen: () {
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'tapped') await take();
        });
        unawaited(take());
      },
      onCancel: () => _channel.setMethodCallHandler(null),
    );
    return controller.stream;
  }

  /// Its buttons pressed, including those pressed while the app did not
  /// run or before this listened (taken when listening starts); for one
  /// listener.
  Stream<LiveActivityPress> presses() {
    late final StreamController<LiveActivityPress> controller;
    Future<void> takeKept() async {
      try {
        final kept = await _presses.invokeListMethod<String>('takePresses');
        for (final action in kept ?? const <String>[]) {
          controller.add(LiveActivityPress(action));
        }
      } on PlatformException catch (error) {
        Log.e('live_activity', 'Presses not taken: ${error.message}');
      }
    }

    controller = StreamController(
      onListen: () {
        _presses.setMethodCallHandler((call) async {
          if (call.method != 'press') return;
          final action = call.arguments;
          if (action is! String) return;
          final handled = Completer<void>();
          controller.add(
            LiveActivityPress(
              action,
              onHandled: () {
                if (!handled.isCompleted) handled.complete();
              },
            ),
          );
          await handled.future.timeout(pressWait, onTimeout: () {});
        });
        unawaited(takeKept());
      },
      onCancel: () => _presses.setMethodCallHandler(null),
    );
    return controller.stream;
  }
}

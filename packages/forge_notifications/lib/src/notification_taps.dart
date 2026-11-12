import 'dart:async';

/// Taps on the app's notifications, as their payloads exactly as reported
/// (null for a notification without one), for one listener at a time.
///
/// A new listener replaces the previous one, whose stream then ends. Taps
/// that arrive while nobody listens, such as the one that launched the
/// app, wait for the next listener.
///
/// Pass [add] as `onTap` to `Notifications.init`; other sources, such as
/// pushed messages, add theirs too.
final class NotificationTaps {
  final _waiting = <String?>[];
  MultiStreamController<String?>? _listener;

  void add(String? payload) {
    final listener = _listener;
    if (listener == null) {
      _waiting.add(payload);
    } else {
      listener.add(payload);
    }
  }

  late final Stream<String?> stream = Stream.multi((listener) {
    _listener?.close();
    _listener = listener;
    _waiting
      ..forEach(listener.add)
      ..clear();
    listener.onCancel = () {
      if (identical(_listener, listener)) _listener = null;
    };
  });
}

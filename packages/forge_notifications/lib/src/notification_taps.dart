import 'dart:async';

/// Taps on the app's notifications, as their payloads, for one listener.
/// Taps added before it listens, such as the one that launched the app,
/// wait for it.
///
/// Pass [add] as `onTap` to `Notifications.init`; other sources, such as
/// pushed messages, add theirs too.
final class NotificationTaps {
  final _taps = StreamController<String?>();

  void add(String? payload) => _taps.add(payload);

  /// Can be listened to once.
  Stream<String?> get stream => _taps.stream;
}

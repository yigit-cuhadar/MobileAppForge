import 'package:forge_core/forge_core.dart';

import 'schedule.dart';

/// Whether the app may show notifications.
///
/// Neither platform reports "not asked yet" through the plugin, so an app
/// that was never asked reads as [denied].
enum NotificationPermission {
  granted,
  denied,

  /// iOS only: delivered quietly to the notification centre.
  provisional,
}

/// A scheduled notification that has not fired yet.
final class PendingNotification extends Equatable {
  const PendingNotification(this.id, this.payload);

  final int id;
  final String? payload;

  @override
  List<Object?> get props => [id, payload];
}

/// Local notifications scheduled on the device. Every method returns a
/// [Result]; invalid arguments give a [ValidationFailure].
///
/// Scheduling an id that is already scheduled or shown replaces it.
abstract interface class Notifications {
  /// Prepares the plugin and the local time zone. Call once, before anything
  /// else. [onTap] receives the payload of every tapped notification,
  /// including the one that launched the app, which is reported during this
  /// call.
  Future<Result<void>> init({void Function(String? payload)? onTap});

  Future<Result<NotificationPermission>> status();

  /// Asks the user (iOS; Android 13+), then returns the outcome.
  Future<Result<NotificationPermission>> request();

  /// Whether alarms fire at the exact time. False on Android 12+ until the
  /// user allows exact alarms; schedules then fire within a few minutes.
  Future<Result<bool>> canScheduleExact();

  /// Opens the Android exact-alarm setting and returns whether it was
  /// granted. Always true on iOS.
  Future<Result<bool>> requestExact();

  Future<Result<void>> show(
    int id, {
    required String title,
    required String body,
    String? payload,
  });

  /// Shows once at [when], which must be in the future.
  Future<Result<void>> scheduleAt(
    int id,
    DateTime when, {
    required String title,
    required String body,
    String? payload,
  });

  /// Shows once after [delay], which must be positive.
  Future<Result<void>> scheduleIn(
    int id,
    Duration delay, {
    required String title,
    required String body,
    String? payload,
  });

  /// Shows every [weekday] (ISO, 1 = Monday) at [time] local wall-clock time.
  Future<Result<void>> scheduleWeekly(
    int id, {
    required int weekday,
    required ClockTime time,
    required String title,
    required String body,
    String? payload,
  });

  /// Shows every [weeks] weeks at [first]'s local wall-clock time, starting
  /// at [first], which may lie in the past.
  ///
  /// The series owns ids [baseId] to `baseId + seriesLength - 1` and keeps
  /// only the next [seriesLength] occurrences scheduled: call this again with
  /// the same arguments (e.g. on every app start) to top it up.
  Future<Result<void>> scheduleEvery(
    int baseId, {
    required DateTime first,
    required int weeks,
    required String title,
    required String body,
    String? payload,
  });

  /// Cancels the scheduled or shown notification [id].
  Future<Result<void>> cancel(int id);

  /// Cancels every occurrence of the series at [baseId].
  Future<Result<void>> cancelEvery(int baseId);

  Future<Result<void>> cancelAll();

  Future<Result<List<PendingNotification>>> pending();
}

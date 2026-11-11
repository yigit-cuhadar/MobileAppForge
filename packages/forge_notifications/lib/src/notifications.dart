import 'package:forge_core/forge_core.dart';

import 'schedule.dart';

/// Whether the app may show notifications.
///
/// Neither platform reports "not asked yet" through the plugin, so an app
/// that was never asked reads as [denied].
enum NotificationPermission { granted, denied }

/// A scheduled notification that has not fired yet.
final class PendingNotification extends Equatable {
  const PendingNotification(this.id, this.payload);

  final int id;
  final String? payload;

  @override
  List<Object?> get props => [id, payload];
}

/// The device time zone that wall-clock schedules follow.
final class LocalTimeZone extends Equatable {
  const LocalTimeZone(this.id, {required this.known, required this.changed});

  /// The IANA id the device reports.
  final String id;

  /// False when the time zone database does not know [id]; wall-clock
  /// schedules then follow UTC.
  final bool known;

  /// Whether the zone in use differs from the one before the call. Always
  /// true from the first `init`.
  final bool changed;

  @override
  List<Object?> get props => [id, known, changed];
}

/// Local notifications scheduled on the device. Every method returns a
/// [Result]; invalid arguments give a [ValidationFailure], and any call
/// before [init] an [UnknownFailure].
///
/// Scheduling an id that is already pending replaces it. iOS keeps at most
/// [iosPendingLimit] pending notifications per app, so a schedule that would
/// exceed it fails with a [ValidationFailure]; Android has no such check, but
/// some devices (Samsung) cap an app at 500 alarms.
///
/// Repeating schedules can be lost (reboot on some devices, exact-alarm
/// permission revoked, time zone change), so apps re-apply them at every app
/// start and when [refreshTimeZone] reports a change; re-applying is
/// idempotent.
abstract interface class Notifications {
  /// Prepares the plugin and the local time zone; call before anything else.
  /// [onTap] receives the payload of every tapped notification, including the
  /// one that launched the app, which is reported once, during the first
  /// call.
  Future<Result<LocalTimeZone>> init({void Function(String? payload)? onTap});

  /// Re-reads the device time zone. Call on app resume; when it changed,
  /// re-apply repeating schedules.
  Future<Result<LocalTimeZone>> refreshTimeZone();

  Future<Result<NotificationPermission>> status();

  /// Asks the user (iOS; Android 13+), then returns the outcome.
  Future<Result<NotificationPermission>> request();

  /// Whether alarms fire at the exact time. False on Android 12+ until the
  /// user allows exact alarms (denied by default from Android 14). Without
  /// it, a notification may fire up to 75 % of its lead time late, at most
  /// one hour: too late for short timers.
  Future<Result<bool>> canScheduleExact();

  /// Opens the Android exact-alarm setting and returns whether it was
  /// granted. Always true on iOS. See [canScheduleExact].
  Future<Result<bool>> requestExact();

  Future<Result<void>> show(
    int id, {
    required String title,
    required String body,
    String? payload,
  });

  /// Shows once at [when], rounded up to a whole second, which must be in
  /// the future.
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
  /// Re-apply at every app start (see [Notifications]).
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
  /// at most the next [seriesLength] occurrences pending, all of which count
  /// against the iOS limit. Re-apply with the same arguments at every app
  /// start to top it up; notifications already on screen stay. If a platform
  /// call fails partway, the failure names the ids that were scheduled.
  Future<Result<void>> scheduleEvery(
    int baseId, {
    required DateTime first,
    required int weeks,
    required String title,
    required String body,
    String? payload,
  });

  /// Cancels the pending or shown notification [id].
  Future<Result<void>> cancel(int id);

  /// Cancels every pending or shown notification of the series at [baseId].
  Future<Result<void>> cancelEvery(int baseId);

  Future<Result<void>> cancelAll();

  Future<Result<List<PendingNotification>>> pending();
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show Importance;
import 'package:forge_core/forge_core.dart';

import 'schedule.dart';

/// An Android notification channel: the one every notification is posted
/// to, or the ongoing ones' own (`Notifications.showCountdown`,
/// `Notifications.showStopwatch`).
final class NotificationChannel {
  const NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
  });

  final String id;

  /// Shown to the user in the system notification settings.
  final String name;
  final String description;
  final Importance importance;
}

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

/// A notification shown once at [at], as `Notifications.sync` wants it.
final class OneOffNotification extends Equatable {
  const OneOffNotification(
    this.id,
    this.at, {
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String? payload;

  @override
  List<Object?> get props => [id, at, title, body, payload];
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
  /// Prepares the plugin and the local time zone, and creates (or renames)
  /// the app's Android channels, so pushed messages naming one find it
  /// before any local notification was shown; needs no permission. Call
  /// before anything else.
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

  /// Opens the system settings of the app's notifications; fails when the
  /// platform could not open them.
  Future<Result<void>> openSettings();

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

  /// Makes the pending notifications with ids [baseId] to
  /// `baseId + count - 1` exactly [wanted]: cancels the other pending ones
  /// of the range and those that differ, then schedules what is missing or
  /// differs (as [scheduleAt]), earliest first, and leaves equal ones alone.
  /// Notifications already on screen stay. Calls run one after another.
  ///
  /// An empty or 32-bit-overflowing range, or [wanted] ids that repeat or
  /// lie outside it, fail with a [ValidationFailure] and change nothing.
  /// Otherwise every change is tried and, if any fails, the last failure is
  /// returned: a notification in the past is not scheduled (its pending
  /// predecessor is still cancelled), and on iOS those that would take the
  /// pending ones past [iosPendingLimit] are left out, latest first.
  ///
  /// Equal ones are recognised by a signature of time, alarm mode (exact or
  /// not), text and payload, appended to the stored payload; taps and
  /// [pending] never see it. Re-applying after the exact-alarm permission
  /// changes therefore reschedules them.
  Future<Result<void>> sync(
    int baseId, {
    required int count,
    required List<OneOffNotification> wanted,
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

  /// Android only (an [UnknownFailure] elsewhere; iOS shows countdowns as
  /// Live Activities), and only with a countdown channel configured: shows,
  /// or replaces in place, an ongoing silent notification [id] whose system
  /// chronometer counts down to [endsAt] without the app running, and which
  /// the system removes at [endsAt]. [endsAt] must be in the future.
  ///
  /// The countdown channel is created without sound or vibration; at
  /// [Importance.defaultImportance] it shows on the lock screen, while lower
  /// ones count as silent, which Android may hide there.
  /// On Android 16 it asks to be promoted to a Live Update (status bar chip),
  /// which needs `android.permission.POST_PROMOTED_NOTIFICATIONS` in the
  /// app's manifest. From Android 14 the user can swipe it away while the
  /// device is unlocked. It needs the notification permission like any
  /// other notification.
  Future<Result<void>> showCountdown(
    int id, {
    required DateTime endsAt,
    required String title,
    String? body,
    String? payload,
  });

  /// Like [showCountdown], but the chronometer counts up from [since], e.g.
  /// the time a workout has run, and the notification stays until
  /// cancelled.
  Future<Result<void>> showStopwatch(
    int id, {
    required DateTime since,
    required String title,
    String? body,
    String? payload,
  });

  /// [showStopwatch] at [at], rounded up to a whole second, which must be in
  /// the future: exactly when the device allows exact alarms, else possibly
  /// late (see [canScheduleExact]). Scheduling [id] again replaces the
  /// pending one; [cancel] removes it. E.g. scheduled at a countdown's end,
  /// it follows the countdown that the system removes then, even with the
  /// app suspended; under another id, as a notification replaced at the
  /// moment the countdown times out could be removed with it.
  Future<Result<void>> scheduleStopwatch(
    int id,
    DateTime at, {
    required DateTime since,
    required String title,
    String? body,
    String? payload,
  });

  /// Cancels the pending or shown notification [id].
  Future<Result<void>> cancel(int id);

  /// Cancels every pending or shown notification of the series at [baseId].
  Future<Result<void>> cancelEvery(int baseId);

  Future<Result<void>> cancelAll();

  Future<Result<List<PendingNotification>>> pending();
}

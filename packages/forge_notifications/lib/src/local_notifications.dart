import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:forge_core/forge_core.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notifications.dart';
import 'schedule.dart';

/// The Android notification channel every notification is posted to.
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

/// [Notifications] over `flutter_local_notifications`.
class LocalNotifications implements Notifications {
  /// [androidIcon] is the drawable resource name of the small icon, e.g.
  /// `ic_notification` for `res/drawable/ic_notification.png`.
  LocalNotifications({required this.channel, required this.androidIcon});

  final NotificationChannel channel;
  final String androidIcon;

  final _plugin = FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  tz.TZDateTime get _now => tz.TZDateTime.from(clock.now(), tz.local);

  @override
  Future<Result<void>> init({void Function(String? payload)? onTap}) =>
      _guard(() async {
        tzdata.initializeTimeZones();
        final zone = (await FlutterTimezone.getLocalTimezone()).identifier;
        try {
          tz.setLocalLocation(tz.getLocation(zone));
        } on tz.LocationNotFoundException catch (error, stack) {
          // Absolute schedules stay right; wall-clock ones follow UTC.
          Log.e('notifications', 'Unknown time zone $zone', error, stack);
        }
        await _plugin.initialize(
          settings: InitializationSettings(
            android: AndroidInitializationSettings(androidIcon),
            iOS: const DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
          onDidReceiveNotificationResponse: onTap == null
              ? null
              : (response) => onTap(_payload(response.payload)),
        );
        final launch = await _plugin.getNotificationAppLaunchDetails();
        if (onTap != null && (launch?.didNotificationLaunchApp ?? false)) {
          onTap(_payload(launch!.notificationResponse?.payload));
        }
      });

  @override
  Future<Result<NotificationPermission>> status() => _guard(() async {
    final android = _android;
    if (android != null) {
      return _permission(await android.areNotificationsEnabled());
    }
    final options = await _requireIos().checkPermissions();
    if (options?.isProvisionalEnabled ?? false) {
      return NotificationPermission.provisional;
    }
    return _permission(options?.isEnabled);
  });

  @override
  Future<Result<NotificationPermission>> request() => _guard(() async {
    final android = _android;
    if (android != null) {
      return _permission(await android.requestNotificationsPermission());
    }
    return _permission(
      await _requireIos().requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ),
    );
  });

  @override
  Future<Result<bool>> canScheduleExact() => _guard(_canScheduleExact);

  @override
  Future<Result<bool>> requestExact() => _guard(() async {
    final android = _android;
    if (android == null) return true;
    return await android.requestExactAlarmsPermission() ?? false;
  });

  @override
  Future<Result<void>> show(
    int id, {
    required String title,
    required String body,
    String? payload,
  }) => _guard(() {
    checkId(id);
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload,
    );
  });

  @override
  Future<Result<void>> scheduleAt(
    int id,
    DateTime when, {
    required String title,
    required String body,
    String? payload,
  }) => _guard(() {
    final at = tz.TZDateTime.from(when, tz.local);
    checkId(id);
    checkFuture(at, _now);
    return _schedule(id, at, title, body, payload);
  });

  @override
  Future<Result<void>> scheduleIn(
    int id,
    Duration delay, {
    required String title,
    required String body,
    String? payload,
  }) => scheduleAt(
    id,
    clock.now().add(delay),
    title: title,
    body: body,
    payload: payload,
  );

  @override
  Future<Result<void>> scheduleWeekly(
    int id, {
    required int weekday,
    required ClockTime time,
    required String title,
    required String body,
    String? payload,
  }) => _guard(() {
    checkId(id);
    final at = nextWeekly(_now, weekday, time);
    return _schedule(id, at, title, body, payload, weekly: true);
  });

  @override
  Future<Result<void>> scheduleEvery(
    int baseId, {
    required DateTime first,
    required int weeks,
    required String title,
    required String body,
    String? payload,
  }) => _guard(() async {
    checkSeriesBase(baseId);
    final occurrences = seriesOccurrences(
      tz.TZDateTime.from(first, tz.local),
      weeks,
      _now,
    );
    await _cancelSeries(baseId);
    if (weeks == 1) {
      return _schedule(
        baseId,
        occurrences.first,
        title,
        body,
        payload,
        weekly: true,
      );
    }
    final mode = await _scheduleMode();
    for (final (index, at) in occurrences.indexed) {
      await _schedule(
        seriesId(baseId, index),
        at,
        title,
        body,
        payload,
        mode: mode,
      );
    }
  });

  @override
  Future<Result<void>> cancel(int id) => _guard(() {
    checkId(id);
    return _plugin.cancel(id: id);
  });

  @override
  Future<Result<void>> cancelEvery(int baseId) => _guard(() {
    checkSeriesBase(baseId);
    return _cancelSeries(baseId);
  });

  @override
  Future<Result<void>> cancelAll() => _guard(_plugin.cancelAll);

  @override
  Future<Result<List<PendingNotification>>> pending() => _guard(() async {
    final requests = await _plugin.pendingNotificationRequests();
    return [
      for (final request in requests)
        PendingNotification(request.id, _payload(request.payload)),
    ];
  });

  Future<void> _schedule(
    int id,
    tz.TZDateTime at,
    String title,
    String body,
    String? payload, {
    bool weekly = false,
    AndroidScheduleMode? mode,
  }) async => _plugin.zonedSchedule(
    id: id,
    scheduledDate: at,
    notificationDetails: _details,
    androidScheduleMode: mode ?? await _scheduleMode(),
    title: title,
    body: body,
    payload: payload,
    matchDateTimeComponents: weekly
        ? DateTimeComponents.dayOfWeekAndTime
        : null,
  );

  Future<void> _cancelSeries(int baseId) async {
    for (final id in seriesIds(baseId)) {
      await _plugin.cancel(id: id);
    }
  }

  // Scheduling an exact alarm without the permission fails on Android, so
  // fall back to an inexact one that may fire a few minutes late.
  Future<AndroidScheduleMode> _scheduleMode() async => await _canScheduleExact()
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  Future<bool> _canScheduleExact() async {
    final android = _android;
    if (android == null) return true;
    return await android.canScheduleExactNotifications() ?? false;
  }

  IOSFlutterLocalNotificationsPlugin _requireIos() =>
      _ios ??
      (throw UnsupportedError('Notifications run on Android and iOS only'));

  static NotificationPermission _permission(bool? granted) => granted ?? false
      ? NotificationPermission.granted
      : NotificationPermission.denied;

  /// The plugin turns a null payload into ''.
  static String? _payload(String? payload) =>
      payload == null || payload.isEmpty ? null : payload;

  static Future<Result<T>> _guard<T>(Future<T> Function() body) =>
      guard(body, mapper: _mapError);

  static Failure? _mapError(Object error) => switch (error) {
    PlatformException(code: 'exact_alarms_not_permitted') => PermissionFailure(
      error.message ?? error.code,
      error,
    ),
    PlatformException() => UnknownFailure(error.message ?? error.code, error),
    ArgumentError(:final message) => ValidationFailure('$message'),
    _ => null,
  };
}

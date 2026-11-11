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
  var _ready = false;
  var _launchReported = false;

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
  Future<Result<LocalTimeZone>> init({void Function(String? payload)? onTap}) =>
      _guard(() async {
        if (!_ready) tzdata.initializeTimeZones();
        final zone = await _applyDeviceZone();
        void tap(String? payload) {
          try {
            onTap?.call(payload);
          } catch (error, stack) {
            Log.e('notifications', 'onTap threw', error, stack);
          }
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
          onDidReceiveNotificationResponse: (response) =>
              tap(_payload(response.payload)),
        );
        _ready = true;
        if (!_launchReported) {
          _launchReported = true;
          final launch = await _plugin.getNotificationAppLaunchDetails();
          if (launch?.didNotificationLaunchApp ?? false) {
            tap(_payload(launch!.notificationResponse?.payload));
          }
        }
        return zone;
      });

  @override
  Future<Result<LocalTimeZone>> refreshTimeZone() => _run(_applyDeviceZone);

  @override
  Future<Result<NotificationPermission>> status() => _run(() async {
    final android = _android;
    if (android != null) {
      return _permission(await android.areNotificationsEnabled());
    }
    final options = await _requireIos().checkPermissions();
    return _permission(
      options != null && (options.isEnabled || options.isProvisionalEnabled),
    );
  });

  @override
  Future<Result<NotificationPermission>> request() => _run(() async {
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
  Future<Result<bool>> canScheduleExact() => _run(_canScheduleExact);

  @override
  Future<Result<bool>> requestExact() => _run(() async {
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
  }) => _run(
    () => _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload,
    ),
  );

  @override
  Future<Result<void>> scheduleAt(
    int id,
    DateTime when, {
    required String title,
    required String body,
    String? payload,
  }) => _run(() async {
    final at = ceilToSecond(tz.TZDateTime.from(when, tz.local));
    checkFuture(at, _now);
    await _checkBudget({id}, 1);
    await _schedule(id, at, title, body, payload, await _scheduleMode());
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
  }) => _run(() async {
    final at = nextWeekly(_now, weekday, time);
    await _checkBudget({id}, 1);
    await _schedule(
      id,
      at,
      title,
      body,
      payload,
      await _scheduleMode(),
      weekly: true,
    );
  });

  @override
  Future<Result<void>> scheduleEvery(
    int baseId, {
    required DateTime first,
    required int weeks,
    required String title,
    required String body,
    String? payload,
  }) => _run(() async {
    checkSeriesBase(baseId);
    final plan = planSeries(
      baseId,
      tz.TZDateTime.from(first, tz.local),
      weeks,
      _now,
    );
    final ids = seriesIds(baseId).toSet();
    final pendingIds = await _pendingIds();
    if (_android == null) {
      checkBudget(pendingIds, ids, plan.occurrences.length, iosPendingLimit);
    }
    final mode = await _scheduleMode();
    final scheduled = <int>[];
    try {
      for (final occurrence in plan.occurrences) {
        await _schedule(
          occurrence.id,
          occurrence.at,
          title,
          body,
          payload,
          mode,
          weekly: plan.weekly,
        );
        scheduled.add(occurrence.id);
      }
      // Cancel only what is still pending: a shown notification stays.
      for (final id in pendingIds) {
        if (ids.contains(id) && !scheduled.contains(id)) {
          await _plugin.cancel(id: id);
        }
      }
    } catch (error) {
      throw _incomplete(error, baseId, scheduled);
    }
  });

  @override
  Future<Result<void>> cancel(int id) => _run(() => _plugin.cancel(id: id));

  @override
  Future<Result<void>> cancelEvery(int baseId) => _run(() async {
    checkSeriesBase(baseId);
    for (final id in seriesIds(baseId)) {
      await _plugin.cancel(id: id);
    }
  });

  @override
  Future<Result<void>> cancelAll() => _run(_plugin.cancelAll);

  @override
  Future<Result<List<PendingNotification>>> pending() => _run(() async {
    final requests = await _plugin.pendingNotificationRequests();
    return [
      for (final request in requests)
        PendingNotification(request.id, _payload(request.payload)),
    ];
  });

  Future<LocalTimeZone> _applyDeviceZone() async {
    final id = (await FlutterTimezone.getLocalTimezone()).identifier;
    final before = _ready ? tz.local.name : null;
    var known = true;
    try {
      tz.setLocalLocation(tz.getLocation(id));
    } on tz.LocationNotFoundException {
      known = false;
      tz.setLocalLocation(tz.UTC);
    }
    return LocalTimeZone(id, known: known, changed: tz.local.name != before);
  }

  Future<void> _schedule(
    int id,
    tz.TZDateTime at,
    String title,
    String body,
    String? payload,
    AndroidScheduleMode mode, {
    bool weekly = false,
  }) => _plugin.zonedSchedule(
    id: id,
    scheduledDate: at,
    notificationDetails: _details,
    androidScheduleMode: mode,
    title: title,
    body: body,
    payload: payload,
    matchDateTimeComponents: weekly
        ? DateTimeComponents.dayOfWeekAndTime
        : null,
  );

  Future<List<int>> _pendingIds() async => [
    for (final request in await _plugin.pendingNotificationRequests())
      request.id,
  ];

  Future<void> _checkBudget(Set<int> claimed, int adding) async {
    if (_android != null) return;
    checkBudget(await _pendingIds(), claimed, adding, iosPendingLimit);
  }

  // Scheduling an exact alarm without the permission fails on Android, so
  // fall back to an inexact one.
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

  Future<Result<T>> _run<T>(Future<T> Function() body) => _guard(() {
    if (!_ready) {
      throw const UnknownFailure('Notifications used before init completed');
    }
    return body();
  });

  static NotificationPermission _permission(bool? granted) => granted ?? false
      ? NotificationPermission.granted
      : NotificationPermission.denied;

  /// The plugin turns a null payload into ''.
  static String? _payload(String? payload) =>
      payload == null || payload.isEmpty ? null : payload;

  static Failure _incomplete(Object error, int baseId, List<int> scheduled) {
    final failure = error is Failure
        ? error
        : _mapError(error) ?? UnknownFailure('$error', error);
    final message =
        'Series $baseId incomplete, scheduled ids $scheduled: '
        '${failure.message}';
    return switch (failure) {
      PermissionFailure() => PermissionFailure(message, error),
      ValidationFailure() => ValidationFailure(message),
      _ => UnknownFailure(message, error),
    };
  }

  static Future<Result<T>> _guard<T>(Future<T> Function() body) =>
      guard(body, mapper: _mapError);

  static Failure? _mapError(Object error) => switch (error) {
    PlatformException(code: 'exact_alarms_not_permitted') => PermissionFailure(
      error.message ?? error.code,
      error,
    ),
    PlatformException() => UnknownFailure(error.message ?? error.code, error),
    ArgumentError() => ValidationFailure('$error'),
    _ => null,
  };
}

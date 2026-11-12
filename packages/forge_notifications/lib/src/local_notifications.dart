import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:forge_core/forge_core.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notifications.dart';
import 'schedule.dart';

/// [Notifications] over `flutter_local_notifications`.
class LocalNotifications implements Notifications {
  /// [androidIcon] is the drawable resource name of the small icon, e.g.
  /// `ic_notification` for `res/drawable/ic_notification.png`.
  /// [countdownChannel] is needed for [showCountdown] only; Android fixes a
  /// channel's sound when it is created, so it is a channel of its own.
  LocalNotifications({
    required this.channel,
    this.countdownChannel,
    required this.androidIcon,
  });

  final NotificationChannel channel;
  final NotificationChannel? countdownChannel;
  final String androidIcon;

  final _plugin = FlutterLocalNotificationsPlugin();
  var _ready = false;
  var _launchReported = false;
  Future<void> _syncing = Future.value();

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
        // Without its channel a notification still shows (the plugin creates
        // it when posting), so a failure here must not fail init.
        try {
          await _createChannels();
        } catch (error, stack) {
          Log.e('notifications', 'channels not created', error, stack);
        }
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
  Future<Result<void>> openSettings() => _guard(() async {
    final opened =
        await (_android?.openAppNotificationSettings() ??
            _requireIos().openAppNotificationSettings());
    if (opened != true) {
      throw const UnknownFailure('Notification settings did not open');
    }
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
  Future<Result<void>> sync(
    int baseId, {
    required int count,
    required List<OneOffNotification> wanted,
  }) {
    final result = _syncing.then(
      (_) => _run(() => _sync(baseId, count, wanted)),
    );
    _syncing = result;
    return result;
  }

  Future<void> _sync(
    int baseId,
    int count,
    List<OneOffNotification> wanted,
  ) async {
    checkIdRange(baseId, count);
    bool owned(int id) => id >= baseId && id < baseId + count;
    final wantedIds = {for (final notification in wanted) notification.id};
    if (wantedIds.length < wanted.length || !wantedIds.every(owned)) {
      throw ValidationFailure(
        'Synced notifications need distinct ids in $baseId to '
        '${baseId + count - 1}',
      );
    }
    final requests = await _plugin.pendingNotificationRequests();
    final pendingIds = {for (final request in requests) request.id};
    final have = {
      for (final request in requests)
        if (owned(request.id)) request.id: request.payload,
    };
    final mode = await _scheduleMode();
    final now = _now;
    final changed = <({OneOffNotification notification, tz.TZDateTime at})>[];
    final unchanged = <int>{};
    for (final notification in wanted) {
      final at = ceilToSecond(tz.TZDateTime.from(notification.at, tz.local));
      final payload = _signed(notification, at, mode);
      if (have[notification.id] == payload) {
        unchanged.add(notification.id);
      } else {
        changed.add((notification: notification, at: at));
      }
    }
    changed.sort((a, b) => a.at.compareTo(b.at));

    (Object, StackTrace)? last;
    Future<void> attempt(Future<void> Function() change) async {
      try {
        await change();
      } catch (error, stack) {
        last = (error, stack);
      }
    }

    // Cancelled first, so nothing stays pending at an outdated time and the
    // freed places count for what is scheduled next.
    for (final id in have.keys) {
      if (unchanged.contains(id)) continue;
      await attempt(() async {
        await _plugin.cancel(id: id);
        pendingIds.remove(id);
      });
    }
    // Android has no limit to keep.
    int? free = _android == null ? iosPendingLimit - pendingIds.length : null;
    for (final (:notification, :at) in changed) {
      await attempt(() async {
        checkFuture(at, now);
        final replacing = pendingIds.contains(notification.id);
        if (!replacing && free != null && free! < 1) {
          throw ValidationFailure(
            'Notification ${notification.id} exceeds the limit of '
            '$iosPendingLimit pending',
          );
        }
        await _schedule(
          notification.id,
          at,
          notification.title,
          notification.body,
          _signed(notification, at, mode),
          mode,
        );
        if (!replacing && free != null) free = free! - 1;
      });
    }
    if (last case (final error, final stack)) {
      Error.throwWithStackTrace(error, stack);
    }
  }

  static String _signed(
    OneOffNotification notification,
    tz.TZDateTime at,
    AndroidScheduleMode mode,
  ) => signPayload(
    notification.payload,
    at: at,
    title: notification.title,
    body: notification.body,
    exact: mode == AndroidScheduleMode.exactAllowWhileIdle,
  );

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
    checkIdRange(baseId, seriesLength);
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
  Future<Result<void>> showCountdown(
    int id, {
    required DateTime endsAt,
    required String title,
    String? body,
  }) => _run(() {
    final android =
        _android ??
        (throw UnsupportedError('Countdown notifications run on Android only'));
    final channel =
        countdownChannel ??
        (throw StateError('showCountdown needs a countdownChannel'));
    final now = clock.now();
    checkFuture(endsAt, now);
    return android.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        playSound: false,
        enableVibration: false,
        silent: true,
        onlyAlertOnce: true,
        ongoing: true,
        autoCancel: false,
        requestPromotedOngoing: true,
        visibility: NotificationVisibility.public,
        when: endsAt.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
        timeoutAfter: endsAt.difference(now).inMilliseconds,
      ),
    );
  });

  @override
  Future<Result<void>> cancel(int id) => _run(() => _plugin.cancel(id: id));

  @override
  Future<Result<void>> cancelEvery(int baseId) => _run(() async {
    checkIdRange(baseId, seriesLength);
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

  Future<void> _createChannels() async {
    final android = _android;
    if (android == null) return;
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        channel.id,
        channel.name,
        description: channel.description,
        importance: channel.importance,
      ),
    );
    final countdown = countdownChannel;
    if (countdown == null) return;
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        countdown.id,
        countdown.name,
        description: countdown.description,
        importance: countdown.importance,
        playSound: false,
        enableVibration: false,
      ),
    );
  }

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

  /// The app's payload: without a `sync` signature, and null for '', which
  /// the plugin turns a null payload into.
  static String? _payload(String? payload) {
    final unsigned = payload == null ? null : unsignPayload(payload);
    return unsigned == null || unsigned.isEmpty ? null : unsigned;
  }

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

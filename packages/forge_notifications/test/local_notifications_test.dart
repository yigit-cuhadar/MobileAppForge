import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_notifications/forge_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

typedef Scheduled = ({
  int id,
  tz.TZDateTime at,
  AndroidScheduleMode mode,
  DateTimeComponents? repeat,
  String? payload,
});

class FakeAndroid extends AndroidFlutterLocalNotificationsPlugin {
  DidReceiveNotificationResponseCallback? onResponse;
  NotificationAppLaunchDetails launch = const NotificationAppLaunchDetails(
    false,
  );
  bool exactAllowed = true;
  bool enabled = true;
  Object? error;
  final shown =
      <(int, String?, String?, String?, AndroidNotificationDetails?)>[];
  final scheduled = <Scheduled>[];
  final cancelled = <int>[];
  var cancelledAll = false;
  var pendingRequests = <PendingNotificationRequest>[];

  @override
  Future<bool> initialize({
    required AndroidInitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    onResponse = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => launch;

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    AndroidNotificationDetails? notificationDetails,
    String? payload,
  }) async {
    if (error case final error?) throw error;
    shown.add((id, title, body, payload, notificationDetails));
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    AndroidNotificationDetails? notificationDetails,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exact,
  }) async {
    if (error case final error?) throw error;
    scheduled.add((
      id: id,
      at: scheduledDate,
      mode: scheduleMode,
      repeat: matchDateTimeComponents,
      payload: payload,
    ));
  }

  @override
  Future<void> cancel({required int id, String? tag}) async =>
      cancelled.add(id);

  @override
  Future<void> cancelAll() async => cancelledAll = true;

  @override
  Future<List<PendingNotificationRequest>>
  pendingNotificationRequests() async => pendingRequests;

  @override
  Future<bool?> areNotificationsEnabled() async => enabled;

  @override
  Future<bool?> requestNotificationsPermission() async => enabled = true;

  @override
  Future<bool?> canScheduleExactNotifications() async => exactAllowed;

  @override
  Future<bool?> requestExactAlarmsPermission() async => exactAllowed = true;
}

class FakeIos extends IOSFlutterLocalNotificationsPlugin {
  NotificationsEnabledOptions? options;
  Map<String, bool>? requested;

  @override
  Future<NotificationsEnabledOptions?> checkPermissions() async => options;

  @override
  Future<bool?> requestPermissions({
    bool sound = false,
    bool alert = false,
    bool badge = false,
    bool provisional = false,
    bool critical = false,
    bool carPlay = false,
    bool providesAppNotificationSettings = false,
  }) async {
    requested = {'sound': sound, 'alert': alert, 'badge': badge};
    return true;
  }
}

NotificationsEnabledOptions iosOptions({
  bool enabled = false,
  bool provisional = false,
}) => NotificationsEnabledOptions(
  isEnabled: enabled,
  isSoundEnabled: enabled,
  isAlertEnabled: enabled,
  isBadgeEnabled: enabled,
  isProvisionalEnabled: provisional,
  isCriticalEnabled: false,
  isProvidesAppNotificationSettingsEnabled: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Wednesday 11 November 2026, 10:00 in Berlin.
  final now = DateTime.utc(2026, 11, 11, 9);
  const channel = NotificationChannel(
    id: 'reminders',
    name: 'Reminders',
    description: 'Workout reminders',
    importance: Importance.high,
  );
  final throwsNothing = isA<Ok<void>>();

  late FakeAndroid android;
  late LocalNotifications notifications;
  final taps = <String?>[];

  Future<T> at<T>(Future<T> Function() body) =>
      withClock(Clock.fixed(now), body);

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (_) async => 'Europe/Berlin',
        );
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    android = FakeAndroid();
    FlutterLocalNotificationsPlatform.instance = android;
    taps.clear();
    notifications = LocalNotifications(
      channel: channel,
      androidIcon: 'ic_notification',
    );
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<void> init() async =>
      expect(await notifications.init(onTap: taps.add), throwsNothing);

  group('init', () {
    test('reports the tap that launched the app, then later taps', () async {
      android.launch = const NotificationAppLaunchDetails(
        true,
        notificationResponse: NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'workout/1',
        ),
      );

      await init();
      android.onResponse!(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'rest',
        ),
      );
      android.onResponse!(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: '',
        ),
      );

      expect(taps, ['workout/1', 'rest', null]);
    });

    test('reports nothing when the app was not launched by a tap', () async {
      await init();

      expect(taps, isEmpty);
    });

    test('uses the device time zone', () async {
      await init();

      expect(tz.local.name, 'Europe/Berlin');
    });
  });

  test('show posts to the configured channel', () async {
    await init();

    await notifications.show(1, title: 'T', body: 'B', payload: 'p');

    final (id, title, body, payload, details) = android.shown.single;
    expect((id, title, body, payload), (1, 'T', 'B', 'p'));
    expect(details!.channelId, 'reminders');
    expect(details.channelName, 'Reminders');
    expect(details.importance, Importance.high);
  });

  group('one-off', () {
    test('scheduleIn fires at now plus the delay, exactly', () async {
      await init();

      final result = await at(
        () => notifications.scheduleIn(
          7,
          const Duration(seconds: 90),
          title: 'Rest is over',
          body: 'Next set',
          payload: 'rest',
        ),
      );

      expect(result, throwsNothing);
      final scheduled = android.scheduled.single;
      expect(scheduled.id, 7);
      expect(
        scheduled.at.millisecondsSinceEpoch,
        now.add(const Duration(seconds: 90)).millisecondsSinceEpoch,
      );
      expect(scheduled.mode, AndroidScheduleMode.exactAllowWhileIdle);
      expect(scheduled.repeat, isNull);
    });

    test('falls back to inexact alarms without the exact permission', () async {
      await init();
      android.exactAllowed = false;

      await at(
        () => notifications.scheduleIn(
          7,
          const Duration(minutes: 1),
          title: 'T',
          body: 'B',
        ),
      );

      expect(
        android.scheduled.single.mode,
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    });

    test('scheduling in the past is a validation failure', () async {
      await init();

      final result = await at(
        () => notifications.scheduleAt(
          7,
          now.subtract(const Duration(seconds: 1)),
          title: 'T',
          body: 'B',
        ),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(android.scheduled, isEmpty);
    });
  });

  test('scheduleWeekly repeats on the weekday at local time', () async {
    await init();

    await at(
      () => notifications.scheduleWeekly(
        3,
        weekday: DateTime.monday,
        time: const ClockTime(7, 0),
        title: 'T',
        body: 'B',
      ),
    );

    final scheduled = android.scheduled.single;
    expect(scheduled.id, 3);
    expect(scheduled.at, tz.TZDateTime(tz.local, 2026, 11, 16, 7));
    expect(scheduled.repeat, DateTimeComponents.dayOfWeekAndTime);
  });

  group('scheduleEvery', () {
    test('pre-schedules a multi-week series under its own ids', () async {
      await init();

      await at(
        () => notifications.scheduleEvery(
          100,
          first: DateTime.utc(2026, 11, 1, 8),
          weeks: 2,
          title: 'T',
          body: 'B',
          payload: 'p',
        ),
      );

      expect(android.cancelled, [for (var i = 100; i < 112; i++) i]);
      expect(android.scheduled.map((s) => s.id), [
        for (var i = 100; i < 112; i++) i,
      ]);
      expect(
        android.scheduled.first.at,
        tz.TZDateTime(tz.local, 2026, 11, 15, 9),
      );
      expect(android.scheduled.every((s) => s.repeat == null), isTrue);
      expect(android.scheduled.every((s) => s.payload == 'p'), isTrue);
    });

    test('repeats natively every week', () async {
      await init();

      await at(
        () => notifications.scheduleEvery(
          100,
          first: DateTime.utc(2026, 11, 1, 8),
          weeks: 1,
          title: 'T',
          body: 'B',
        ),
      );

      final scheduled = android.scheduled.single;
      expect(scheduled.id, 100);
      expect(scheduled.at, tz.TZDateTime(tz.local, 2026, 11, 15, 9));
      expect(scheduled.repeat, DateTimeComponents.dayOfWeekAndTime);
    });

    test('rejects a base id whose range overflows 32 bits', () async {
      await init();

      final result = await at(
        () => notifications.scheduleEvery(
          0x7FFFFFFF,
          first: now,
          weeks: 2,
          title: 'T',
          body: 'B',
        ),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(android.cancelled, isEmpty);
    });
  });

  test('cancel, cancelEvery and cancelAll', () async {
    await init();

    await notifications.cancel(5);
    await notifications.cancelEvery(200);
    await notifications.cancelAll();

    expect(android.cancelled, [5, for (var i = 200; i < 212; i++) i]);
    expect(android.cancelledAll, isTrue);
  });

  test('pending lists ids and payloads', () async {
    await init();
    android.pendingRequests = const [
      PendingNotificationRequest(1, 'T', 'B', 'rest'),
      PendingNotificationRequest(2, 'T', 'B', ''),
    ];

    final result = await notifications.pending();

    expect(result.valueOrNull, const [
      PendingNotification(1, 'rest'),
      PendingNotification(2, null),
    ]);
  });

  group('permissions on Android', () {
    test('status and request', () async {
      await init();
      android.enabled = false;

      expect(
        (await notifications.status()).valueOrNull,
        NotificationPermission.denied,
      );
      expect(
        (await notifications.request()).valueOrNull,
        NotificationPermission.granted,
      );
    });

    test('exact alarms', () async {
      await init();
      android.exactAllowed = false;

      expect((await notifications.canScheduleExact()).valueOrNull, isFalse);
      expect((await notifications.requestExact()).valueOrNull, isTrue);
      expect((await notifications.canScheduleExact()).valueOrNull, isTrue);
    });
  });

  group('platform errors', () {
    test('map to an unknown failure', () async {
      await init();
      android.error = PlatformException(code: 'invalid_icon');

      final result = await notifications.show(1, title: 'T', body: 'B');

      expect(result.failureOrNull, isA<UnknownFailure>());
    });

    test('a refused exact alarm maps to a permission failure', () async {
      await init();
      android.error = PlatformException(code: 'exact_alarms_not_permitted');

      final result = await at(
        () => notifications.scheduleIn(
          1,
          const Duration(minutes: 1),
          title: 'T',
          body: 'B',
        ),
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('permissions on iOS', () {
    late FakeIos ios;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      ios = FakeIos();
      FlutterLocalNotificationsPlatform.instance = ios;
    });

    test('status reports provisional and denied', () async {
      ios.options = iosOptions(provisional: true);
      expect(
        (await notifications.status()).valueOrNull,
        NotificationPermission.provisional,
      );

      ios.options = iosOptions();
      expect(
        (await notifications.status()).valueOrNull,
        NotificationPermission.denied,
      );
    });

    test('request asks for alerts, badges and sounds', () async {
      final result = await notifications.request();

      expect(result.valueOrNull, NotificationPermission.granted);
      expect(ios.requested, {'sound': true, 'alert': true, 'badge': true});
    });

    test('exact scheduling is always available', () async {
      expect((await notifications.canScheduleExact()).valueOrNull, isTrue);
    });
  });
}

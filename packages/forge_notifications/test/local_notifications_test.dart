import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_notifications/forge_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

const _pluginChannel = MethodChannel(
  'dexterous.com/flutter/local_notifications',
);

/// The native side of the plugin: records calls and keeps pending state.
class FakeNative {
  final calls = <MethodCall>[];
  final pending = <int, String>{};
  Map<String, Object?>? launch;
  var exactAllowed = true;
  var enabled = true;
  Map<String, bool> iosPermissions = {};

  /// Fails the given method from its [failAfter]th call on.
  String? failing;
  var failAfter = 0;

  Iterable<MethodCall> named(String method) =>
      calls.where((call) => call.method == method);

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    if (call.method == failing && failAfter-- <= 0) {
      throw PlatformException(code: 'boom', message: 'native failure');
    }
    final args = call.arguments;
    switch (call.method) {
      case 'initialize':
        return true;
      case 'getNotificationAppLaunchDetails':
        return launch;
      case 'zonedSchedule':
        pending[args['id'] as int] = args['payload'] as String;
      case 'cancel':
        pending.remove(args is Map ? args['id'] : args);
      case 'cancelAll':
        pending.clear();
      case 'pendingNotificationRequests':
        return [
          for (final MapEntry(:key, :value) in pending.entries)
            {'id': key, 'title': 'T', 'body': 'B', 'payload': value},
        ];
      case 'areNotificationsEnabled':
        return enabled;
      case 'requestNotificationsPermission':
        return enabled = true;
      case 'canScheduleExactNotifications':
        return exactAllowed;
      case 'requestExactAlarmsPermission':
        return exactAllowed = true;
      case 'checkPermissions':
        return iosPermissions;
      case 'requestPermissions':
        return true;
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  // Wednesday 11 November 2026, 10:00 in Berlin.
  final now = DateTime.utc(2026, 11, 11, 9);
  const channel = NotificationChannel(
    id: 'reminders',
    name: 'Reminders',
    description: 'Workout reminders',
    importance: Importance.high,
  );

  late FakeNative native;
  late String deviceZone;
  late LocalNotifications notifications;
  late List<String?> taps;

  Future<T> at<T>(Future<T> Function() body) =>
      withClock(Clock.fixed(now), body);

  void usePlatform(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    FlutterLocalNotificationsPlatform.instance = platform == TargetPlatform.iOS
        ? IOSFlutterLocalNotificationsPlugin()
        : AndroidFlutterLocalNotificationsPlugin();
  }

  setUp(() {
    native = FakeNative();
    deviceZone = 'Europe/Berlin';
    taps = [];
    messenger.setMockMethodCallHandler(_pluginChannel, native.handle);
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (_) async => deviceZone,
    );
    usePlatform(TargetPlatform.android);
    notifications = LocalNotifications(
      channel: channel,
      androidIcon: 'ic_notification',
    );
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<Result<LocalTimeZone>> init() => notifications.init(onTap: taps.add);

  Future<void> tap(String payload) => messenger.handlePlatformMessage(
    _pluginChannel.name,
    _pluginChannel.codec.encodeMethodCall(
      MethodCall('didReceiveNotificationResponse', {
        'notificationId': 1,
        'payload': payload,
        'notificationResponseType': 0,
      }),
    ),
    (_) {},
  );

  Map<String, Object?> launchedBy(String payload) => {
    'notificationLaunchedApp': true,
    'notificationResponse': {
      'notificationId': 1,
      'payload': payload,
      'notificationResponseType': 0,
    },
  };

  List<int> scheduledIds() => [
    for (final call in native.named('zonedSchedule'))
      call.arguments['id'] as int,
  ];

  group('init', () {
    test('passes the icon and asks for no permission on Android', () async {
      await init();

      expect(native.named('initialize').single.arguments, {
        'defaultIcon': 'ic_notification',
      });
    });

    test('asks for no permission at start on iOS', () async {
      usePlatform(TargetPlatform.iOS);

      await init();

      final args = native.named('initialize').single.arguments as Map;
      expect(args['requestAlertPermission'], isFalse);
      expect(args['requestBadgePermission'], isFalse);
      expect(args['requestSoundPermission'], isFalse);
      expect(args['requestProvisionalPermission'], isFalse);
    });

    test('reports the launching tap once, then every later tap', () async {
      native.launch = launchedBy('workout/1');

      await init();
      await tap('rest');
      await tap('');
      await init();

      expect(taps, ['workout/1', 'rest', null]);
    });

    test('a throwing onTap does not fail init', () async {
      native.launch = launchedBy('workout/1');

      final result = await notifications.init(
        onTap: (_) => throw StateError('app bug'),
      );

      expect(result.isOk, isTrue);
    });

    test('returns the device time zone', () async {
      final result = await init();

      expect(
        result.valueOrNull,
        const LocalTimeZone('Europe/Berlin', known: true, changed: true),
      );
      expect(tz.local.name, 'Europe/Berlin');
    });

    test('falls back to UTC for an unknown zone and says so', () async {
      deviceZone = 'Mars/Olympus';

      final result = await init();

      expect(result.valueOrNull?.known, isFalse);
      expect(tz.local, tz.UTC);
    });
  });

  test('refreshTimeZone reports whether the zone changed', () async {
    await init();

    final same = await notifications.refreshTimeZone();
    deviceZone = 'America/New_York';
    final moved = await notifications.refreshTimeZone();

    expect(same.valueOrNull?.changed, isFalse);
    expect(
      moved.valueOrNull,
      const LocalTimeZone('America/New_York', known: true, changed: true),
    );
    expect(tz.local.name, 'America/New_York');
  });

  test('calls before init fail clearly', () async {
    final result = await notifications.show(1, title: 'T', body: 'B');

    expect(result.failureOrNull, isA<UnknownFailure>());
    expect(result.failureOrNull!.message, contains('init'));
    expect(native.calls, isEmpty);
  });

  test('show posts to the configured channel', () async {
    await init();

    await notifications.show(1, title: 'T', body: 'B', payload: 'p');

    final args = native.named('show').single.arguments as Map;
    expect(
      [args['id'], args['title'], args['body'], args['payload']],
      [1, 'T', 'B', 'p'],
    );
    final details = args['platformSpecifics'] as Map;
    expect(details['channelId'], 'reminders');
    expect(details['channelName'], 'Reminders');
    expect(details['channelDescription'], 'Workout reminders');
    expect(details['importance'], Importance.high.value);
  });

  test('the plugin rejects an id beyond 32 bits', () async {
    await init();

    final result = await notifications.show(1 << 32, title: 'T', body: 'B');

    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  group('one-off', () {
    test('scheduleIn rounds up to the next whole second, exactly', () async {
      await init();

      final result = await at(
        () => notifications.scheduleIn(
          7,
          const Duration(milliseconds: 1500),
          title: 'Rest is over',
          body: 'Next set',
          payload: 'rest',
        ),
      );

      expect(result.isOk, isTrue);
      final args = native.named('zonedSchedule').single.arguments as Map;
      expect(args['id'], 7);
      expect(args['scheduledDateTime'], '2026-11-11T10:00:02');
      expect(args['timeZoneName'], 'Europe/Berlin');
      expect(args['platformSpecifics']['scheduleMode'], 'exactAllowWhileIdle');
      expect(args.containsKey('matchDateTimeComponents'), isFalse);
    });

    test('a sub-second delay is still scheduled in the future', () async {
      await init();

      final result = await at(
        () => notifications.scheduleIn(
          7,
          const Duration(milliseconds: 10),
          title: 'T',
          body: 'B',
        ),
      );

      expect(result.isOk, isTrue);
      expect(
        native.named('zonedSchedule').single.arguments['scheduledDateTime'],
        '2026-11-11T10:00:01',
      );
    });

    test('falls back to inexact alarms without the exact permission', () async {
      await init();
      native.exactAllowed = false;

      await at(
        () => notifications.scheduleIn(
          7,
          const Duration(minutes: 1),
          title: 'T',
          body: 'B',
        ),
      );

      expect(
        native
            .named('zonedSchedule')
            .single
            .arguments['platformSpecifics']['scheduleMode'],
        'inexactAllowWhileIdle',
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
      expect(native.named('zonedSchedule'), isEmpty);
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

    final args = native.named('zonedSchedule').single.arguments as Map;
    expect(args['id'], 3);
    expect(args['scheduledDateTime'], '2026-11-16T07:00:00');
    expect(
      args['matchDateTimeComponents'],
      DateTimeComponents.dayOfWeekAndTime.index,
    );
  });

  group('scheduleEvery', () {
    Future<Result<void>> every({
      DateTime? first,
      int weeks = 2,
      String payload = 'p',
    }) => at(
      () => notifications.scheduleEvery(
        100,
        first: first ?? DateTime.utc(2026, 11, 1, 8),
        weeks: weeks,
        title: 'T',
        body: 'B',
        payload: payload,
      ),
    );

    test('pre-schedules a multi-week series under its own ids', () async {
      await init();

      await every();

      // 1 November is occurrence 0, so 15 November (101) is next.
      expect(scheduledIds(), [
        for (var k = 1; k <= seriesLength; k++) 100 + k % seriesLength,
      ]);
      final first = native.named('zonedSchedule').first.arguments as Map;
      expect(first['scheduledDateTime'], '2026-11-15T09:00:00');
      expect(first.containsKey('matchDateTimeComponents'), isFalse);
    });

    test('re-applying is idempotent and keeps shown notifications', () async {
      await init();
      await every();
      final pendingBefore = Map.of(native.pending);
      native.calls.clear();

      await every();

      expect(native.pending, pendingBefore);
      expect(native.named('cancel'), isEmpty);
    });

    test('a weekly series starting within a week repeats natively', () async {
      await init();
      await every(first: DateTime.utc(2026, 12, 2, 8), weeks: 1);
      native.calls.clear();

      await every(first: DateTime.utc(2026, 11, 14, 8), weeks: 1);

      final args = native.named('zonedSchedule').single.arguments as Map;
      expect(args['id'], 100);
      expect(args['scheduledDateTime'], '2026-11-14T09:00:00');
      expect(
        args['matchDateTimeComponents'],
        DateTimeComponents.dayOfWeekAndTime.index,
      );
      // Only the leftover pending occurrences are cancelled.
      expect(native.pending.keys, [100]);
      expect(native.named('cancel'), hasLength(seriesLength - 1));
    });

    test('a weekly series three weeks out does not fire early', () async {
      await init();

      await every(first: DateTime.utc(2026, 12, 2, 8), weeks: 1);

      final calls = native.named('zonedSchedule');
      expect(calls, hasLength(seriesLength));
      expect(calls.first.arguments['scheduledDateTime'], '2026-12-02T09:00:00');
      expect(
        calls.any(
          (c) => (c.arguments as Map).containsKey('matchDateTimeComponents'),
        ),
        isFalse,
      );
    });

    test('a failure partway names the scheduled ids', () async {
      await init();
      native
        ..failing = 'zonedSchedule'
        ..failAfter = 3;

      final result = await every();

      expect(result.failureOrNull, isA<UnknownFailure>());
      expect(
        result.failureOrNull!.message,
        allOf(contains('[101, 102, 103]'), contains('native failure')),
      );
      expect(native.pending.keys, [101, 102, 103]);
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
      expect(native.named('zonedSchedule'), isEmpty);
    });
  });

  group('iOS pending limit', () {
    setUp(() => usePlatform(TargetPlatform.iOS));

    test('rejects a schedule that would pass 64 pending', () async {
      await init();
      native.pending.addAll({for (var i = 0; i < 60; i++) i: ''});

      final series = await at(
        () => notifications.scheduleEvery(
          100,
          first: DateTime.utc(2026, 11, 1, 8),
          weeks: 2,
          title: 'T',
          body: 'B',
        ),
      );
      native.pending.addAll({for (var i = 60; i < 64; i++) i: ''});
      final replacing = await at(
        () => notifications.scheduleIn(
          0,
          const Duration(minutes: 1),
          title: 'T',
          body: 'B',
        ),
      );
      final adding = await at(
        () => notifications.scheduleIn(
          64,
          const Duration(minutes: 1),
          title: 'T',
          body: 'B',
        ),
      );

      expect(series.failureOrNull, isA<ValidationFailure>());
      expect(replacing.isOk, isTrue);
      expect(adding.failureOrNull, isA<ValidationFailure>());
    });
  });

  test('cancel, cancelEvery and cancelAll', () async {
    await init();

    await notifications.cancel(5);
    await notifications.cancelEvery(200);
    await notifications.cancelAll();

    expect(
      [for (final call in native.named('cancel')) call.arguments['id']],
      [5, for (var i = 200; i < 212; i++) i],
    );
    expect(native.named('cancelAll'), hasLength(1));
  });

  test('pending lists ids and payloads', () async {
    await init();
    native.pending.addAll({1: 'rest', 2: ''});

    final result = await notifications.pending();

    expect(result.valueOrNull, const [
      PendingNotification(1, 'rest'),
      PendingNotification(2, null),
    ]);
  });

  group('permissions on Android', () {
    test('status and request', () async {
      await init();
      native.enabled = false;

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
      native.exactAllowed = false;

      expect((await notifications.canScheduleExact()).valueOrNull, isFalse);
      expect((await notifications.requestExact()).valueOrNull, isTrue);
      expect((await notifications.canScheduleExact()).valueOrNull, isTrue);
    });
  });

  group('permissions on iOS', () {
    setUp(() => usePlatform(TargetPlatform.iOS));

    test('status counts provisional as granted', () async {
      await init();

      native.iosPermissions = {'isProvisionalEnabled': true};
      expect(
        (await notifications.status()).valueOrNull,
        NotificationPermission.granted,
      );
      native.iosPermissions = {};
      expect(
        (await notifications.status()).valueOrNull,
        NotificationPermission.denied,
      );
    });

    test('request asks for alerts, badges and sounds', () async {
      await init();

      final result = await notifications.request();

      expect(result.valueOrNull, NotificationPermission.granted);
      final args = native.named('requestPermissions').single.arguments as Map;
      expect(
        [args['alert'], args['badge'], args['sound'], args['provisional']],
        [true, true, true, false],
      );
    });

    test('exact scheduling is always available', () async {
      await init();

      expect((await notifications.canScheduleExact()).valueOrNull, isTrue);
    });
  });

  group('platform errors', () {
    test('map to an unknown failure', () async {
      await init();
      native.failing = 'show';

      final result = await notifications.show(1, title: 'T', body: 'B');

      expect(result.failureOrNull, isA<UnknownFailure>());
    });

    test('a refused exact alarm maps to a permission failure', () async {
      await init();
      messenger.setMockMethodCallHandler(_pluginChannel, (call) async {
        if (call.method == 'zonedSchedule') {
          throw PlatformException(code: 'exact_alarms_not_permitted');
        }
        return native.handle(call);
      });

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
}

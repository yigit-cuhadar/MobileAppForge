import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_health/forge_health.dart';
import 'package:forge_health/src/data/health_data_source.dart';
import 'package:forge_health/src/data/platform_health_steps.dart';
import 'package:health/health.dart';
import 'package:mocktail/mocktail.dart';

class _MockSource extends Mock implements HealthDataSource {}

/// Whether the test process's zone follows EU or US daylight saving time
/// (2026: March 29 and October 25, or March 8 and November 1).
/// `tools/check.sh` runs these tests again with `TZ=Europe/Berlin`.
final followsEuOrUsDst = [
  DateTime(2026, 3, 29),
  DateTime(2026, 3, 8),
].any((day) => DateTime(2026, 3, day.day + 1).difference(day).inHours == 23);

void main() {
  late _MockSource source;
  late PlatformHealthSteps repository;

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(Uri());
  });

  setUp(() {
    source = _MockSource();
    repository = PlatformHealthSteps(source);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    Log.onError = (_, _, _) {};
    when(source.hasStepsPermission).thenAnswer((_) async => true);
    when(source.isHealthKitAvailable).thenAnswer((_) async => true);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    Log.onError = null;
  });

  /// Answers every day's total with its day of month.
  void stepsByDayOfMonth() => when(
    () => source.totalSteps(any(), any()),
  ).thenAnswer((call) async => (call.positionalArguments[0] as DateTime).day);

  List<({DateTime start, DateTime end})> queriedDays() {
    final args = verify(() => source.totalSteps(captureAny(), captureAny()))
        .captured
        .cast<DateTime>();
    return [
      for (var i = 0; i < args.length; i += 2)
        (start: args[i], end: args[i + 1]),
    ];
  }

  group('availability', () {
    for (final (status, expected) in [
      (HealthConnectSdkStatus.sdkAvailable, HealthAvailability.available),
      (
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired,
        HealthAvailability.notInstalled,
      ),
      (HealthConnectSdkStatus.sdkUnavailable, HealthAvailability.unsupported),
    ]) {
      test('Health Connect $status is $expected', () async {
        when(source.healthConnectStatus).thenAnswer((_) async => status);
        expect((await repository.availability()).valueOrNull, expected);
      });
    }

    test('an unreadable Health Connect status fails', () async {
      when(source.healthConnectStatus).thenAnswer((_) async => null);
      expect(
        (await repository.availability()).failureOrNull,
        isA<UnknownFailure>(),
      );
    });

    test('iOS follows HealthKit', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        (await repository.availability()).valueOrNull,
        HealthAvailability.available,
      );
      when(source.isHealthKitAvailable).thenAnswer((_) async => false);
      expect(
        (await repository.availability()).valueOrNull,
        HealthAvailability.unsupported,
      );
    });

    test('iOS counts as available if the plugin drops its check', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(source.isHealthKitAvailable).thenThrow(MissingPluginException());
      expect(
        (await repository.availability()).valueOrNull,
        HealthAvailability.available,
      );
    });

    test('other platforms are unsupported without a plugin call', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(
        (await repository.availability()).valueOrNull,
        HealthAvailability.unsupported,
      );
      verifyZeroInteractions(source);
    });
  });

  group('permission', () {
    test('Android reports granted and denied', () async {
      expect(
        (await repository.permission()).valueOrNull,
        HealthPermission.granted,
      );
      when(source.hasStepsPermission).thenAnswer((_) async => false);
      expect(
        (await repository.permission()).valueOrNull,
        HealthPermission.denied,
      );
    });

    test('iOS read access is undetermined', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(source.hasStepsPermission).thenAnswer((_) async => null);
      expect(
        (await repository.permission()).valueOrNull,
        HealthPermission.undetermined,
      );
    });

    test('missing Health Connect is unavailable', () async {
      when(source.hasStepsPermission).thenThrow(UnsupportedError('missing'));
      expect(
        (await repository.permission()).failureOrNull,
        isA<HealthFailure>(),
      );
    });

    test('an iOS device without HealthKit is unavailable', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(source.isHealthKitAvailable).thenAnswer((_) async => false);
      expect(
        (await repository.permission()).failureOrNull,
        isA<HealthFailure>(),
      );
      expect(
        (await repository.requestPermission()).failureOrNull,
        isA<HealthFailure>(),
      );
      verifyNever(source.requestStepsPermission);
    });

    test('other platforms are unavailable', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(
        (await repository.permission()).failureOrNull,
        isA<HealthFailure>(),
      );
    });
  });

  group('requestPermission', () {
    test('Android skips the dialog when already granted', () async {
      expect(
        (await repository.requestPermission()).valueOrNull,
        HealthPermission.granted,
      );
      verifyNever(source.requestStepsPermission);
    });

    test('Android returns the dialog outcome', () async {
      when(source.hasStepsPermission).thenAnswer((_) async => false);
      when(source.requestStepsPermission).thenAnswer((_) async => true);
      expect(
        (await repository.requestPermission()).valueOrNull,
        HealthPermission.granted,
      );
      when(source.requestStepsPermission).thenAnswer((_) async => false);
      expect(
        (await repository.requestPermission()).valueOrNull,
        HealthPermission.denied,
      );
    });

    test('iOS stays undetermined after the sheet', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(source.requestStepsPermission).thenAnswer((_) async => true);
      expect(
        (await repository.requestPermission()).valueOrNull,
        HealthPermission.undetermined,
      );
      verifyNever(source.hasStepsPermission);
    });

    test('a failed iOS sheet fails', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(source.requestStepsPermission).thenAnswer((_) async => false);
      expect(
        (await repository.requestPermission()).failureOrNull,
        isA<UnknownFailure>(),
      );
    });
  });

  group('reading steps', () {
    test('stepsOn reads the whole local day of any time in it', () async {
      stepsByDayOfMonth();
      final result = await repository.stepsOn(DateTime(2026, 5, 12, 15, 30));
      expect(result.valueOrNull, 12);
      expect(queriedDays(), [
        (start: DateTime(2026, 5, 12), end: DateTime(2026, 5, 13)),
      ]);
    });

    test('dailySteps ignores the times of day at both ends', () async {
      stepsByDayOfMonth();
      final result = await repository.dailySteps(
        DateTime(2026, 5, 10, 23, 59),
        DateTime(2026, 5, 12, 0, 1),
      );
      expect(result.valueOrNull, [
        DailySteps(DateTime(2026, 5, 10), 10),
        DailySteps(DateTime(2026, 5, 11), 11),
        DailySteps(DateTime(2026, 5, 12), 12),
      ]);
    });

    test('days without data are zero', () async {
      when(() => source.totalSteps(any(), any())).thenAnswer((_) async => 0);
      final result = await repository.dailySteps(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 3),
      );
      expect(result.valueOrNull!.map((d) => d.count), [0, 0, 0]);
    });

    for (final (name, first, last) in [
      ('spring forward', DateTime(2026, 3, 6), DateTime(2026, 3, 31)),
      ('fall back', DateTime(2026, 10, 24), DateTime(2026, 11, 3)),
    ]) {
      test('windows are contiguous local midnights across $name', () async {
        stepsByDayOfMonth();
        final result = await repository.dailySteps(first, last);
        final days = queriedDays();
        expect(days.first.start, first);
        expect(days.last.end, DateTime(last.year, last.month, last.day + 1));
        for (var i = 0; i < days.length; i++) {
          expect((days[i].start.hour, days[i].start.minute), (0, 0));
          if (i > 0) expect(days[i].start, days[i - 1].end);
        }
        expect(result.valueOrNull!.map((d) => d.day), days.map((d) => d.start));
      });
    }

    test('the DST change days are 23 and 25 hours long', () async {
      stepsByDayOfMonth();
      await repository.dailySteps(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
      await repository.dailySteps(
        DateTime(2026, 10, 20),
        DateTime(2026, 11, 5),
      );
      final hours = queriedDays().map((d) => d.end.difference(d.start).inHours);
      expect(hours, hasLength(31 + 17));
      expect(hours.where((h) => h == 23), hasLength(1));
      expect(hours.where((h) => h == 25), hasLength(1));
      expect(hours.where((h) => h == 24), hasLength(31 + 17 - 2));
    }, skip: followsEuOrUsDst ? false : 'needs EU or US daylight saving time');

    test('reads at most five days at once', () async {
      var inFlight = 0;
      var peak = 0;
      when(() => source.totalSteps(any(), any())).thenAnswer((_) async {
        peak = ++inFlight > peak ? inFlight : peak;
        await Future<void>.delayed(Duration.zero);
        inFlight--;
        return 1;
      });
      final result = await repository.dailySteps(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 31),
      );
      expect(result.valueOrNull, hasLength(31));
      expect(peak, 5);
    });

    test('reads up to 366 days and rejects longer ranges', () async {
      when(() => source.totalSteps(any(), any())).thenAnswer((_) async => 1);
      final longest = await repository.dailySteps(
        DateTime(2027, 6, 1),
        DateTime(2028, 5, 31),
      );
      expect(longest.valueOrNull, hasLength(maxStepDays));
      clearInteractions(source);
      final tooLong = await repository.dailySteps(
        DateTime(2027, 6, 1),
        DateTime(2028, 6, 1),
      );
      expect(tooLong.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => source.totalSteps(any(), any()));
    });

    test('a read without Health Connect is unavailable', () async {
      when(source.hasStepsPermission).thenThrow(UnsupportedError('missing'));
      expect(
        (await repository.stepsOn(DateTime(2026, 5, 1))).failureOrNull,
        isA<HealthFailure>(),
      );
      verifyNever(() => source.totalSteps(any(), any()));
    });

    test('a read without Android access is a permission failure', () async {
      when(source.hasStepsPermission).thenAnswer((_) async => false);
      expect(
        (await repository.dailySteps(
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 3),
        )).failureOrNull,
        isA<PermissionFailure>(),
      );
      verifyNever(() => source.totalSteps(any(), any()));
    });

    test('a missing total with access granted is unknown', () async {
      stepsByDayOfMonth();
      when(() => source.totalSteps(DateTime(2026, 5, 2), any()))
          .thenAnswer((_) async => null);
      expect(
        (await repository.dailySteps(
          DateTime(2026, 5, 1),
          DateTime(2026, 5, 3),
        )).failureOrNull,
        isA<UnknownFailure>(),
      );
    });

    test('an iOS device without HealthKit is unavailable', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(source.isHealthKitAvailable).thenAnswer((_) async => false);
      expect(
        (await repository.stepsOn(DateTime(2026, 5, 1))).failureOrNull,
        isA<HealthFailure>(),
      );
      verifyNever(() => source.totalSteps(any(), any()));
    });

    test('a platform error is unknown', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(() => source.totalSteps(any(), any()))
          .thenThrow(PlatformException(code: 'STEPS_ERROR', message: 'locked'));
      final failure = (await repository.stepsOn(DateTime(2026, 5, 1)))
          .failureOrNull;
      expect(failure, isA<UnknownFailure>());
      expect(failure!.message, 'locked');
    });

    test('a reversed range fails without reading', () async {
      final result = await repository.dailySteps(
        DateTime(2026, 5, 3),
        DateTime(2026, 5, 2, 23),
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => source.totalSteps(any(), any()));
    });

    test('other platforms are unavailable', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(
        (await repository.stepsOn(DateTime(2026, 5, 1))).failureOrNull,
        isA<HealthFailure>(),
      );
    });
  });

  group('openSettings', () {
    const manage = 'android.health.connect.action.MANAGE_HEALTH_PERMISSIONS';
    const home = 'android.health.connect.action.HEALTH_HOME_SETTINGS';
    const legacy = 'androidx.health.ACTION_HEALTH_CONNECT_SETTINGS';
    final playStore = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
    );

    void healthConnect(HealthConnectSdkStatus status) =>
        when(source.healthConnectStatus).thenAnswer((_) async => status);

    void launches(Set<String> resolvable) =>
        when(
          () => source.launchAndroidAction(
            any(),
            arguments: any(named: 'arguments'),
          ),
        ).thenAnswer((call) async {
          if (!resolvable.contains(call.positionalArguments[0])) {
            throw PlatformException(code: 'error', message: 'No activity');
          }
        });

    List<Object?> launched() => verify(
      () => source.launchAndroidAction(
        captureAny(),
        arguments: captureAny(named: 'arguments'),
      ),
    ).captured;

    setUp(() {
      when(source.packageName).thenAnswer((_) async => 'com.example.app');
    });

    test('Android 14+ opens the app permission page', () async {
      healthConnect(HealthConnectSdkStatus.sdkAvailable);
      launches({manage, home, legacy});
      expect((await repository.openSettings()).isOk, isTrue);
      expect(launched(), [
        manage,
        {'android.intent.extra.PACKAGE_NAME': 'com.example.app'},
      ]);
    });

    test('falls back to the Health Connect home, then the app', () async {
      healthConnect(HealthConnectSdkStatus.sdkAvailable);
      launches({home});
      expect((await repository.openSettings()).isOk, isTrue);
      launches({legacy});
      expect((await repository.openSettings()).isOk, isTrue);
      expect(launched().whereType<String>(), [
        manage,
        home,
        manage,
        home,
        legacy,
      ]);
    });

    test('fails when no settings page opens', () async {
      healthConnect(HealthConnectSdkStatus.sdkAvailable);
      launches({});
      expect(
        (await repository.openSettings()).failureOrNull,
        isA<UnknownFailure>(),
      );
    });

    test('missing Health Connect opens the Play Store app', () async {
      healthConnect(
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired,
      );
      when(source.openHealthConnectInStore).thenAnswer((_) async {});
      expect((await repository.openSettings()).isOk, isTrue);
      verifyNever(() => source.openUrl(any()));
    });

    test('without the Play Store app it opens the web page', () async {
      healthConnect(
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired,
      );
      when(source.openHealthConnectInStore)
          .thenThrow(PlatformException(code: 'error'));
      when(() => source.openUrl(any())).thenAnswer((_) async => true);
      expect((await repository.openSettings()).isOk, isTrue);
      verify(() => source.openUrl(playStore)).called(1);

      when(() => source.openUrl(any())).thenAnswer((_) async => false);
      expect(
        (await repository.openSettings()).failureOrNull,
        isA<UnknownFailure>(),
      );
    });

    test('unsupported devices have no settings', () async {
      healthConnect(HealthConnectSdkStatus.sdkUnavailable);
      expect(
        (await repository.openSettings()).failureOrNull,
        isA<HealthFailure>(),
      );
    });

    test('iOS opens the app settings', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(source.isHealthKitAvailable).thenThrow(MissingPluginException());
      when(() => source.openUrl(any())).thenAnswer((_) async => true);
      expect((await repository.openSettings()).isOk, isTrue);
      verify(() => source.openUrl(Uri.parse('app-settings:'))).called(1);

      when(() => source.openUrl(any())).thenAnswer((_) async => false);
      expect(
        (await repository.openSettings()).failureOrNull,
        isA<UnknownFailure>(),
      );
    });
  });
}

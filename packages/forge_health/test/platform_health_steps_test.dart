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

HealthFailureReason? reasonOf(Result<Object?> result) =>
    switch (result.failureOrNull) {
      HealthFailure(:final reason) => reason,
      _ => null,
    };

void main() {
  late _MockSource source;
  late PlatformHealthSteps repository;

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    source = _MockSource();
    repository = PlatformHealthSteps(source);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    Log.onError = (_, _, _) {};
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
      when(source.isHealthKitAvailable).thenAnswer((_) async => true);
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
      when(source.hasStepsPermission).thenAnswer((_) async => true);
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
        reasonOf(await repository.permission()),
        HealthFailureReason.unavailable,
      );
    });

    test('other platforms are unavailable', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(
        reasonOf(await repository.permission()),
        HealthFailureReason.unavailable,
      );
    });
  });

  group('requestPermission', () {
    test('Android skips the dialog when already granted', () async {
      when(source.hasStepsPermission).thenAnswer((_) async => true);
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

    // Run with TZ=Europe/Berlin or TZ=America/New_York to cross real DST
    // changes; in UTC the same boundaries are 24 hours long.
    for (final (name, first, last) in [
      ('spring forward', DateTime(2026, 3, 6), DateTime(2026, 3, 31)),
      ('fall back', DateTime(2026, 10, 24), DateTime(2026, 11, 3)),
    ]) {
      test('splits by calendar day across $name', () async {
        stepsByDayOfMonth();
        final result = await repository.dailySteps(first, last);
        final days = queriedDays();
        expect(days.first.start, first);
        expect(days.last.end, DateTime(last.year, last.month, last.day + 1));
        for (var i = 0; i < days.length; i++) {
          final day = days[i];
          expect((day.start.hour, day.start.minute), (0, 0));
          expect(
            day.end,
            DateTime(day.start.year, day.start.month, day.start.day + 1),
          );
          if (i > 0) expect(day.start, days[i - 1].end);
        }
        expect(
          days,
          hasLength((last.difference(first).inHours / 24).round() + 1),
        );
        expect(result.valueOrNull!.map((d) => d.day), days.map((d) => d.start));
      });
    }

    test('a refused Health Connect read is denied', () async {
      stepsByDayOfMonth();
      when(() => source.totalSteps(DateTime(2026, 5, 2), any()))
          .thenAnswer((_) async => null);
      when(source.hasStepsPermission).thenAnswer((_) async => false);
      final result = await repository.dailySteps(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 3),
      );
      expect(reasonOf(result), HealthFailureReason.denied);
    });

    test('a missing total with access granted is unknown', () async {
      when(() => source.totalSteps(any(), any())).thenAnswer((_) async => null);
      when(source.hasStepsPermission).thenAnswer((_) async => true);
      expect(
        (await repository.stepsOn(DateTime(2026, 5, 1))).failureOrNull,
        isA<UnknownFailure>(),
      );
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
        reasonOf(await repository.stepsOn(DateTime(2026, 5, 1))),
        HealthFailureReason.unavailable,
      );
    });
  });

  group('openSettings', () {
    test('Android opens Health Connect settings when available', () async {
      when(source.healthConnectStatus)
          .thenAnswer((_) async => HealthConnectSdkStatus.sdkAvailable);
      when(source.openHealthConnectSettings).thenAnswer((_) async {});
      expect((await repository.openSettings()).isOk, isTrue);
      verify(source.openHealthConnectSettings).called(1);
    });

    test('Android opens the store when Health Connect is missing', () async {
      when(source.healthConnectStatus).thenAnswer(
        (_) async =>
            HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired,
      );
      when(source.installHealthConnect).thenAnswer((_) async {});
      expect((await repository.openSettings()).isOk, isTrue);
      verify(source.installHealthConnect).called(1);
    });

    test('unsupported devices have no settings', () async {
      when(source.healthConnectStatus)
          .thenAnswer((_) async => HealthConnectSdkStatus.sdkUnavailable);
      expect(
        reasonOf(await repository.openSettings()),
        HealthFailureReason.unavailable,
      );
    });

    test('iOS opens the app settings', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(source.isHealthKitAvailable).thenAnswer((_) async => true);
      when(source.openAppSettings).thenAnswer((_) async {});
      expect((await repository.openSettings()).isOk, isTrue);
      verify(source.openAppSettings).called(1);
    });
  });
}

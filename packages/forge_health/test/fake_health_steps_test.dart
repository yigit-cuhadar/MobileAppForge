import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_health/forge_health.dart';

void main() {
  late DateTime now;
  late FakeHealthSteps fake;

  setUp(() {
    now = DateTime(2026, 5, 12, 6);
    fake = FakeHealthSteps(
      permissionStatus: HealthPermission.granted,
      stepsFor: (day) => day.day * 1000,
      clock: () => now,
    );
  });

  test('past days are full, today counts up, future days are zero', () async {
    final result = await fake.dailySteps(
      DateTime(2026, 5, 11),
      DateTime(2026, 5, 13),
    );
    expect(result.valueOrNull, [
      DailySteps(DateTime(2026, 5, 11), 11000),
      DailySteps(DateTime(2026, 5, 12), 3000),
      DailySteps(DateTime(2026, 5, 13), 0),
    ]);
    now = DateTime(2026, 5, 13);
    expect((await fake.stepsOn(DateTime(2026, 5, 12, 20))).valueOrNull, 12000);
  });

  test('the default counts are fixed per date and in range', () {
    final counts = [
      for (var d = 1; d <= 60; d++)
        FakeHealthSteps.defaultSteps(DateTime(2026, 1, d)),
    ];
    expect(counts.toSet().length, greaterThan(30));
    expect(counts.every((c) => c >= 2000 && c < 14000), isTrue);
    expect(FakeHealthSteps.defaultSteps(DateTime(2026, 1, 5)), counts[4]);
  });

  test('a request grants a denied permission', () async {
    fake.permissionStatus = HealthPermission.denied;
    expect(
      (await fake.stepsOn(DateTime(2026, 5, 11))).failureOrNull,
      isA<PermissionFailure>(),
    );
    expect(
      (await fake.requestPermission()).valueOrNull,
      HealthPermission.granted,
    );
    expect((await fake.stepsOn(DateTime(2026, 5, 11))).valueOrNull, 11000);
  });

  test('a request can be refused or stay undetermined', () async {
    fake
      ..permissionStatus = HealthPermission.denied
      ..grantOnRequest = HealthPermission.denied;
    expect(
      (await fake.requestPermission()).valueOrNull,
      HealthPermission.denied,
    );
    fake.grantOnRequest = HealthPermission.undetermined;
    expect(
      (await fake.requestPermission()).valueOrNull,
      HealthPermission.undetermined,
    );
    expect((await fake.stepsOn(DateTime(2026, 5, 11))).isOk, isTrue);
  });

  test('without a health store only availability and settings work', () async {
    fake.status = HealthAvailability.notInstalled;
    expect(
      (await fake.availability()).valueOrNull,
      HealthAvailability.notInstalled,
    );
    expect((await fake.permission()).failureOrNull, isA<HealthFailure>());
    expect(
      (await fake.stepsOn(DateTime(2026, 5, 11))).failureOrNull,
      isA<HealthFailure>(),
    );
    expect((await fake.openSettings()).isOk, isTrue);
    expect(fake.settingsOpened, 1);

    fake.status = HealthAvailability.unsupported;
    expect((await fake.openSettings()).failureOrNull, isA<HealthFailure>());
    expect(fake.settingsOpened, 1);
  });

  test('a set failure is returned until cleared', () async {
    fake.failure = const NetworkFailure();
    expect((await fake.availability()).failureOrNull, isA<NetworkFailure>());
    expect(
      (await fake.dailySteps(now, now)).failureOrNull,
      isA<NetworkFailure>(),
    );
    fake.failure = null;
    expect((await fake.dailySteps(now, now)).isOk, isTrue);
  });

  test('a reversed range fails', () async {
    expect(
      (await fake.dailySteps(
        DateTime(2026, 5, 2),
        DateTime(2026, 5, 1),
      )).failureOrNull,
      isA<ValidationFailure>(),
    );
  });

  test('a range is capped at maxStepDays', () async {
    expect(
      (await fake.dailySteps(
        DateTime(2027, 6, 1),
        DateTime(2028, 5, 31),
      )).valueOrNull,
      hasLength(maxStepDays),
    );
    expect(
      (await fake.dailySteps(
        DateTime(2027, 6, 1),
        DateTime(2028, 6, 1),
      )).failureOrNull,
      isA<ValidationFailure>(),
    );
  });

  test('a range has one entry per local day across DST', () async {
    final result = await fake.dailySteps(
      DateTime(2026, 3, 1),
      DateTime(2026, 3, 31),
    );
    final days = result.valueOrNull!.map((d) => d.day).toList();
    expect(days, [for (var d = 1; d <= 31; d++) DateTime(2026, 3, d)]);
  });
}

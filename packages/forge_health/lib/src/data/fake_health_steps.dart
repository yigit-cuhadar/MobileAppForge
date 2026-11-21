import 'package:forge_core/forge_core.dart';

import '../domain/health_models.dart';
import '../domain/health_steps.dart';
import 'local_days.dart';

/// In-memory health store for tests, simulators and demos. Deterministic:
/// each past day has a fixed count from [stepsFor], the current day counts
/// up through the day by the clock, and future days are zero. Its
/// workouts are [workoutList]. Every field can be changed while it runs.
class FakeHealthSteps implements HealthSteps {
  FakeHealthSteps({
    this.status = HealthAvailability.available,
    this.permissionStatus = HealthPermission.denied,
    this.grantOnRequest = HealthPermission.granted,
    this.workoutsPermissionStatus = HealthPermission.denied,
    int Function(DateTime day)? stepsFor,
    this.workoutList = const [],
    DateTime Function()? clock,
  }) : stepsFor = stepsFor ?? defaultSteps,
       _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  HealthAvailability status;
  HealthPermission permissionStatus;

  HealthPermission workoutsPermissionStatus;

  /// What [requestPermission] changes a denied [permissionStatus] and
  /// [workoutsPermissionStatus] to.
  HealthPermission grantOnRequest;

  /// Every workout in the store, in any order.
  List<HealthWorkout> workoutList;

  /// The full count of a past day, given its local midnight.
  int Function(DateTime day) stepsFor;

  /// Returned by every call until cleared.
  Failure? failure;

  /// How often [openSettings] succeeded.
  var settingsOpened = 0;

  /// 2,000 to 13,999 steps, varying by date.
  static int defaultSteps(DateTime day) =>
      2000 + (day.year * 372 + day.month * 31 + day.day) * 7919 % 12000;

  @override
  Future<Result<HealthAvailability>> availability() => _run(() async => status);

  @override
  Future<Result<HealthPermission>> permission() => _run(() async {
    _requireAvailable();
    return permissionStatus;
  });

  @override
  Future<Result<HealthPermission>> requestPermission() => _run(() async {
    _requireAvailable();
    if (permissionStatus == HealthPermission.denied) {
      permissionStatus = grantOnRequest;
    }
    if (workoutsPermissionStatus == HealthPermission.denied) {
      workoutsPermissionStatus = grantOnRequest;
    }
    return permissionStatus;
  });

  @override
  Future<Result<int>> stepsOn(DateTime day) =>
      _run(() async => _read(day, day).single.count);

  @override
  Future<Result<List<DailySteps>>> dailySteps(DateTime first, DateTime last) =>
      _run(() async => _read(first, last));

  @override
  Future<Result<HealthPermission>> workoutsPermission() => _run(() async {
    _requireAvailable();
    return workoutsPermissionStatus;
  });

  @override
  Future<Result<List<HealthWorkout>>> workouts(DateTime first, DateTime last) =>
      _run(() async {
        _requireAvailable();
        if (workoutsPermissionStatus == HealthPermission.denied) {
          throw const PermissionFailure('Workouts read access not granted');
        }
        final days = readDays(first, last);
        final from = days.first.start;
        final to = days.last.end;
        return [
          for (final w in workoutList)
            if (!w.start.isBefore(from) && w.start.isBefore(to)) w,
        ]..sort((a, b) => a.start.compareTo(b.start));
      });

  @override
  Future<Result<void>> openSettings() => _run(() async {
    if (status == HealthAvailability.unsupported) {
      throw const HealthFailure();
    }
    settingsOpened++;
  });

  List<DailySteps> _read(DateTime first, DateTime last) {
    _requireAvailable();
    if (permissionStatus == HealthPermission.denied) {
      throw const PermissionFailure('Steps read access not granted');
    }
    return [
      for (final day in readDays(first, last))
        DailySteps(day.start, _count(day.start, day.end)),
    ];
  }

  int _count(DateTime start, DateTime end) {
    final now = _clock();
    if (!now.isAfter(start)) return 0;
    final full = stepsFor(start);
    if (!now.isBefore(end)) return full;
    final elapsed = now.difference(start).inSeconds;
    return full * elapsed ~/ end.difference(start).inSeconds;
  }

  void _requireAvailable() {
    if (status != HealthAvailability.available) {
      throw const HealthFailure();
    }
  }

  Future<Result<T>> _run<T>(Future<T> Function() body) => guard(() {
    final failure = this.failure;
    if (failure != null) throw failure;
    return body();
  });
}

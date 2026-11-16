import 'package:forge_core/forge_core.dart';

import 'health_models.dart';

/// The longest range [HealthSteps.dailySteps] and [HealthSteps.workouts]
/// read at once.
const maxStepDays = 366;

/// Step counts and workouts from the platform health store, read only.
/// Steps and workouts have their own access. Failures are
/// [HealthFailure] (no usable store), [PermissionFailure] (Android: read
/// access missing), [ValidationFailure] or [UnknownFailure].
abstract interface class HealthSteps {
  Future<Result<HealthAvailability>> availability();

  Future<Result<HealthPermission>> permission();

  /// Shows the platform's permission sheet when it still can, then returns
  /// the outcome. iOS shows it only the first time, so calling this whenever
  /// steps are first needed is harmless there.
  Future<Result<HealthPermission>> requestPermission();

  /// Steps of the local calendar day containing [day]; the current day
  /// counts up to now.
  Future<Result<int>> stepsOn(DateTime day);

  /// One entry per local calendar day from [first] to [last] inclusive,
  /// oldest first, days without data as zero. Times of day are ignored.
  /// At most [maxStepDays] days.
  /// Android reads only 30 days before the permission was first granted.
  Future<Result<List<DailySteps>>> dailySteps(DateTime first, DateTime last);

  /// Read access to workouts, asked for apart from steps.
  Future<Result<HealthPermission>> workoutsPermission();

  /// Shows the platform's permission sheet for workouts when it still can,
  /// then returns the outcome, as [requestPermission] does for steps.
  Future<Result<HealthPermission>> requestWorkoutsPermission();

  /// The workouts that started on the local calendar days from [first] to
  /// [last] inclusive, oldest first. At most [maxStepDays] days.
  Future<Result<List<HealthWorkout>>> workouts(DateTime first, DateTime last);

  /// Where the user fixes access: the Health Connect settings, the store
  /// page when Health Connect is [HealthAvailability.notInstalled], or the
  /// app's page in iOS Settings.
  Future<Result<void>> openSettings();
}

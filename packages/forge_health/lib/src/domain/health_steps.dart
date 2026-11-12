import 'package:forge_core/forge_core.dart';

import 'health_models.dart';

/// Step counts from the platform health store, read only. Failures are
/// [HealthFailure], [ValidationFailure] or [UnknownFailure].
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
  /// Android reads only 30 days before the permission was first granted.
  Future<Result<List<DailySteps>>> dailySteps(DateTime first, DateTime last);

  /// Where the user fixes access: the Health Connect settings, the store
  /// page when Health Connect is [HealthAvailability.notInstalled], or the
  /// app's page in iOS Settings.
  Future<Result<void>> openSettings();
}

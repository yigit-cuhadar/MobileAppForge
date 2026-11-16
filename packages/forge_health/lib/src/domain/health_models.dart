import 'package:forge_core/forge_core.dart';

/// Whether the device has a health store the app can read.
enum HealthAvailability {
  available,

  /// Android: Health Connect is missing or needs an update. `openSettings`
  /// sends the user to the store to get it.
  notInstalled,

  /// No health store: Android before 9, an iPad without the Health app, or
  /// a platform other than iOS and Android.
  unsupported,
}

/// Read access to step counts or to workouts.
enum HealthPermission {
  granted,

  /// Android: not granted, whether never asked or refused. After two
  /// refusals Health Connect stops showing its dialog; send the user to
  /// `openSettings` instead.
  denied,

  /// iOS: HealthKit never reveals whether read access was granted. Read
  /// anyway: a refusal reads as zero steps.
  undetermined,
}

/// The steps of one local calendar day.
final class DailySteps extends Equatable {
  const DailySteps(this.day, this.count);

  /// Local midnight starting the day.
  final DateTime day;

  /// De-duplicated across sources (phone, watch) as the platform aggregates
  /// them.
  final int count;

  @override
  List<Object?> get props => [day, count];
}

/// The kind of a [HealthWorkout], as the health store records it. iOS has
/// no treadmill kind: a treadmill run reads as [running].
enum HealthWorkoutType {
  running,
  treadmillRunning,
  walking,
  hiking,
  cycling,
  elliptical,
  rowing,
  stairClimbing,
  swimming,
  jumpRope,
  hiit,
  strength,
  other,
}

/// A workout another app (or a watch) saved to the health store.
final class HealthWorkout extends Equatable {
  const HealthWorkout({
    required this.id,
    required this.type,
    required this.start,
    required this.duration,
    this.distanceMeters,
    this.energyKcal,
    this.averageHeartRate,
    required this.source,
  });

  /// The store's id of the workout, stable across reads.
  final String id;
  final HealthWorkoutType type;
  final DateTime start;
  final Duration duration;
  final double? distanceMeters;

  /// Total energy burned, in kilocalories.
  final double? energyKcal;

  /// Beats per minute, from the heart rate samples taken during it.
  final int? averageHeartRate;

  /// Who saved it: the app's name on iOS, its package name (such as
  /// `com.strava`) on Android, where Health Connect gives no name.
  final String source;

  @override
  List<Object?> get props => [
    id,
    type,
    start,
    duration,
    distanceMeters,
    energyKcal,
    averageHeartRate,
    source,
  ];
}

/// No usable health store; `availability` tells why. Missing read access
/// is a [PermissionFailure], anything unrecognised an [UnknownFailure].
final class HealthFailure extends Failure {
  const HealthFailure([
    super.message = 'Health data unavailable',
    Object? cause,
  ]) : super(cause: cause);
}

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

/// Read access to step counts.
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

/// A health store call that could not be served. Anything unrecognised is an
/// [UnknownFailure].
final class HealthFailure extends Failure {
  const HealthFailure(this.reason, [String? message, Object? cause])
    : super(message ?? 'Health data unavailable', cause: cause);

  final HealthFailureReason reason;

  @override
  String toString() => 'HealthFailure(${reason.name}): $message';
}

enum HealthFailureReason {
  /// No usable health store; `availability` tells why.
  unavailable,

  /// Android: step read access is not granted.
  denied,
}

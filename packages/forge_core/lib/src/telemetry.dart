import 'result.dart';

/// Analytics and crash reporting on this device. Collection is per user,
/// never per device: it follows one user's own answer, and is off while
/// that is unknown. A uid is whatever identifies who answered: the signed-in
/// user's id, or one fixed key in an app without accounts.
abstract interface class Telemetry {
  /// From now on collection follows [uid] (null: nobody). Another user than
  /// before turns it off until [apply] gives their answer.
  Future<Result<void>> follow(String? uid);

  /// Collects for [uid] only with [consent], from now on and when the app
  /// next starts with them signed in. Of quick answers the latest wins.
  Future<Result<void>> apply(String uid, bool consent);

  /// After [uid]'s account is deleted: records no for them, stops
  /// collecting, and drops this device's analytics id and unsent crash
  /// reports.
  Future<Result<void>> forget(String uid);

  /// Records the event [name] with [parameters] if collection is on, and
  /// drops it otherwise. Never fails: an event that cannot be recorded is
  /// only logged, as losing one is expected.
  Future<void> logEvent(String name, [Map<String, Object> parameters]);
}

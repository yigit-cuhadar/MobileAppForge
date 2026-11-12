import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:forge_core/forge_core.dart';
import 'package:health/health.dart';

import '../domain/health_models.dart';
import '../domain/health_steps.dart';
import 'health_data_source.dart';
import 'local_days.dart';

/// [HealthSteps] over Apple HealthKit and Android Health Connect.
class PlatformHealthSteps implements HealthSteps {
  const PlatformHealthSteps(this._source);

  final HealthDataSource _source;

  @override
  Future<Result<HealthAvailability>> availability() => _guard(_availability);

  @override
  Future<Result<HealthPermission>> permission() => _guard(() async {
    _requirePlatform();
    return _permission(await _source.hasStepsPermission());
  });

  @override
  Future<Result<HealthPermission>> requestPermission() => _guard(() async {
    switch (_platform) {
      case _Platform.android:
        // The plugin's request can hang when access is already granted.
        if (await _source.hasStepsPermission() ?? false) {
          return HealthPermission.granted;
        }
        return await _source.requestStepsPermission()
            ? HealthPermission.granted
            : HealthPermission.denied;
      case _Platform.ios:
        if (!await _source.requestStepsPermission()) {
          throw const UnknownFailure('HealthKit authorization failed');
        }
        return HealthPermission.undetermined;
      case _Platform.other:
        throw const HealthFailure(HealthFailureReason.unavailable);
    }
  });

  @override
  Future<Result<int>> stepsOn(DateTime day) => _guard(() async {
    final days = await _read(day, day);
    return days.single.count;
  });

  @override
  Future<Result<List<DailySteps>>> dailySteps(DateTime first, DateTime last) =>
      _guard(() => _read(first, last));

  @override
  Future<Result<void>> openSettings() => _guard(() async {
    switch (await _availability()) {
      case HealthAvailability.available:
        await (_platform == _Platform.android
            ? _source.openHealthConnectSettings()
            : _source.openAppSettings());
      case HealthAvailability.notInstalled:
        await _source.installHealthConnect();
      case HealthAvailability.unsupported:
        throw const HealthFailure(HealthFailureReason.unavailable);
    }
  });

  Future<HealthAvailability> _availability() async {
    switch (_platform) {
      case _Platform.android:
        return switch (await _source.healthConnectStatus()) {
          HealthConnectSdkStatus.sdkAvailable => HealthAvailability.available,
          HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
            HealthAvailability.notInstalled,
          HealthConnectSdkStatus.sdkUnavailable =>
            HealthAvailability.unsupported,
          null => throw const UnknownFailure(
            'Health Connect status could not be read',
          ),
        };
      case _Platform.ios:
        return await _source.isHealthKitAvailable()
            ? HealthAvailability.available
            : HealthAvailability.unsupported;
      case _Platform.other:
        return HealthAvailability.unsupported;
    }
  }

  Future<List<DailySteps>> _read(DateTime first, DateTime last) async {
    _requirePlatform();
    if (startOfDay(last).isBefore(startOfDay(first))) {
      throw ValidationFailure('$last is before $first');
    }
    final days = localDays(first, last);
    final counts = await Future.wait([
      for (final day in days) _source.totalSteps(day.start, day.end),
    ]);
    if (counts.contains(null)) throw await _readFailure();
    return [
      for (var i = 0; i < days.length; i++)
        DailySteps(days[i].start, counts[i]!),
    ];
  }

  /// Health Connect reports a refused read only as a missing total.
  Future<Failure> _readFailure() async =>
      await _source.hasStepsPermission() == false
      ? const HealthFailure(HealthFailureReason.denied)
      : const UnknownFailure('Steps could not be read');

  static HealthPermission _permission(bool? granted) => switch (granted) {
    true => HealthPermission.granted,
    false => HealthPermission.denied,
    null => HealthPermission.undetermined,
  };

  static _Platform get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.android => _Platform.android,
    TargetPlatform.iOS => _Platform.ios,
    _ => _Platform.other,
  };

  static void _requirePlatform() {
    if (_platform == _Platform.other) {
      throw const HealthFailure(HealthFailureReason.unavailable);
    }
  }

  static Future<Result<T>> _guard<T>(Future<T> Function() body) =>
      guard(body, mapper: _mapError);
}

enum _Platform { android, ios, other }

/// The plugin throws [UnsupportedError] for any Health Connect call while it
/// is missing.
Failure? _mapError(Object error) => switch (error) {
  UnsupportedError() => HealthFailure(
    HealthFailureReason.unavailable,
    error.message,
    error,
  ),
  PlatformException() => UnknownFailure(error.message ?? error.code, error),
  HealthException() => UnknownFailure('$error', error),
  _ => null,
};

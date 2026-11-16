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

  /// Days read at once, to stay clear of Health Connect's rate limits.
  static const _parallelReads = 5;

  static final _playStoreUrl = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata',
  );

  @override
  Future<Result<HealthAvailability>> availability() => _guard(_availability);

  @override
  Future<Result<HealthPermission>> permission() => _guard(() async {
    await _requireIosStore();
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
        await _requireIosStore();
        if (!await _source.requestStepsPermission()) {
          throw const UnknownFailure('HealthKit authorization failed');
        }
        return HealthPermission.undetermined;
      case _Platform.other:
        throw const HealthFailure();
    }
  });

  @override
  Future<Result<HealthPermission>> workoutsPermission() => _guard(() async {
    await _requireIosStore();
    return _permission(await _source.hasWorkoutsPermission());
  });

  @override
  Future<Result<HealthPermission>> requestWorkoutsPermission() =>
      _guard(() async {
        switch (_platform) {
          case _Platform.android:
            // As for steps: the request can hang when access is granted.
            if (await _source.hasWorkoutsPermission() ?? false) {
              return HealthPermission.granted;
            }
            return await _source.requestWorkoutsPermission()
                ? HealthPermission.granted
                : HealthPermission.denied;
          case _Platform.ios:
            await _requireIosStore();
            if (!await _source.requestWorkoutsPermission()) {
              throw const UnknownFailure('HealthKit authorization failed');
            }
            return HealthPermission.undetermined;
          case _Platform.other:
            throw const HealthFailure();
        }
      });

  @override
  Future<Result<List<HealthWorkout>>> workouts(DateTime first, DateTime last) =>
      _guard(() async {
        final days = readDays(first, last);
        switch (_platform) {
          case _Platform.android:
            // A refused read comes back as no workouts; ask first.
            if (await _source.hasWorkoutsPermission() == false) {
              throw const PermissionFailure('Workouts read access not granted');
            }
          case _Platform.ios:
            await _requireIosStore();
          case _Platform.other:
            throw const HealthFailure();
        }
        final raw = await _source.workouts(days.first.start, days.last.end)
          ..sort((a, b) => a.start.compareTo(b.start));
        // Heart rate is optional: without it the average is left out.
        final heartRate = await _source.hasHeartRatePermission() != false;
        final averages = <int?>[];
        for (var i = 0; i < raw.length; i += _parallelReads) {
          averages.addAll(
            await Future.wait([
              for (final w in raw.skip(i).take(_parallelReads))
                heartRate ? _averageHeartRate(w.start, w.end) : Future.value(),
            ]),
          );
        }
        return [
          for (final (i, w) in raw.indexed)
            HealthWorkout(
              id: w.id,
              type: _type(w.activity),
              start: w.start,
              duration: w.end.difference(w.start),
              distanceMeters: w.distanceMeters?.toDouble(),
              energyKcal: w.energyKcal?.toDouble(),
              averageHeartRate: averages[i],
              source: w.source,
            ),
        ];
      });

  Future<int?> _averageHeartRate(DateTime start, DateTime end) async {
    final rates = await _source.heartRates(start, end);
    if (rates.isEmpty) return null;
    return (rates.reduce((a, b) => a + b) / rates.length).round();
  }

  static HealthWorkoutType _type(
    HealthWorkoutActivityType activity,
  ) => switch (activity) {
    HealthWorkoutActivityType.RUNNING => HealthWorkoutType.running,
    HealthWorkoutActivityType.RUNNING_TREADMILL =>
      HealthWorkoutType.treadmillRunning,
    HealthWorkoutActivityType.WALKING ||
    HealthWorkoutActivityType.WALKING_TREADMILL => HealthWorkoutType.walking,
    HealthWorkoutActivityType.HIKING => HealthWorkoutType.hiking,
    HealthWorkoutActivityType.BIKING ||
    HealthWorkoutActivityType.BIKING_STATIONARY => HealthWorkoutType.cycling,
    HealthWorkoutActivityType.ELLIPTICAL => HealthWorkoutType.elliptical,
    HealthWorkoutActivityType.ROWING ||
    HealthWorkoutActivityType.ROWING_MACHINE => HealthWorkoutType.rowing,
    HealthWorkoutActivityType.STAIR_CLIMBING ||
    HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE ||
    HealthWorkoutActivityType.STAIRS => HealthWorkoutType.stairClimbing,
    HealthWorkoutActivityType.SWIMMING ||
    HealthWorkoutActivityType.SWIMMING_POOL ||
    HealthWorkoutActivityType.SWIMMING_OPEN_WATER => HealthWorkoutType.swimming,
    HealthWorkoutActivityType.JUMP_ROPE => HealthWorkoutType.jumpRope,
    HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING =>
      HealthWorkoutType.hiit,
    HealthWorkoutActivityType.STRENGTH_TRAINING ||
    HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING ||
    HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING ||
    HealthWorkoutActivityType.WEIGHTLIFTING => HealthWorkoutType.strength,
    _ => HealthWorkoutType.other,
  };

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
            ? _openHealthConnectSettings()
            : _open(Uri.parse('app-settings:')));
      case HealthAvailability.notInstalled:
        try {
          await _source.openHealthConnectInStore();
        } on PlatformException {
          await _open(_playStoreUrl);
        }
      case HealthAvailability.unsupported:
        throw const HealthFailure();
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
        return await _isHealthKitAvailable()
            ? HealthAvailability.available
            : HealthAvailability.unsupported;
      case _Platform.other:
        return HealthAvailability.unsupported;
    }
  }

  Future<List<DailySteps>> _read(DateTime first, DateTime last) async {
    final days = readDays(first, last);
    switch (_platform) {
      case _Platform.android:
        // The plugin's step total skips its Health Connect check, and a
        // refused read comes back only as a missing total; asking first
        // tells both apart (a missing Health Connect throws here).
        if (await _source.hasStepsPermission() == false) {
          throw const PermissionFailure('Steps read access not granted');
        }
      case _Platform.ios:
        await _requireIosStore();
      case _Platform.other:
        throw const HealthFailure();
    }
    final counts = <int>[];
    for (var i = 0; i < days.length; i += _parallelReads) {
      final batch = await Future.wait([
        for (final day in days.skip(i).take(_parallelReads))
          _source.totalSteps(day.start, day.end),
      ]);
      for (final count in batch) {
        counts.add(count ?? (throw const UnknownFailure('Steps unreadable')));
      }
    }
    return [
      for (var i = 0; i < days.length; i++)
        DailySteps(days[i].start, counts[i]),
    ];
  }

  /// The app's own Health Connect permission page (Android 14+), else the
  /// Health Connect home: the system one (14+), then the app's (9-13).
  Future<void> _openHealthConnectSettings() async {
    final package = await _source.packageName();
    final newer = [
      (
        'android.health.connect.action.MANAGE_HEALTH_PERMISSIONS',
        {'android.intent.extra.PACKAGE_NAME': package},
      ),
      ('android.health.connect.action.HEALTH_HOME_SETTINGS', null),
    ];
    for (final (action, arguments) in newer) {
      try {
        return await _source.launchAndroidAction(action, arguments: arguments);
      } on PlatformException {
        // Not on this Android version; try the next.
      }
    }
    await _source.launchAndroidAction(
      'androidx.health.ACTION_HEALTH_CONNECT_SETTINGS',
    );
  }

  Future<void> _open(Uri url) async {
    if (!await _source.openUrl(url)) {
      throw UnknownFailure('Could not open $url');
    }
  }

  /// A renamed plugin method must not hide HealthKit; assume it is there.
  Future<bool> _isHealthKitAvailable() async {
    try {
      return await _source.isHealthKitAvailable();
    } on MissingPluginException {
      return true;
    }
  }

  /// Throws [HealthFailure] on iOS devices without HealthKit and on other
  /// platforms. Android checks Health Connect inside its calls.
  Future<void> _requireIosStore() async {
    switch (_platform) {
      case _Platform.android:
        return;
      case _Platform.ios:
        if (!await _isHealthKitAvailable()) throw const HealthFailure();
      case _Platform.other:
        throw const HealthFailure();
    }
  }

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

  static Future<Result<T>> _guard<T>(Future<T> Function() body) =>
      guard(body, mapper: _mapError);
}

enum _Platform { android, ios, other }

/// The plugin throws [UnsupportedError] for any Health Connect call while it
/// is missing.
Failure? _mapError(Object error) => switch (error) {
  UnsupportedError() => HealthFailure(
    error.message ?? 'Health Connect unavailable',
    error,
  ),
  PlatformException() => UnknownFailure(error.message ?? error.code, error),
  HealthException() => UnknownFailure('$error', error),
  _ => null,
};

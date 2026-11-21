import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// A workout as the plugin reads it.
typedef RawWorkout = ({
  String id,
  HealthWorkoutActivityType activity,
  DateTime start,
  DateTime end,
  int? distanceMeters,
  int? energyKcal,
  String source,
});

/// Thin wrapper over the `health` plugin, intents and URLs; throws.
class HealthDataSource {
  final _health = Health();

  // The plugin's iOS side answers this, but its Dart API does not expose it.
  static const _channel = MethodChannel('flutter_health');

  static const _steps = [HealthDataType.STEPS];

  /// What reading a workout needs. On Android the plugin also reads the
  /// distance, energy and steps recorded during each workout, and a refused
  /// one of them empties the whole read, so all are asked together.
  static List<HealthDataType> get _workouts =>
      defaultTargetPlatform == TargetPlatform.android
      ? const [
          HealthDataType.WORKOUT,
          HealthDataType.DISTANCE_DELTA,
          HealthDataType.TOTAL_CALORIES_BURNED,
          HealthDataType.STEPS,
        ]
      : const [HealthDataType.WORKOUT];

  static const _heartRate = [HealthDataType.HEART_RATE];

  /// iOS: false on devices without HealthKit, e.g. older iPads. Throws
  /// [MissingPluginException] if the plugin drops the method.
  Future<bool> isHealthKitAvailable() async =>
      await _channel.invokeMethod<bool>('checkIfHealthDataAvailable') ?? false;

  /// Android: null when the status could not be read.
  Future<HealthConnectSdkStatus?> healthConnectStatus() =>
      _health.getHealthConnectSdkStatus();

  /// Null when the platform does not tell (iOS read access). Throws
  /// [UnsupportedError] on Android without a working Health Connect.
  Future<bool?> hasStepsPermission() => _health.hasPermissions(_steps);

  /// Null when the platform does not tell (iOS read access). Throws
  /// [UnsupportedError] on Android without a working Health Connect.
  Future<bool?> hasWorkoutsPermission() => _health.hasPermissions(_workouts);

  /// As [hasWorkoutsPermission], for heart rate, which a workout's average
  /// is read from but does not need.
  Future<bool?> hasHeartRatePermission() => _health.hasPermissions(_heartRate);

  /// Asks for steps, workouts and heart rate in one sheet: iOS shows no
  /// second sheet right after the first closes. Android: whether all were
  /// granted. iOS: whether the sheet was handled.
  Future<bool> requestPermissions() => _health.requestAuthorization([
    ...{..._steps, ..._workouts, ..._heartRate},
  ]);

  /// The workouts that started in [start, end). Android returns none, with
  /// no error, when a read it needs was refused.
  Future<List<RawWorkout>> workouts(DateTime start, DateTime end) async {
    final points = await _health.getHealthDataFromTypes(
      types: const [HealthDataType.WORKOUT],
      startTime: start,
      endTime: end,
    );
    return [
      for (final point in points)
        if (point.value case final WorkoutHealthValue value)
          (
            id: point.uuid,
            activity: value.workoutActivityType,
            start: point.dateFrom,
            end: point.dateTo,
            distanceMeters: value.totalDistance,
            energyKcal: value.totalEnergyBurned,
            source: point.sourceName,
          ),
    ];
  }

  /// The heart rate samples, in beats per minute, taken in [start, end].
  Future<List<num>> heartRates(DateTime start, DateTime end) async {
    final points = await _health.getHealthDataFromTypes(
      types: _heartRate,
      startTime: start,
      endTime: end,
    );
    return [
      for (final point in points)
        if (point.value case final NumericHealthValue value) value.numericValue,
    ];
  }

  /// The platform's aggregate of [start, end). Null when Health Connect
  /// could not read; the plugin does not say why.
  Future<int?> totalSteps(DateTime start, DateTime end) =>
      _health.getTotalStepsInInterval(start, end);

  /// The app's own package name (Android) or bundle id (iOS).
  Future<String> packageName() async =>
      (await PackageInfo.fromPlatform()).packageName;

  /// Starts an Android activity for [action]; throws [PlatformException]
  /// when no activity handles it.
  Future<void> launchAndroidAction(
    String action, {
    Map<String, dynamic>? arguments,
  }) => AndroidIntent(action: action, arguments: arguments).launch();

  /// Opens the Play Store's Health Connect page with its onboarding, as the
  /// plugin's own `installHealthConnect` does, but reports a missing Play
  /// Store as [PlatformException] instead of ignoring it.
  Future<void> openHealthConnectInStore() => const AndroidIntent(
    action: 'android.intent.action.VIEW',
    data:
        'market://details?id=com.google.android.apps.healthdata'
        '&url=healthconnect%3A%2F%2Fonboarding',
    package: 'com.android.vending',
  ).launch();

  /// Whether something opened [url].
  Future<bool> openUrl(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thin wrapper over the `health` plugin and the settings intents; throws.
class HealthDataSource {
  final _health = Health();

  // The plugin's iOS side answers this, but its Dart API does not expose it.
  static const _channel = MethodChannel('flutter_health');

  static const _steps = [HealthDataType.STEPS];

  /// iOS: false on devices without HealthKit, e.g. older iPads.
  Future<bool> isHealthKitAvailable() async =>
      await _channel.invokeMethod<bool>('checkIfHealthDataAvailable') ?? false;

  /// Android: null when the status could not be read.
  Future<HealthConnectSdkStatus?> healthConnectStatus() =>
      _health.getHealthConnectSdkStatus();

  /// Null when the platform does not tell (iOS read access). Throws
  /// [UnsupportedError] on Android without Health Connect.
  Future<bool?> hasStepsPermission() => _health.hasPermissions(_steps);

  /// Android: whether it was granted. iOS: whether the sheet was handled.
  Future<bool> requestStepsPermission() => _health.requestAuthorization(_steps);

  /// The platform's aggregate of [start, end); null when Health Connect
  /// refused the read.
  Future<int?> totalSteps(DateTime start, DateTime end) =>
      _health.getTotalStepsInInterval(start, end);

  Future<void> installHealthConnect() => _health.installHealthConnect();

  /// Health Connect is part of the system from Android 14, with its own
  /// settings action; before that it is an app with the androidx action.
  Future<void> openHealthConnectSettings() async {
    try {
      await const AndroidIntent(
        action: 'android.health.connect.action.HEALTH_HOME_SETTINGS',
      ).launch();
    } on PlatformException {
      await const AndroidIntent(
        action: 'androidx.health.ACTION_HEALTH_CONNECT_SETTINGS',
      ).launch();
    }
  }

  /// The app's page in iOS Settings, which lists its Health access.
  Future<void> openAppSettings() async {
    if (!await launchUrl(Uri.parse('app-settings:'))) {
      throw PlatformException(
        code: 'settings',
        message: 'Could not open app settings',
      );
    }
  }
}

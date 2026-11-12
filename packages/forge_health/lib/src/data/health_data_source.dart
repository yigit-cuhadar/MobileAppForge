import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thin wrapper over the `health` plugin, intents and URLs; throws.
class HealthDataSource {
  final _health = Health();

  // The plugin's iOS side answers this, but its Dart API does not expose it.
  static const _channel = MethodChannel('flutter_health');

  static const _steps = [HealthDataType.STEPS];

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

  /// Android: whether it was granted. iOS: whether the sheet was handled.
  Future<bool> requestStepsPermission() => _health.requestAuthorization(_steps);

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

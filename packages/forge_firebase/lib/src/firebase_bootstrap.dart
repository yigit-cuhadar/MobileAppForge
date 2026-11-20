import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:forge_core/forge_core.dart';
import 'package:path_provider/path_provider.dart';

import 'firebase_telemetry.dart';

/// Initializes Firebase, activates App Check and routes uncaught errors to
/// Crashlytics, without changing whether Analytics and Crashlytics collect, so
/// it is safe in any entry point, background ones included.
///
/// App Check attests the app with App Attest (DeviceCheck below iOS 14) and
/// Play Integrity; debug builds, the iOS simulator among them, use the debug
/// provider, whose token the native log prints on first launch. Whether
/// Firebase rejects requests without a valid token is set per product in the
/// console. On iOS the Runner needs the
/// `com.apple.developer.devicecheck.appattest-environment` entitlement.
///
/// Collection stays as the native config sets it (off: `tools/new_app.sh`
/// writes `FIREBASE_ANALYTICS_COLLECTION_ENABLED` and
/// `FirebaseCrashlyticsCollectionEnabled` into Info.plist,
/// `firebase_analytics_collection_enabled` and
/// `firebase_crashlytics_collection_enabled` into AndroidManifest.xml) until
/// the main entry point calls [FirebaseTelemetry.restore] and the app
/// applies answers through the returned [Telemetry]. It only ever collects
/// in release builds of the prod environment, so development never
/// pollutes production data.
///
/// Keep the instance the main entry point gets and register it once; a
/// background entry point ignores the return value.
Future<FirebaseTelemetry> initFirebase({
  required FirebaseOptions options,
  required AppEnv env,
}) async {
  await Firebase.initializeApp(options: options);
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestWithDeviceCheckFallbackProvider(),
  );

  final crashlytics = FirebaseCrashlytics.instance;
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
  Log.onError = (error, stack, reason) =>
      crashlytics.recordError(error, stack, reason: reason);

  return FirebaseTelemetry(
    allowed: env.isProd && kReleaseMode,
    directory: getApplicationSupportDirectory,
    analytics: FirebaseAnalytics.instance,
    crashlytics: crashlytics,
  );
}

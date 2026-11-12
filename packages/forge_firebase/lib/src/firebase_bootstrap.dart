import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:forge_core/forge_core.dart';
import 'package:path_provider/path_provider.dart';

import 'firebase_telemetry.dart';

/// Initializes Firebase and routes uncaught errors to Crashlytics, without
/// changing whether Analytics and Crashlytics collect, so it is safe in any
/// entry point, background ones included.
///
/// Collection stays as the native config sets it (the app turns both off
/// there: `FIREBASE_ANALYTICS_COLLECTION_ENABLED` and
/// `FirebaseCrashlyticsCollectionEnabled` in Info.plist,
/// `firebase_analytics_collection_enabled` and
/// `firebase_crashlytics_collection_enabled` in AndroidManifest.xml) until
/// the main entry point calls [FirebaseTelemetry.restore] and the app
/// applies users' answers through the returned [Telemetry]. It only ever
/// collects in release builds of the prod environment, so development
/// never pollutes production data.
Future<FirebaseTelemetry> initFirebase({
  required FirebaseOptions options,
  required AppEnv env,
}) async {
  await Firebase.initializeApp(options: options);

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

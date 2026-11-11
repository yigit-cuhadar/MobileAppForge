import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:forge_core/forge_core.dart';

/// Initializes Firebase and routes uncaught errors to Crashlytics.
///
/// Crash and analytics collection run only in release builds of the prod
/// environment, so development never pollutes production data.
Future<void> initFirebase({
  required FirebaseOptions options,
  required AppEnv env,
}) async {
  await Firebase.initializeApp(options: options);

  final collect = env.isProd && kReleaseMode;
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(collect);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(collect);

  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
  Log.onError = (error, stack, reason) =>
      crashlytics.recordError(error, stack, reason: reason);
}

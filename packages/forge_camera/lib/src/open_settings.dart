import 'package:app_settings/app_settings.dart';

/// Opens this app's page in the system settings, where a refused camera
/// access is turned back on: the app's settings on iOS, its app details on
/// Android.
Future<void> openSettings() => AppSettings.openAppSettings();

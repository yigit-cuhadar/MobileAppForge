import 'package:flutter/foundation.dart';
import 'package:forge_core/forge_core.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/remote_app_gate_repository.dart';
import 'domain/app_gate_repository.dart';
import 'domain/app_gate_usecases.dart';
import 'presentation/app_gate_cubit.dart';

/// Registers the gate: a minimum version, a recommended version and a
/// maintenance switch from Remote Config. Needs a `RemoteConfigRepository`
/// with [remoteConfigDefaults]; `start()` the [AppGateCubit] once it is
/// initialized, before `runApp`.
class AppGateModule implements FeatureModule {
  const AppGateModule({required this.appStore, required this.playStore});

  /// This app's page on the App Store and on Google Play.
  final Uri appStore;
  final Uri playStore;

  /// The Remote Config keys the gate reads, with defaults that ask nothing.
  static const remoteConfigDefaults = AppGateKeys.defaults;

  @override
  void register(GetIt sl) {
    final (platform, store) = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => ('ios', appStore),
      TargetPlatform.android => ('android', playStore),
      _ => (null, appStore),
    };
    sl
      ..registerLazySingleton<AppGateRepository>(
        () => RemoteAppGateRepository(
          sl(),
          platform: platform,
          installedVersion: () async =>
              (await PackageInfo.fromPlatform()).version,
          directory: getApplicationSupportDirectory,
          launchStore: () =>
              launchUrl(store, mode: LaunchMode.externalApplication),
        ),
      )
      ..registerFactory(() => CheckAppGate(sl()))
      ..registerFactory(() => RefreshAppGate(sl()))
      ..registerFactory(() => DismissUpdate(sl()))
      ..registerFactory(() => OpenStore(sl()))
      ..registerLazySingleton(
        () => AppGateCubit(
          check: sl(),
          refresh: sl(),
          dismissUpdate: sl(),
          openStore: sl(),
        ),
      );
  }
}

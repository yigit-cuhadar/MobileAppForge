import 'package:forge_core/forge_core.dart';
import 'package:get_it/get_it.dart';

import 'data/fake_health_steps.dart';
import 'data/health_data_source.dart';
import 'data/platform_health_steps.dart';
import 'domain/health_steps.dart';
import 'domain/health_usecases.dart';

/// Registers [HealthSteps] and its use cases.
class HealthModule implements FeatureModule {
  /// Reads the platform health store.
  const HealthModule() : _fake = null;

  /// Serves [fake] instead, e.g. on a simulator without health data. Its
  /// controls stay reachable through `sl<FakeHealthSteps>()`.
  const HealthModule.fake(FakeHealthSteps this._fake);

  final FakeHealthSteps? _fake;

  @override
  void register(GetIt sl) {
    final fake = _fake;
    if (fake == null) {
      sl.registerLazySingleton<HealthSteps>(
        () => PlatformHealthSteps(HealthDataSource()),
      );
    } else {
      sl
        ..registerSingleton(fake)
        ..registerSingleton<HealthSteps>(fake);
    }
    sl
      ..registerFactory(() => GetHealthAvailability(sl()))
      ..registerFactory(() => GetStepsPermission(sl()))
      ..registerFactory(() => RequestStepsPermission(sl()))
      ..registerFactory(() => GetStepsOn(sl()))
      ..registerFactory(() => GetDailySteps(sl()))
      ..registerFactory(() => OpenHealthSettings(sl()));
  }
}

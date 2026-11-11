import 'package:get_it/get_it.dart';

/// The app-wide service locator. Only composition roots and pages that create
/// cubits read from it; domain and data classes receive dependencies through
/// their constructors.
final GetIt sl = GetIt.instance;

/// A feature's dependency registrations: data source → repository → use cases
/// → cubit factories.
abstract interface class FeatureModule {
  void register(GetIt sl);
}

void registerModules(List<FeatureModule> modules) {
  for (final module in modules) {
    module.register(sl);
  }
}

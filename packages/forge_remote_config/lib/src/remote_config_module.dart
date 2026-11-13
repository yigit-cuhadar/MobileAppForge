import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:forge_core/forge_core.dart';
import 'package:get_it/get_it.dart';

import 'data/fake_remote_config_repository.dart';
import 'data/firebase_remote_config_repository.dart';
import 'domain/remote_config_repository.dart';

/// Where values come from: Firebase Remote Config or the in-memory fake.
sealed class RemoteConfigBackend {
  const RemoteConfigBackend();
}

/// Firebase Remote Config. Values younger than [minimumFetchInterval] are
/// not fetched again.
final class FirebaseRemoteConfigBackend extends RemoteConfigBackend {
  const FirebaseRemoteConfigBackend({required this.minimumFetchInterval});

  final Duration minimumFetchInterval;
}

/// The fake. Its controls are on the registered
/// [FakeRemoteConfigRepository].
final class FakeRemoteConfigBackend extends RemoteConfigBackend {
  const FakeRemoteConfigBackend();
}

/// Registers [RemoteConfigRepository] with the app's [defaults]: bools,
/// numbers and strings. Call after
/// Firebase is initialized, then `initialize()` the repository once.
class RemoteConfigModule implements FeatureModule {
  const RemoteConfigModule({required this.defaults, required this.backend});

  final Map<String, Object> defaults;
  final RemoteConfigBackend backend;

  @override
  void register(GetIt sl) {
    switch (backend) {
      case FirebaseRemoteConfigBackend(:final minimumFetchInterval):
        sl.registerLazySingleton<RemoteConfigRepository>(
          () => FirebaseRemoteConfigRepository(
            FirebaseRemoteConfig.instance,
            defaults: defaults,
            minimumFetchInterval: minimumFetchInterval,
          ),
        );
      case FakeRemoteConfigBackend():
        sl
          ..registerLazySingleton(() => FakeRemoteConfigRepository(defaults))
          ..registerLazySingleton<RemoteConfigRepository>(
            () => sl<FakeRemoteConfigRepository>(),
          );
    }
  }
}

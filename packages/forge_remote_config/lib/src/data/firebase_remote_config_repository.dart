import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_firebase/forge_firebase.dart';

import '../domain/remote_config_repository.dart';
import 'remote_values.dart';

/// [RemoteConfigRepository] on Firebase Remote Config. The SDK is not given
/// the defaults: a key without a server value reads the app's default here,
/// so reads are the same before and after [initialize].
class FirebaseRemoteConfigRepository implements RemoteConfigRepository {
  /// [defaults] are bools, numbers and strings.
  FirebaseRemoteConfigRepository(
    this._config, {
    required this._defaults,
    required this._minimumFetchInterval,
  });

  final FirebaseRemoteConfig _config;
  final Map<String, Object> _defaults;
  final Duration _minimumFetchInterval;

  @override
  Future<Result<void>> initialize() async {
    final ready = await guard(() async {
      await _config.setConfigSettings(
        RemoteConfigSettings(
          // The SDK's default; nothing waits for the fetch.
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: _minimumFetchInterval,
        ),
      );
      await _config.ensureInitialized();
      await _config.activate();
    }, mapper: mapFirebaseError);
    // Offline or throttled is expected: logged quietly, not reported.
    unawaited(
      _config.fetch().catchError(
        (Object error) => Log.d('RemoteConfig', 'fetch failed: $error'),
      ),
    );
    return ready;
  }

  @override
  String getString(String key) => readString(_value(key));

  @override
  bool getBool(String key) => readBool(_value(key));

  @override
  int getInt(String key) => readInt(_value(key));

  @override
  double getDouble(String key) => readDouble(_value(key));

  Object? _value(String key) {
    final value = _config.getValue(key);
    return value.source == ValueSource.valueRemote
        ? value.asString()
        : _defaults[key];
  }
}

import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_firebase/forge_firebase.dart';

import '../domain/remote_config_repository.dart';

/// [RemoteConfigRepository] on Firebase Remote Config.
class FirebaseRemoteConfigRepository implements RemoteConfigRepository {
  /// [defaults] are bools, numbers and strings, of the type each key is read
  /// as.
  FirebaseRemoteConfigRepository(
    this._config, {
    required this._defaults,
    required this._fetchTimeout,
    required this._minimumFetchInterval,
  });

  final FirebaseRemoteConfig _config;
  final Map<String, Object> _defaults;
  final Duration _fetchTimeout;
  final Duration _minimumFetchInterval;

  @override
  Future<Result<void>> initialize() async {
    final ready = await guard(() async {
      await _config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: _fetchTimeout,
          minimumFetchInterval: _minimumFetchInterval,
        ),
      );
      await _config.setDefaults(_defaults);
      await _config.ensureInitialized();
    }, mapper: mapFirebaseError);
    unawaited(guard(_config.fetchAndActivate, mapper: mapFirebaseError));
    return ready;
  }

  @override
  String getString(String key) => _read(key, (value) => value.asString());

  @override
  bool getBool(String key) => _read(key, (value) => value.asBool());

  @override
  int getInt(String key) => _read(key, (value) => value.asInt());

  @override
  double getDouble(String key) => _read(key, (value) => value.asDouble());

  /// Until the SDK has the defaults, its values are static: the app's
  /// default stands in.
  T _read<T>(String key, T Function(RemoteConfigValue value) parse) {
    final value = _config.getValue(key);
    final fallback = _defaults[key];
    return value.source == ValueSource.valueStatic && fallback is T
        ? fallback
        : parse(value);
  }
}

import 'package:forge_core/forge_core.dart';

import '../domain/remote_config_repository.dart';

/// In-memory Remote Config for tests and builds without Firebase. Reads
/// [values] first, then the defaults; changes apply at once.
class FakeRemoteConfigRepository implements RemoteConfigRepository {
  FakeRemoteConfigRepository(this._defaults);

  final Map<String, Object> _defaults;

  /// What the server would send, e.g. `values['paywall_layout'] = 'b'`.
  final values = <String, Object>{};

  /// Returned by [initialize] until cleared, e.g. `NetworkFailure()`.
  Failure? failure;

  @override
  Future<Result<void>> initialize() async =>
      failure == null ? const Ok(null) : Err(failure!);

  @override
  String getString(String key) => _read(key, '');

  @override
  bool getBool(String key) => _read(key, false);

  @override
  int getInt(String key) => _read(key, 0);

  @override
  double getDouble(String key) => _read(key, 0.0);

  T _read<T>(String key, T none) => switch (values[key] ?? _defaults[key]) {
    final T value => value,
    _ => none,
  };
}

import 'package:forge_core/forge_core.dart';

import '../domain/remote_config_repository.dart';
import 'remote_values.dart';

/// In-memory Remote Config for tests and builds without Firebase. Reads
/// [values] first, then the defaults, as the Firebase repository reads
/// them. Unlike Firebase, a change to [values] applies at once.
class FakeRemoteConfigRepository implements RemoteConfigRepository {
  FakeRemoteConfigRepository(this._defaults);

  final Map<String, Object> _defaults;

  /// What the server would send, as strings like Firebase's
  /// (`values['paywall_layout'] = 'b'`) or typed like defaults.
  final values = <String, Object>{};

  /// Returned by [initialize] until cleared, e.g. `NetworkFailure()`.
  Failure? failure;

  @override
  Future<Result<void>> initialize() async =>
      failure == null ? const Ok(null) : Err(failure!);

  @override
  String getString(String key) => readString(_value(key));

  @override
  bool getBool(String key) => readBool(_value(key));

  @override
  int getInt(String key) => readInt(_value(key));

  @override
  double getDouble(String key) => readDouble(_value(key));

  Object? _value(String key) => values[key] ?? _defaults[key];
}

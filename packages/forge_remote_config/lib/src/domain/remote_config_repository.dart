import 'package:forge_core/forge_core.dart';

/// Values the app can change from the server without a release, e.g. the
/// variant of an A/B test. Keys and defaults come from the app.
///
/// Reads never fail and never wait: they return the last activated value,
/// or the app's default until one is activated (or when the server has
/// none). A key the app gave no default reads as `''`, `false` or `0`.
abstract interface class RemoteConfigRepository {
  /// Makes the last activated values readable, then fetches and activates
  /// the server's values in the background, without waiting for the
  /// network. Call once, at startup. A failed fetch only keeps the current
  /// values.
  Future<Result<void>> initialize();

  String getString(String key);

  bool getBool(String key);

  int getInt(String key);

  double getDouble(String key);
}

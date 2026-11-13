import 'package:forge_core/forge_core.dart';

/// Values the app can change from the server without a release, e.g. the
/// variant of an A/B test. Keys and defaults come from the app.
///
/// One session sees one set of values: what an earlier launch fetched, or
/// the app's defaults for keys the server has not sent. Values fetched in
/// this session apply from the next launch. Reads never fail and never
/// wait; a number default serves both [getInt] (when integral) and
/// [getDouble]; a key without a value or default reads as `''`, `false` or
/// `0`.
abstract interface class RemoteConfigRepository {
  /// Activates the values an earlier launch fetched, then fetches the
  /// server's values for the next launch in the background. Call once, at
  /// startup, before the first read. A failed fetch keeps the current
  /// values and never reaches the app.
  Future<Result<void>> initialize();

  String getString(String key);

  bool getBool(String key);

  int getInt(String key);

  double getDouble(String key);
}

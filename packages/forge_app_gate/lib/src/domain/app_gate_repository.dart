import 'package:forge_core/forge_core.dart';

import 'app_gate_status.dart';
import 'version.dart';

abstract interface class AppGateRepository {
  /// The version of the running install.
  Future<Result<Version>> installedVersion();

  /// The rules as last fetched, or the defaults; never waits.
  AppGateRules rules();

  /// Fetches the rules now. A failure keeps the last ones.
  Future<Result<void>> refresh();

  /// The recommended version whose offer the user dismissed, if any.
  Future<Result<Version?>> loadDismissed();

  Future<Result<void>> saveDismissed(Version version);

  /// Opens this app's page in the platform's store.
  Future<Result<void>> openStore();
}

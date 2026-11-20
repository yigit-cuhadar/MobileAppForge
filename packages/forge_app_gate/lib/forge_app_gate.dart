/// Keeps an install from being used when the server says so: a minimum
/// version (an update page in place of the app), a recommended version (an
/// offer over it, until dismissed for that version) and a maintenance
/// switch (a page with Retry), all from Remote Config.
///
/// Register `AppGateModule` after the `RemoteConfigModule`, whose defaults
/// include [AppGateModule.remoteConfigDefaults]; once the Remote Config is
/// initialized, await `sl<AppGateCubit>().start()` before `runApp`. Put
/// [AppGate] in `MaterialApp.builder` with the cubit provided above it.
/// The rules are checked from what the last launch fetched, so offline the
/// app opens as before, then fetched again at start, on every resume and
/// on Retry. A rule that is not a version asks nothing.
library;

export 'src/app_gate_module.dart';
export 'src/data/remote_app_gate_repository.dart' show AppGateKeys;
export 'src/domain/app_gate_repository.dart';
export 'src/domain/app_gate_status.dart';
export 'src/domain/app_gate_usecases.dart';
export 'src/domain/version.dart';
export 'src/presentation/app_gate.dart';
export 'src/presentation/app_gate_cubit.dart';
export 'src/presentation/app_gate_pages.dart';
export 'src/presentation/app_gate_strings.dart';

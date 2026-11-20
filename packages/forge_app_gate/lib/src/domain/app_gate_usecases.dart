import 'package:forge_core/forge_core.dart';

import 'app_gate_repository.dart';
import 'app_gate_status.dart';
import 'version.dart';

/// The status from the current rules. Nothing that fails here closes the
/// app: an unknown installed version or dismissal reads as none.
class CheckAppGate {
  const CheckAppGate(this._repository);
  final AppGateRepository _repository;

  Future<AppGateStatus> call() async {
    final installed = await _repository.installedVersion();
    final dismissed = await _repository.loadDismissed();
    return _repository.rules().statusFor(
      installed.valueOrNull,
      dismissed: dismissed.valueOrNull,
    );
  }
}

class RefreshAppGate implements UseCase<void, NoParams> {
  const RefreshAppGate(this._repository);
  final AppGateRepository _repository;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repository.refresh();
}

class DismissUpdate implements UseCase<void, Version> {
  const DismissUpdate(this._repository);
  final AppGateRepository _repository;

  @override
  Future<Result<void>> call(Version params) =>
      _repository.saveDismissed(params);
}

class OpenStore implements UseCase<void, NoParams> {
  const OpenStore(this._repository);
  final AppGateRepository _repository;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repository.openStore();
}

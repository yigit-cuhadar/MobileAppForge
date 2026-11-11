import 'package:forge_core/forge_core.dart';

import 'purchases_models.dart';
import 'purchases_repository.dart';

class ConfigurePurchases implements UseCase<void, NoParams> {
  const ConfigurePurchases(this._repository);
  final PurchasesRepository _repository;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repository.configure();
}

class IdentifyPurchaser implements UseCase<Entitlement, String> {
  const IdentifyPurchaser(this._repository);
  final PurchasesRepository _repository;

  @override
  Future<Result<Entitlement>> call(String params) =>
      _repository.identify(params);
}

class ResetPurchaser implements UseCase<Entitlement, NoParams> {
  const ResetPurchaser(this._repository);
  final PurchasesRepository _repository;

  @override
  Future<Result<Entitlement>> call([NoParams params = const NoParams()]) =>
      _repository.reset();
}

class RefreshEntitlement implements UseCase<Entitlement, NoParams> {
  const RefreshEntitlement(this._repository);
  final PurchasesRepository _repository;

  @override
  Future<Result<Entitlement>> call([NoParams params = const NoParams()]) =>
      _repository.refresh();
}

class WatchEntitlement {
  const WatchEntitlement(this._repository);
  final PurchasesRepository _repository;

  Stream<Entitlement> call() => _repository.watchEntitlement();
}

class GetOffering implements UseCase<Offering, NoParams> {
  const GetOffering(this._repository);
  final PurchasesRepository _repository;

  @override
  Future<Result<Offering>> call([NoParams params = const NoParams()]) =>
      _repository.offering();
}

class PurchasePlan implements UseCase<Entitlement, Plan> {
  const PurchasePlan(this._repository);
  final PurchasesRepository _repository;

  @override
  Future<Result<Entitlement>> call(Plan params) => _repository.purchase(params);
}

class RestorePurchases implements UseCase<Entitlement, NoParams> {
  const RestorePurchases(this._repository);
  final PurchasesRepository _repository;

  @override
  Future<Result<Entitlement>> call([NoParams params = const NoParams()]) =>
      _repository.restore();
}

class GetManagementUrl implements UseCase<Uri, NoParams> {
  const GetManagementUrl(this._repository);
  final PurchasesRepository _repository;

  @override
  Future<Result<Uri>> call([NoParams params = const NoParams()]) =>
      _repository.managementUrl();
}

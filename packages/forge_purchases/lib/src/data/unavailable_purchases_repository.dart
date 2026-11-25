import 'package:forge_core/forge_core.dart';

import '../domain/purchases_models.dart';
import '../domain/purchases_repository.dart';

/// No store: nobody is entitled and every store call fails with
/// [PurchaseFailureReason.storeUnavailable].
class UnavailablePurchasesRepository implements PurchasesRepository {
  const UnavailablePurchasesRepository();

  static const _unavailable = Err<Never>(
    PurchaseFailure(
      PurchaseFailureReason.storeUnavailable,
      'No purchases backend is configured',
    ),
  );

  @override
  Future<Result<void>> configure() async => const Ok(null);

  @override
  Future<Result<Entitlement>> identify(String userId) async =>
      const Ok(Entitlement.none());

  @override
  Future<Result<Entitlement>> reset() async => const Ok(Entitlement.none());

  /// The entitlement never changes, so nothing is emitted.
  @override
  Stream<Entitlement> watchEntitlement() => const Stream.empty();

  @override
  Future<Result<Entitlement>> refresh() async => const Ok(Entitlement.none());

  @override
  Future<Result<Offering>> offering() async => _unavailable;

  @override
  Future<Result<bool>> recordAdAttribution({required bool lookUp}) async =>
      const Ok(false);

  @override
  Future<Result<Entitlement>> purchase(Plan plan) async => _unavailable;

  @override
  Future<Result<Entitlement>> restore() async => _unavailable;

  @override
  Future<Result<Uri>> managementUrl() async => _unavailable;

  @override
  Future<Result<bool>> presentCustomerCenter() async => _unavailable;
}

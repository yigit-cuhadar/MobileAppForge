import 'package:forge_core/forge_core.dart';

import 'purchases_models.dart';

/// Purchases for one entitlement. Failures are [PurchaseFailure],
/// [NetworkFailure] or [UnknownFailure].
abstract interface class PurchasesRepository {
  /// Must complete before any other call. Starts with an anonymous user.
  /// Fails when the entitlement could not be loaded; updates still arrive
  /// through [watchEntitlement] later.
  Future<Result<void>> configure();

  /// Switches to the app's [userId] so purchases follow the account.
  Future<Result<void>> identify(String userId);

  /// Back to a fresh anonymous user, e.g. on sign-out.
  Future<Result<void>> reset();

  /// Emits the entitlement after [configure] and on every change; a late
  /// listener gets the latest value first. Never errors.
  Stream<Entitlement> watchEntitlement();

  /// Never empty: no plans is a [PurchaseFailureReason.productNotAvailable].
  Future<Result<Offering>> offering();

  /// Resolves to the entitlement after the purchase.
  Future<Result<Entitlement>> purchase(Plan plan);

  /// Moves the store account's purchases to the current user.
  Future<Result<Entitlement>> restore();

  /// The platform's manage-subscription page, for the app to open.
  Future<Result<Uri>> managementUrl();
}

import 'package:forge_core/forge_core.dart';

import 'purchases_models.dart';

/// Purchases for one entitlement. Failures are [PurchaseFailure],
/// [NetworkFailure] or [UnknownFailure].
abstract interface class PurchasesRepository {
  /// Must complete before any other call. The store resumes its cached user:
  /// the last identified one, or an anonymous one. Call [identify] or [reset]
  /// next; nothing is emitted before one of them succeeds.
  Future<Result<void>> configure();

  /// Switches to the app's [userId] so purchases follow the account.
  Future<Result<Entitlement>> identify(String userId);

  /// Switches to an anonymous user, e.g. on sign-out or when the app starts
  /// signed out.
  Future<Result<Entitlement>> reset();

  /// Emits the current user's entitlement on every change; a late listener
  /// gets the latest value first. A user switch clears that value until it
  /// succeeds. Never errors.
  Stream<Entitlement> watchEntitlement();

  /// Fetches the entitlement again, e.g. when it should have expired.
  Future<Result<Entitlement>> refresh();

  /// Never empty: no plans is a [PurchaseFailureReason.productNotAvailable].
  /// Trials and intro offers appear only when the user is eligible.
  Future<Result<Offering>> offering();

  /// Resolves to the entitlement after the purchase.
  Future<Result<Entitlement>> purchase(Plan plan);

  /// Moves the store account's purchases to the current user.
  Future<Result<Entitlement>> restore();

  /// The platform's manage-subscription page, for the app to open.
  Future<Result<Uri>> managementUrl();
}

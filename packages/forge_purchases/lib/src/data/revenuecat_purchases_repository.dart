import 'package:forge_core/forge_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../domain/purchases_models.dart';
import '../domain/purchases_repository.dart';
import 'entitlement_channel.dart';
import 'revenuecat_mappers.dart';

class RevenueCatPurchasesRepository implements PurchasesRepository {
  RevenueCatPurchasesRepository({
    required this._apiKey,
    required this._entitlementId,
  });

  final String _apiKey;
  final String _entitlementId;
  final _channel = EntitlementChannel();

  /// Packages of the last loaded offering by product id; purchases need them.
  final _packages = <String, rc.Package>{};

  @override
  Future<Result<void>> configure() => _guard(() async {
    await rc.Purchases.configure(rc.PurchasesConfiguration(_apiKey));
    rc.Purchases.addCustomerInfoUpdateListener(_publish);
    _publish(await rc.Purchases.getCustomerInfo());
  });

  @override
  Future<Result<void>> identify(String userId) => _guard(
    () async => _publish((await rc.Purchases.logIn(userId)).customerInfo),
  );

  @override
  Future<Result<void>> reset() => _guard(() async {
    // logOut throws for a user who is already anonymous.
    if (await rc.Purchases.isAnonymous) return;
    _publish(await rc.Purchases.logOut());
  });

  @override
  Stream<Entitlement> watchEntitlement() => _channel.stream;

  @override
  Future<Result<Offering>> offering() => _guard(_loadOffering);

  @override
  Future<Result<Entitlement>> purchase(Plan plan) => _guard(() async {
    if (!_packages.containsKey(plan.id)) await _loadOffering();
    final package = _packages[plan.id];
    if (package == null) {
      throw const PurchaseFailure(PurchaseFailureReason.productNotAvailable);
    }
    final current = _channel.latest;
    // Google Play keeps both subscriptions unless told it is a plan change.
    final changeFrom =
        current != null &&
            current.isActive &&
            current.store == PurchaseStore.playStore &&
            current.productId != plan.id
        ? rc.StoreProductChangeInfo(current.productId!)
        : null;
    final result = await rc.Purchases.purchase(
      rc.PurchaseParams.package(package, productChangeInfo: changeFrom),
    );
    return _publish(result.customerInfo);
  });

  @override
  Future<Result<Entitlement>> restore() =>
      _guard(() async => _publish(await rc.Purchases.restorePurchases()));

  @override
  Future<Result<Uri>> managementUrl() => _guard(() async {
    final url = (await rc.Purchases.getCustomerInfo()).managementURL;
    return url == null ? storeSubscriptionsUrl() : Uri.parse(url);
  });

  Future<Offering> _loadOffering() async {
    final current = (await rc.Purchases.getOfferings()).current;
    final plans = <Plan>[];
    _packages.clear();
    for (final package in current?.availablePackages ?? <rc.Package>[]) {
      final plan = planFrom(package);
      if (plan == null) continue;
      plans.add(plan);
      _packages[plan.id] = package;
    }
    if (plans.isEmpty) {
      throw const PurchaseFailure(
        PurchaseFailureReason.productNotAvailable,
        'No current offering with monthly, yearly or lifetime packages',
      );
    }
    return Offering(plans);
  }

  Entitlement _publish(rc.CustomerInfo info) =>
      _channel.add(entitlementFrom(info, _entitlementId));

  Future<Result<T>> _guard<T>(Future<T> Function() body) =>
      guard(body, mapper: mapPurchasesError);
}

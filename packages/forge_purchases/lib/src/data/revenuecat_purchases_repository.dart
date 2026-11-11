import 'package:flutter/foundation.dart';
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
  });

  @override
  Future<Result<Entitlement>> identify(String userId) =>
      _switchUser(() async => (await rc.Purchases.logIn(userId)).customerInfo);

  @override
  Future<Result<Entitlement>> reset() => _switchUser(
    // A cold start resumes the cached signed-in user, which must be logged
    // out; logOut throws for a user who is already anonymous.
    () async => await rc.Purchases.isAnonymous
        ? rc.Purchases.getCustomerInfo()
        : rc.Purchases.logOut(),
  );

  @override
  Stream<Entitlement> watchEntitlement() => _channel.stream;

  @override
  Future<Result<Entitlement>> refresh() => _guard(() async {
    await rc.Purchases.invalidateCustomerInfoCache();
    return _publish(await rc.Purchases.getCustomerInfo());
  });

  @override
  Future<Result<Offering>> offering() => _guard(_loadOffering);

  @override
  Future<Result<Entitlement>> purchase(Plan plan) => _guard(() async {
    if (!_packages.containsKey(plan.id)) await _loadOffering();
    final package = _packages[plan.id];
    if (package == null) {
      throw const PurchaseFailure(PurchaseFailureReason.productNotAvailable);
    }
    final result = await rc.Purchases.purchase(
      rc.PurchaseParams.package(
        package,
        productChangeInfo: productChangeFor(_channel.latest, plan),
      ),
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

  Future<Result<Entitlement>> _switchUser(
    Future<rc.CustomerInfo> Function() body,
  ) {
    _channel.close();
    return _guard(
      () async => _channel.open(entitlementFrom(await body(), _entitlementId)),
    );
  }

  Future<Offering> _loadOffering() async {
    final packages =
        (await rc.Purchases.getOfferings()).current?.availablePackages ??
        const <rc.Package>[];
    final eligible = await _introEligibleProducts(packages);
    final plans = <Plan>[];
    _packages.clear();
    for (final package in packages) {
      final id = package.storeProduct.identifier;
      final plan = planFrom(package, introEligible: eligible(id));
      if (plan == null) continue;
      plans.add(plan);
      _packages[id] = package;
    }
    if (plans.isEmpty) {
      throw const PurchaseFailure(
        PurchaseFailureReason.productNotAvailable,
        'No current offering with monthly, yearly or lifetime packages',
      );
    }
    return Offering(plans);
  }

  /// Google Play lists only offers the user is eligible for; the App Store
  /// lists them for everyone, so they are kept only when confirmed eligible.
  Future<bool Function(String productId)> _introEligibleProducts(
    List<rc.Package> packages,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.macOS) {
      return (_) => true;
    }
    final ids = [
      for (final package in packages)
        if (package.storeProduct.introductoryPrice != null)
          package.storeProduct.identifier,
    ];
    if (ids.isEmpty) return (_) => false;
    final eligibility =
        await rc.Purchases.checkTrialOrIntroductoryPriceEligibility(ids);
    return (id) =>
        eligibility[id]?.status ==
        rc.IntroEligibilityStatus.introEligibilityStatusEligible;
  }

  Entitlement _publish(rc.CustomerInfo info) =>
      _channel.add(entitlementFrom(info, _entitlementId));

  /// Expected outcomes are thrown as failures, which `guard` returns without
  /// error-logging; everything else goes through its logging mapper.
  Future<Result<T>> _guard<T>(Future<T> Function() body) => guard(() async {
    try {
      return await body();
    } catch (error) {
      final failure = mapPurchasesError(error);
      if (failure != null && isExpectedFailure(failure)) throw failure;
      rethrow;
    }
  }, mapper: mapPurchasesError);
}

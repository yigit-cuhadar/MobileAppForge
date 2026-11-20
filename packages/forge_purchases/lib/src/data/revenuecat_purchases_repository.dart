import 'package:flutter/foundation.dart';
import 'package:forge_core/forge_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/purchases_models.dart';
import '../domain/purchases_repository.dart';
import 'ad_services_attribution.dart';
import 'entitlement_channel.dart';
import 'revenuecat_mappers.dart';

/// The custom attributes [RevenueCatPurchasesRepository.recordAdAttribution]
/// sets for targeting: the ad network and its campaign id.
const adNetworkAttribute = 'ad_network';
const adCampaignAttribute = 'ad_campaign_id';
const appleSearchAds = 'apple_search_ads';

class RevenueCatPurchasesRepository implements PurchasesRepository {
  RevenueCatPurchasesRepository({
    required this._apiKey,
    required this._entitlementId,
    required this._adServices,
    required this._preferences,
    this.attributionWait = const Duration(seconds: 5),
  });

  final String _apiKey;
  final String _entitlementId;
  final AdServicesAttribution _adServices;
  final SharedPreferencesAsync _preferences;

  /// Apple's final answer for this install: the campaign id, or
  /// [_notAttributed].
  static const _adAttributionKey = 'forge_purchases.adAttribution';
  static const _notAttributed = 'none';

  /// How long [offering] waits for a [recordAdAttribution] in progress.
  final Duration attributionWait;
  final _channel = EntitlementChannel();
  Future<void>? _attribution;

  /// Packages of the last loaded offering by product id; purchases need them.
  final _packages = <String, rc.Package>{};

  /// The win-back offers of those packages the user is eligible for.
  final _winBacks = <String, rc.WinBackOffer>{};

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
  Future<Result<bool>> recordAdAttribution({required bool lookUp}) {
    final result = _guard(() => _recordAdAttribution(lookUp: lookUp));
    _attribution = result.then((_) {});
    return result;
  }

  Future<bool> _recordAdAttribution({required bool lookUp}) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    // RevenueCat's own Apple Search Ads collection, for its charts. It asks
    // Apple within 24 hours, too late for a first paywall, hence the
    // attributes below.
    await rc.Purchases.enableAdServicesAttributionTokenCollection();
    var answer = await _preferences.getString(_adAttributionKey);
    if (answer == null) {
      if (!lookUp) return false;
      final campaign = await _adServices.campaignId();
      answer = campaign == null ? _notAttributed : '$campaign';
      await _preferences.setString(_adAttributionKey, answer);
    }
    if (answer == _notAttributed) return false;
    await rc.Purchases.setAttributes({
      adNetworkAttribute: appleSearchAds,
      adCampaignAttribute: answer,
    });
    await rc.Purchases.syncAttributesAndOfferingsIfNeeded();
    return true;
  }

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
        winBackOffer: plan.winBack == null ? null : _winBacks[plan.id],
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

  @override
  Future<Result<bool>> presentCustomerCenter() => _guard(() async {
    await RevenueCatUI.presentCustomerCenter();
    return true;
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
    await _attribution?.timeout(attributionWait, onTimeout: () {});
    final current = (await rc.Purchases.getOfferings()).current;
    final packages = current?.availablePackages ?? const <rc.Package>[];
    final eligible = await _introEligibleProducts(packages);
    final winBacks = await _eligibleWinBacks(packages);
    final plans = <Plan>[];
    _packages.clear();
    _winBacks.clear();
    for (final package in packages) {
      final id = package.storeProduct.identifier;
      final winBack = winBacks[id];
      final plan = planFrom(
        package,
        introEligible: eligible(id),
        winBack: winBack,
      );
      if (plan == null) continue;
      plans.add(plan);
      _packages[id] = package;
      if (plan.winBack != null) _winBacks[id] = winBack!;
    }
    if (plans.isEmpty) {
      throw const PurchaseFailure(
        PurchaseFailureReason.productNotAvailable,
        'No current offering with monthly, yearly or lifetime packages',
      );
    }
    return Offering(plans, metadata: current?.metadata ?? const {});
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

  /// The first win-back offer of each subscription the user is eligible
  /// for. Apple's only, from iOS 18; elsewhere, or when the store cannot
  /// tell, there are none.
  Future<Map<String, rc.WinBackOffer>> _eligibleWinBacks(
    List<rc.Package> packages,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return const {};
    final offers = <String, rc.WinBackOffer>{};
    await Future.wait([
      for (final package in packages)
        if (package.storeProduct.subscriptionPeriod != null)
          rc.Purchases.getEligibleWinBackOffersForPackage(package).then(
            (eligible) {
              if (eligible.isNotEmpty) {
                offers[package.storeProduct.identifier] = eligible.first;
              }
            },
            // Before iOS 18 the SDK refuses; the paywall goes on without.
            onError: (_) {},
          ),
    ]);
    return offers;
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

import 'package:flutter/services.dart';
import 'package:forge_core/forge_core.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../domain/purchases_models.dart';

Entitlement entitlementFrom(rc.CustomerInfo info, String entitlementId) {
  final entitlement = info.entitlements.all[entitlementId];
  if (entitlement == null) return const Entitlement.none();
  final expiration = entitlement.expirationDate;
  return Entitlement(
    isActive: entitlement.isActive,
    productId: entitlement.productIdentifier,
    expiresAt: expiration == null ? null : DateTime.parse(expiration),
    willRenew: entitlement.willRenew,
    isInTrial: entitlement.periodType == rc.PeriodType.trial,
    hasBillingIssue: entitlement.billingIssueDetectedAt != null,
    store: switch (entitlement.store) {
      rc.Store.appStore || rc.Store.macAppStore => PurchaseStore.appStore,
      rc.Store.playStore => PurchaseStore.playStore,
      rc.Store.promotional => PurchaseStore.promotional,
      rc.Store.testStore => PurchaseStore.test,
      _ => PurchaseStore.other,
    },
  );
}

/// Null for packages that are not monthly, yearly or lifetime.
Plan? planFrom(rc.Package package) {
  final product = package.storeProduct;
  final period = switch (package.packageType) {
    rc.PackageType.monthly => PlanPeriod.monthly,
    rc.PackageType.annual => PlanPeriod.yearly,
    rc.PackageType.lifetime => PlanPeriod.lifetime,
    _ => switch (product.subscriptionPeriod) {
      'P1M' => PlanPeriod.monthly,
      'P1Y' => PlanPeriod.yearly,
      _ => null,
    },
  };
  if (period == null) return null;
  final intro = product.introductoryPrice;
  final unit = intro == null ? null : _unitFrom(intro.periodUnit);
  final isFree = intro != null && intro.price == 0;
  return Plan(
    id: product.identifier,
    period: period,
    price: product.priceString,
    priceAmount: product.price,
    currencyCode: product.currencyCode,
    trial: isFree && unit != null
        ? OfferPeriod(intro.periodNumberOfUnits * intro.cycles, unit)
        : null,
    intro: !isFree && intro != null && unit != null
        ? IntroOffer(
            price: intro.priceString,
            period: OfferPeriod(intro.periodNumberOfUnits, unit),
            cycles: intro.cycles,
          )
        : null,
  );
}

PeriodUnit? _unitFrom(rc.PeriodUnit unit) => switch (unit) {
  rc.PeriodUnit.day => PeriodUnit.day,
  rc.PeriodUnit.week => PeriodUnit.week,
  rc.PeriodUnit.month => PeriodUnit.month,
  rc.PeriodUnit.year => PeriodUnit.year,
  rc.PeriodUnit.unknown => null,
};

/// [FailureMapper] for RevenueCat SDK errors. Pass to `guard(mapper:)`.
Failure? mapPurchasesError(Object error) {
  // The SDK reports its error code as the numeric PlatformException code.
  if (error is! PlatformException || int.tryParse(error.code) == null) {
    return null;
  }
  final code = rc.PurchasesErrorHelper.getErrorCode(error);
  final message = error.message ?? code.name;
  PurchaseFailure purchase(PurchaseFailureReason reason) =>
      PurchaseFailure(reason, message, error);
  return switch (code) {
    rc.PurchasesErrorCode.purchaseCancelledError => purchase(
      PurchaseFailureReason.cancelled,
    ),
    rc.PurchasesErrorCode.networkError ||
    rc.PurchasesErrorCode.offlineConnectionError ||
    rc.PurchasesErrorCode.productRequestTimeout ||
    rc.PurchasesErrorCode.apiEndpointBlocked => NetworkFailure(message, error),
    rc.PurchasesErrorCode.storeProblemError ||
    rc.PurchasesErrorCode.purchaseNotAllowedError ||
    rc.PurchasesErrorCode.insufficientPermissionsError => purchase(
      PurchaseFailureReason.storeUnavailable,
    ),
    rc.PurchasesErrorCode.productNotAvailableForPurchaseError ||
    rc.PurchasesErrorCode.ineligibleError => purchase(
      PurchaseFailureReason.productNotAvailable,
    ),
    rc.PurchasesErrorCode.productAlreadyPurchasedError ||
    rc.PurchasesErrorCode.receiptAlreadyInUseError ||
    rc.PurchasesErrorCode.receiptInUseByOtherSubscriberError ||
    rc.PurchasesErrorCode.purchaseBelongsToOtherUser => purchase(
      PurchaseFailureReason.alreadyOwned,
    ),
    rc.PurchasesErrorCode.paymentPendingError => purchase(
      PurchaseFailureReason.pending,
    ),
    _ => UnknownFailure(message, error),
  };
}

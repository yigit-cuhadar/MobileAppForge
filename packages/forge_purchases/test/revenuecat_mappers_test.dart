import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_purchases/forge_purchases.dart';
import 'package:forge_purchases/src/data/revenuecat_mappers.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

rc.CustomerInfo customerWith(
  List<rc.EntitlementInfo> entitlements,
) => rc.CustomerInfo(
  rc.EntitlementInfos(
    {for (final e in entitlements) e.identifier: e},
    {for (final e in entitlements.where((e) => e.isActive)) e.identifier: e},
  ),
  const {},
  const [],
  const [],
  const [],
  '2026-01-01T00:00:00Z',
  'user',
  const {},
  '2026-01-01T00:00:00Z',
);

rc.EntitlementInfo entitlementInfo({
  bool isActive = true,
  bool willRenew = true,
  rc.PeriodType periodType = rc.PeriodType.normal,
  rc.Store store = rc.Store.appStore,
  String? billingIssueDetectedAt,
}) => rc.EntitlementInfo(
  'premium',
  isActive,
  willRenew,
  '2026-01-01T00:00:00Z',
  '2026-01-01T00:00:00Z',
  'pro_yearly',
  false,
  store: store,
  periodType: periodType,
  expirationDate: '2027-01-01T00:00:00Z',
  billingIssueDetectedAt: billingIssueDetectedAt,
);

rc.Package package(
  rc.PackageType type, {
  String? subscriptionPeriod,
  rc.IntroductoryPrice? intro,
}) => rc.Package(
  'pkg',
  type,
  rc.StoreProduct(
    'pro',
    'Pro',
    'Pro',
    39.99,
    '€39.99',
    'EUR',
    subscriptionPeriod: subscriptionPeriod,
    introductoryPrice: intro,
  ),
  const rc.PresentedOfferingContext('default', null, null),
);

void main() {
  group('entitlementFrom', () {
    test('an unknown entitlement id is none', () {
      expect(
        entitlementFrom(customerWith([entitlementInfo()]), 'other'),
        const Entitlement.none(),
      );
    });

    test('maps an active renewing subscription', () {
      expect(
        entitlementFrom(customerWith([entitlementInfo()]), 'premium'),
        Entitlement(
          isActive: true,
          productId: 'pro_yearly',
          expiresAt: DateTime.utc(2027),
          willRenew: true,
          store: PurchaseStore.appStore,
        ),
      );
    });

    test('maps a trial', () {
      final entitlement = entitlementFrom(
        customerWith([entitlementInfo(periodType: rc.PeriodType.trial)]),
        'premium',
      );
      expect(entitlement.isInTrial, isTrue);
    });

    test('keeps the details of an expired entitlement', () {
      final entitlement = entitlementFrom(
        customerWith([
          entitlementInfo(
            isActive: false,
            willRenew: false,
            store: rc.Store.playStore,
          ),
        ]),
        'premium',
      );
      expect(entitlement.isActive, isFalse);
      expect(entitlement.productId, 'pro_yearly');
      expect(entitlement.store, PurchaseStore.playStore);
    });

    test('flags a billing issue', () {
      final entitlement = entitlementFrom(
        customerWith([
          entitlementInfo(billingIssueDetectedAt: '2026-12-31T00:00:00Z'),
        ]),
        'premium',
      );
      expect(entitlement.isActive, isTrue);
      expect(entitlement.hasBillingIssue, isTrue);
    });
  });

  group('planFrom', () {
    test('maps an annual package with a free trial', () {
      final plan = planFrom(
        package(
          rc.PackageType.annual,
          intro: const rc.IntroductoryPrice(
            0,
            '€0.00',
            'P1W',
            1,
            rc.PeriodUnit.day,
            7,
          ),
        ),
      );
      expect(
        plan,
        const Plan(
          id: 'pro',
          period: PlanPeriod.yearly,
          price: '€39.99',
          priceAmount: 39.99,
          currencyCode: 'EUR',
          trial: OfferPeriod(7, PeriodUnit.day),
        ),
      );
    });

    test('maps a paid intro offer', () {
      final plan = planFrom(
        package(
          rc.PackageType.monthly,
          intro: const rc.IntroductoryPrice(
            0.99,
            '€0.99',
            'P1M',
            3,
            rc.PeriodUnit.month,
            1,
          ),
        ),
      )!;
      expect(plan.trial, isNull);
      expect(
        plan.intro,
        const IntroOffer(
          price: '€0.99',
          period: OfferPeriod(1, PeriodUnit.month),
          cycles: 3,
        ),
      );
    });

    test('reads the period of a custom package from the product', () {
      expect(
        planFrom(package(rc.PackageType.custom, subscriptionPeriod: 'P1M'))!
            .period,
        PlanPeriod.monthly,
      );
      expect(
        planFrom(package(rc.PackageType.lifetime))!.period,
        PlanPeriod.lifetime,
      );
    });

    test('skips periods the domain does not model', () {
      expect(planFrom(package(rc.PackageType.weekly)), isNull);
    });
  });

  group('mapPurchasesError', () {
    Failure? map(rc.PurchasesErrorCode code) => mapPurchasesError(
      PlatformException(code: '${code.index}', message: 'm'),
    );

    PurchaseFailureReason? reasonOf(rc.PurchasesErrorCode code) =>
        switch (map(code)) {
          PurchaseFailure(:final reason) => reason,
          _ => null,
        };

    const reasons = {
      rc.PurchasesErrorCode.purchaseCancelledError:
          PurchaseFailureReason.cancelled,
      rc.PurchasesErrorCode.storeProblemError:
          PurchaseFailureReason.storeUnavailable,
      rc.PurchasesErrorCode.purchaseNotAllowedError:
          PurchaseFailureReason.storeUnavailable,
      rc.PurchasesErrorCode.insufficientPermissionsError:
          PurchaseFailureReason.storeUnavailable,
      rc.PurchasesErrorCode.productNotAvailableForPurchaseError:
          PurchaseFailureReason.productNotAvailable,
      rc.PurchasesErrorCode.ineligibleError:
          PurchaseFailureReason.productNotAvailable,
      rc.PurchasesErrorCode.productAlreadyPurchasedError:
          PurchaseFailureReason.alreadyOwned,
      rc.PurchasesErrorCode.receiptAlreadyInUseError:
          PurchaseFailureReason.alreadyOwned,
      rc.PurchasesErrorCode.receiptInUseByOtherSubscriberError:
          PurchaseFailureReason.alreadyOwned,
      rc.PurchasesErrorCode.purchaseBelongsToOtherUser:
          PurchaseFailureReason.alreadyOwned,
      rc.PurchasesErrorCode.paymentPendingError: PurchaseFailureReason.pending,
    };

    for (final MapEntry(key: code, value: reason) in reasons.entries) {
      test('${code.name} is ${reason.name}', () {
        expect(reasonOf(code), reason);
      });
    }

    for (final code in const [
      rc.PurchasesErrorCode.networkError,
      rc.PurchasesErrorCode.offlineConnectionError,
      rc.PurchasesErrorCode.productRequestTimeout,
      rc.PurchasesErrorCode.apiEndpointBlocked,
    ]) {
      test('${code.name} is a network failure', () {
        expect(map(code), isA<NetworkFailure>());
      });
    }

    test('every other code is unknown', () {
      final others = rc.PurchasesErrorCode.values.where(
        (code) => !reasons.containsKey(code) && map(code) is! NetworkFailure,
      );
      expect(others, isNotEmpty);
      for (final code in others) {
        expect(map(code), isA<UnknownFailure>(), reason: code.name);
      }
    });

    test('ignores errors that are not RevenueCat errors', () {
      expect(mapPurchasesError(StateError('x')), isNull);
      expect(
        mapPurchasesError(PlatformException(code: 'channel-error')),
        isNull,
      );
    });
  });
}

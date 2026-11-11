import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_purchases/forge_purchases.dart';
import 'package:forge_purchases/src/data/revenuecat_mappers.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'revenuecat_payloads.dart';

Entitlement entitlementOf(Map<String, Object?> entitlement) => entitlementFrom(
  rc.CustomerInfo.fromJson(customerInfoJson([entitlement])),
  'premium',
);

Plan? planOf(Map<String, Object?> package, {bool introEligible = true}) =>
    planFrom(rc.Package.fromJson(package), introEligible: introEligible);

void main() {
  group('entitlementFrom', () {
    test('an unknown entitlement id is none', () {
      expect(
        entitlementFrom(rc.CustomerInfo.fromJson(customerInfoJson()), 'x'),
        const Entitlement.none(),
      );
    });

    test('maps an App Store trial', () {
      expect(
        entitlementOf(
          entitlementJson(
            store: 'APP_STORE',
            productId: 'pro_yearly',
            periodType: 'TRIAL',
          ),
        ),
        Entitlement(
          isActive: true,
          productId: 'pro_yearly',
          expiresAt: DateTime.utc(2027),
          willRenew: true,
          isInTrial: true,
          store: PurchaseStore.appStore,
        ),
      );
    });

    test('joins the Play base plan so the id matches the plan', () {
      final entitlement = entitlementOf(
        entitlementJson(
          store: 'PLAY_STORE',
          productId: 'pro',
          basePlanId: 'yearly',
        ),
      );
      final plan = planOf(packageJson(productId: 'pro:yearly'))!;

      expect(entitlement.productId, plan.id);
      expect(entitlement.store, PurchaseStore.playStore);
    });

    test('keeps the details of an expired entitlement', () {
      final entitlement = entitlementOf(
        entitlementJson(
          store: 'APP_STORE',
          productId: 'pro_yearly',
          isActive: false,
          willRenew: false,
        ),
      );
      expect(entitlement.isActive, isFalse);
      expect(entitlement.productId, 'pro_yearly');
      expect(entitlement.expiresAt, DateTime.utc(2027));
    });

    test('flags a billing issue during the grace period', () {
      final entitlement = entitlementOf(
        entitlementJson(
          store: 'PLAY_STORE',
          productId: 'pro',
          basePlanId: 'monthly',
          billingIssueDetectedAt: '2026-12-31T00:00:00.000Z',
        ),
      );
      expect(entitlement.isActive, isTrue);
      expect(entitlement.hasBillingIssue, isTrue);
    });
  });

  group('planFrom', () {
    test('maps an App Store yearly plan with a one-week trial', () {
      expect(
        planOf(
          packageJson(productId: 'pro_yearly', introPrice: appStoreWeekTrial),
        ),
        const Plan(
          id: 'pro_yearly',
          period: PlanPeriod.yearly,
          price: '€39.99',
          priceAmount: 39.99,
          currencyCode: 'EUR',
          trial: OfferPeriod(1, PeriodUnit.week),
        ),
      );
    });

    test('maps a Play trial phase', () {
      expect(
        planOf(
          packageJson(productId: 'pro:yearly', introPrice: playSevenDayTrial),
        )!.trial,
        const OfferPeriod(7, PeriodUnit.day),
      );
    });

    test('drops offers the user is not eligible for', () {
      final plan = planOf(
        packageJson(productId: 'pro_yearly', introPrice: appStoreWeekTrial),
        introEligible: false,
      )!;
      expect(plan.trial, isNull);
      expect(plan.intro, isNull);
    });

    test('maps a paid intro offer', () {
      final plan = planOf(
        packageJson(
          productId: 'pro_monthly',
          packageType: 'MONTHLY',
          subscriptionPeriod: 'P1M',
          introPrice: const {
            'price': 0.99,
            'priceString': '€0.99',
            'period': 'P1M',
            'cycles': 3,
            'periodUnit': 'MONTH',
            'periodNumberOfUnits': 1,
          },
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
        planOf(
          packageJson(
            productId: 'pro_monthly',
            packageType: 'CUSTOM',
            subscriptionPeriod: 'P1M',
          ),
        )!.period,
        PlanPeriod.monthly,
      );
    });

    test('skips periods the domain does not model', () {
      expect(
        planOf(
          packageJson(
            productId: 'pro_weekly',
            packageType: 'WEEKLY',
            subscriptionPeriod: 'P1W',
          ),
        ),
        isNull,
      );
    });
  });

  group('productChangeFor', () {
    const yearly = Plan(
      id: 'pro:yearly',
      period: PlanPeriod.yearly,
      price: '',
      priceAmount: 0,
      currencyCode: 'EUR',
    );
    Entitlement activeOn(PurchaseStore store, String productId) =>
        Entitlement(isActive: true, productId: productId, store: store);

    test('switching Play plans changes from the subscription id', () {
      expect(
        productChangeFor(
          activeOn(PurchaseStore.playStore, 'pro:monthly'),
          yearly,
        )?.oldProductIdentifier,
        'pro',
      );
    });

    test('re-buying the current plan is not a change', () {
      expect(
        productChangeFor(activeOn(PurchaseStore.playStore, yearly.id), yearly),
        isNull,
      );
    });

    test('only an active Play subscription is changed from', () {
      expect(
        productChangeFor(
          activeOn(PurchaseStore.appStore, 'pro_monthly'),
          yearly,
        ),
        isNull,
      );
      expect(
        productChangeFor(
          const Entitlement(
            isActive: false,
            productId: 'pro:monthly',
            store: PurchaseStore.playStore,
          ),
          yearly,
        ),
        isNull,
      );
      expect(productChangeFor(null, yearly), isNull);
    });
  });

  group('mapPurchasesError', () {
    Failure? map(rc.PurchasesErrorCode code) => mapPurchasesError(
      PlatformException(code: '${code.index}', message: 'm'),
    );

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
        expect(
          map(code),
          isA<PurchaseFailure>().having((f) => f.reason, 'reason', reason),
        );
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

    test('ignores errors that are not RevenueCat errors', () {
      expect(mapPurchasesError(StateError('x')), isNull);
      expect(
        mapPurchasesError(PlatformException(code: 'channel-error')),
        isNull,
      );
    });
  });
}

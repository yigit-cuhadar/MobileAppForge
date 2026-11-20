import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_purchases/forge_purchases.dart';
import 'package:forge_purchases/src/data/revenuecat_purchases_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import 'revenuecat_payloads.dart';

/// Drives the real plugin code through its method channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('purchases_flutter');

  final playMonthly = entitlementJson(
    store: 'PLAY_STORE',
    productId: 'pro',
    basePlanId: 'monthly',
  );
  late List<MethodCall> calls;
  late Map<String, Object? Function(MethodCall call)> answers;
  late List<Object> logged;
  late RevenueCatPurchasesRepository repository;

  PlatformException rcError(rc.PurchasesErrorCode code) =>
      PlatformException(code: '${code.index}', message: code.name);

  setUp(() async {
    calls = [];
    logged = [];
    Log.onError = (error, _, _) => logged.add(error);
    answers = {
      'setupPurchases': (_) => null,
      'isAnonymous': (_) => false,
      'logIn': (_) => {
        'customerInfo': customerInfoJson([playMonthly]),
        'created': false,
      },
      'logOut': (_) => customerInfoJson(),
      'getCustomerInfo': (_) => customerInfoJson(),
      'getOfferings': (_) => offeringsJson([
        packageJson(productId: 'pro:yearly', introPrice: playSevenDayTrial),
      ]),
      'purchasePackage': (_) => {
        'customerInfo': customerInfoJson(),
        'transaction': {
          'transactionIdentifier': 't',
          'productIdentifier': 'pro:yearly',
          'purchaseDate': '2026-01-01T00:00:00.000Z',
        },
      },
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return answers[call.method]!(call);
        });
    repository = RevenueCatPurchasesRepository(
      apiKey: 'goog_test',
      entitlementId: 'premium',
    );
    await repository.configure();
  });

  tearDown(() {
    Log.onError = null;
    debugDefaultTargetPlatformOverride = null;
  });

  Future<Plan> yearlyPlan() async =>
      (await repository.offering()).valueOrNull!.plans.single;

  List<MethodCall> callsTo(String method) =>
      calls.where((c) => c.method == method).toList();

  test("the offering carries the current offering's metadata", () async {
    answers['getOfferings'] = (_) => offeringsJson(
      [packageJson(productId: 'pro:yearly')],
      metadata: {'dismissible': false},
    );
    expect((await repository.offering()).valueOrNull!.metadata, {
      'dismissible': false,
    });
  });

  test('a cold start with a cached user logs out on reset', () async {
    expect((await repository.reset()).isOk, isTrue);
    expect(callsTo('logOut'), hasLength(1));

    answers['isAnonymous'] = (_) => true;
    expect((await repository.reset()).isOk, isTrue);
    expect(callsTo('logOut'), hasLength(1));
  });

  test('switching Play plans is sent as a product change', () async {
    await repository.identify('a');
    await repository.purchase(await yearlyPlan());

    final arguments = callsTo('purchasePackage').single.arguments as Map;
    expect(arguments['googleOldProductIdentifier'], 'pro');
  });

  test('after a failed switch nothing of the previous user is used', () async {
    await repository.identify('a');
    answers['logIn'] = (_) => throw rcError(rc.PurchasesErrorCode.networkError);
    expect(
      (await repository.identify('b')).failureOrNull,
      isA<NetworkFailure>(),
    );

    final replayed = <Entitlement>[];
    final subscription = repository.watchEntitlement().listen(replayed.add);
    await pumpEventQueue();
    await repository.purchase(await yearlyPlan());

    final arguments = callsTo('purchasePackage').single.arguments as Map;
    expect(arguments['googleOldProductIdentifier'], isNull);
    expect(replayed, isEmpty);
    await subscription.cancel();
  });

  test('on iOS a trial shows only when the user is eligible', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    answers['getOfferings'] = (_) => offeringsJson([
      packageJson(productId: 'pro_yearly', introPrice: appStoreWeekTrial),
    ]);
    Object? eligibility(int status) => {
      'pro_yearly': {'status': status, 'description': ''},
    };

    answers['checkTrialOrIntroductoryPriceEligibility'] = (_) => eligibility(
      rc.IntroEligibilityStatus.introEligibilityStatusEligible.index,
    );
    expect((await yearlyPlan()).trial, const OfferPeriod(1, PeriodUnit.week));

    answers['checkTrialOrIntroductoryPriceEligibility'] = (_) => eligibility(
      rc.IntroEligibilityStatus.introEligibilityStatusUnknown.index,
    );
    expect((await yearlyPlan()).trial, isNull);
  });

  group('on iOS', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      answers['getOfferings'] = (_) => offeringsJson([
        packageJson(productId: 'pro_yearly', introPrice: appStoreWeekTrial),
      ]);
      answers['checkTrialOrIntroductoryPriceEligibility'] = (_) => {
        'pro_yearly': {
          'status':
              rc.IntroEligibilityStatus.introEligibilityStatusIneligible.index,
          'description': '',
        },
      };
      answers['purchasePackageWithWinBackOffer'] = answers['purchasePackage']!;
    });

    test('an eligible win-back offer is offered and applied', () async {
      answers['eligibleWinBackOffersForProduct'] = (_) => [
        appStoreMonthFreeWinBack,
      ];
      final plan = await yearlyPlan();
      expect(
        plan.winBack,
        const WinBackOffer.free(
          'winback_1m_free',
          OfferPeriod(1, PeriodUnit.month),
        ),
      );

      await repository.purchase(plan);
      final arguments =
          callsTo('purchasePackageWithWinBackOffer').single.arguments as Map;
      expect(arguments['winBackOfferIdentifier'], 'winback_1m_free');
      expect(callsTo('purchasePackage'), isEmpty);
    });

    test('before iOS 18 the plans come without win-back offers', () async {
      answers['eligibleWinBackOffersForProduct'] = (_) =>
          throw rcError(rc.PurchasesErrorCode.unsupportedError);
      final plan = await yearlyPlan();
      expect(plan.winBack, isNull);
      expect(logged, isEmpty);

      await repository.purchase(plan);
      expect(callsTo('purchasePackage'), hasLength(1));
    });
  });

  test('Customer Center is presented through RevenueCatUI', () async {
    final presented = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('purchases_ui_flutter'), (
          call,
        ) async {
          presented.add(call.method);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('purchases_ui_flutter'),
            null,
          ),
    );

    expect((await repository.presentCustomerCenter()).valueOrNull, isTrue);
    expect(presented, contains('presentCustomerCenter'));
  });

  test('expected outcomes are returned without error logging', () async {
    final plan = await yearlyPlan();
    for (final code in const [
      rc.PurchasesErrorCode.purchaseCancelledError,
      rc.PurchasesErrorCode.paymentPendingError,
      rc.PurchasesErrorCode.productAlreadyPurchasedError,
      rc.PurchasesErrorCode.networkError,
    ]) {
      answers['purchasePackage'] = (_) => throw rcError(code);
      expect((await repository.purchase(plan)).isOk, isFalse);
    }
    expect(logged, isEmpty);

    answers['purchasePackage'] = (_) =>
        throw rcError(rc.PurchasesErrorCode.storeProblemError);
    final result = await repository.purchase(plan);
    expect(
      (result.failureOrNull! as PurchaseFailure).reason,
      PurchaseFailureReason.storeUnavailable,
    );
    expect(logged, hasLength(1));
  });
}

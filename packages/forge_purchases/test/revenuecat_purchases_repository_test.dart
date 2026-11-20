import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_purchases/forge_purchases.dart';
import 'package:forge_purchases/src/data/ad_services_attribution.dart';
import 'package:forge_purchases/src/data/revenuecat_purchases_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'revenuecat_payloads.dart';

/// Drives the real plugin code through its method channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('purchases_flutter');
  const adServicesChannel = MethodChannel('forge_purchases/ad_services');

  final playMonthly = entitlementJson(
    store: 'PLAY_STORE',
    productId: 'pro',
    basePlanId: 'monthly',
  );
  late List<MethodCall> calls;
  late Map<String, Object? Function(MethodCall call)> answers;
  late List<Object> logged;
  late RevenueCatPurchasesRepository repository;

  /// Apple's attribution API; attributed to campaign 542370539 by default.
  late Future<http.Response> Function() adServices;
  late int appleAsked;

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
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    appleAsked = 0;
    adServices = () async => http.Response(
      jsonEncode({'attribution': true, 'campaignId': 542370539}),
      200,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(adServicesChannel, (call) async => 'token');
    repository = RevenueCatPurchasesRepository(
      apiKey: 'goog_test',
      entitlementId: 'premium',
      adServices: AdServicesAttribution(
        client: MockClient((_) {
          appleAsked++;
          return adServices();
        }),
        retryDelay: Duration.zero,
      ),
      preferences: SharedPreferencesAsync(),
      attributionWait: const Duration(milliseconds: 100),
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

  group('ad attribution on iOS', () {
    final soft = offeringsJson(
      [packageJson(productId: 'pro_yearly')],
      metadata: {'dismissible': true},
    );
    final hard = offeringsJson(
      [packageJson(productId: 'pro_yearly')],
      metadata: {'dismissible': false},
    );

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      answers['getOfferings'] = (_) => soft;
      answers['enableAdServicesAttributionTokenCollection'] = (_) => null;
      answers['setAttributes'] = (_) => null;
      // Targeting sees the attributes once synced.
      answers['syncAttributesAndOfferingsIfNeeded'] = (_) {
        answers['getOfferings'] = (_) => hard;
        return hard;
      };
    });

    Future<Object?> dismissible() async =>
        (await repository.offering()).valueOrNull!.metadata['dismissible'];

    test('an attributed install is marked and its offering reloaded', () async {
      expect(
        (await repository.recordAdAttribution(lookUp: true)).valueOrNull,
        isTrue,
      );

      expect(
        callsTo('enableAdServicesAttributionTokenCollection'),
        hasLength(1),
      );
      expect(callsTo('setAttributes').single.arguments, {
        'attributes': {
          'ad_network': 'apple_search_ads',
          'ad_campaign_id': '542370539',
        },
      });
      expect(callsTo('syncAttributesAndOfferingsIfNeeded'), hasLength(1));
      expect(await dismissible(), isFalse);
    });

    test('an install Apple does not attribute is left as it is', () async {
      adServices = () async =>
          http.Response(jsonEncode({'attribution': false}), 200);

      expect(
        (await repository.recordAdAttribution(lookUp: true)).valueOrNull,
        isFalse,
      );
      expect(callsTo('setAttributes'), isEmpty);
      expect(await dismissible(), isTrue);
    });

    test('a record not ready yet is asked for again', () async {
      final responses = [
        http.Response('', 404),
        http.Response('', 404),
        http.Response(jsonEncode({'attribution': true, 'campaignId': 7}), 200),
      ];
      adServices = () async => responses.removeAt(0);

      expect(
        (await repository.recordAdAttribution(lookUp: true)).valueOrNull,
        isTrue,
      );
      expect(
        (callsTo('setAttributes').single.arguments as Map)['attributes'],
        containsPair('ad_campaign_id', '7'),
      );
    });

    test('Apple failing leaves the offering as it was, unlogged', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      appleAsked = 0;
      adServices = () async => http.Response('', 404);

      final result = await repository.recordAdAttribution(lookUp: true);
      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(callsTo('setAttributes'), isEmpty);
      expect(await dismissible(), isTrue);

      adServices = () => throw http.ClientException('offline');
      expect(
        (await repository.recordAdAttribution(lookUp: true)).failureOrNull,
        isA<NetworkFailure>(),
      );
      expect(logged, isEmpty);
    });

    test('a device without a token is not attributed', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(adServicesChannel, (call) async => null);

      expect(
        (await repository.recordAdAttribution(lookUp: true)).valueOrNull,
        isFalse,
      );
      expect(callsTo('setAttributes'), isEmpty);
    });

    test('Apple is asked once per install; its answer is applied to every '
        'user', () async {
      await repository.recordAdAttribution(lookUp: true);
      await repository.identify('other');
      expect(
        (await repository.recordAdAttribution(lookUp: false)).valueOrNull,
        isTrue,
      );

      expect(appleAsked, 1);
      expect(callsTo('setAttributes'), hasLength(2));
      expect(callsTo('syncAttributesAndOfferingsIfNeeded'), hasLength(2));
    });

    test('a final "not attributed" is kept too', () async {
      adServices = () async =>
          http.Response(jsonEncode({'attribution': false}), 200);
      await repository.recordAdAttribution(lookUp: true);
      await repository.recordAdAttribution(lookUp: true);

      expect(appleAsked, 1);
      expect(callsTo('setAttributes'), isEmpty);
    });

    test('without an answer yet, Apple is asked only with lookUp', () async {
      expect(
        (await repository.recordAdAttribution(lookUp: false)).valueOrNull,
        isFalse,
      );
      expect(appleAsked, 0);
    });

    test('no answer is asked for again, a missing token is not', () async {
      adServices = () async => http.Response('', 503);
      await repository.recordAdAttribution(lookUp: true);
      adServices = () async => http.Response(
        jsonEncode({'attribution': true, 'campaignId': 3}),
        200,
      );
      expect(
        (await repository.recordAdAttribution(lookUp: true)).valueOrNull,
        isTrue,
      );
      expect(appleAsked, 2);

      // Another install, on a device without a token.
      await SharedPreferencesAsync().clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(adServicesChannel, (call) async => null);
      await repository.recordAdAttribution(lookUp: true);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(adServicesChannel, (call) async => 'token');
      expect(
        (await repository.recordAdAttribution(lookUp: true)).valueOrNull,
        isFalse,
      );
      expect(appleAsked, 2);
    });

    test('the offering waits for an attribution in progress', () async {
      final apple = Completer<http.Response>();
      adServices = () => apple.future;

      unawaited(repository.recordAdAttribution(lookUp: true));
      final offering = repository.offering();
      apple.complete(
        http.Response(jsonEncode({'attribution': true, 'campaignId': 1}), 200),
      );

      expect((await offering).valueOrNull!.metadata['dismissible'], isFalse);
    });

    test('the offering does not wait for a slow attribution', () async {
      adServices = () => Completer<http.Response>().future;

      unawaited(repository.recordAdAttribution(lookUp: true));

      expect(await dismissible(), isTrue);
    });
  });

  test('elsewhere no ad network is asked', () async {
    var asked = false;
    adServices = () async {
      asked = true;
      return http.Response('{}', 200);
    };

    expect(
      (await repository.recordAdAttribution(lookUp: true)).valueOrNull,
      isFalse,
    );
    expect(asked, isFalse);
    expect(callsTo('enableAdServicesAttributionTokenCollection'), isEmpty);
  });
}

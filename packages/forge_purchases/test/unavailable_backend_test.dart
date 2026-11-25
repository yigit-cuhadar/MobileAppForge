import 'package:flutter_test/flutter_test.dart';
import 'package:forge_purchases/forge_purchases.dart';
import 'package:get_it/get_it.dart';

const plan = Plan(
  id: 'pro_monthly',
  period: PlanPeriod.monthly,
  price: r'$4.99',
  priceAmount: 4.99,
  currencyCode: 'USD',
);

final isUnavailable = isA<PurchaseFailure>().having(
  (f) => f.reason,
  'reason',
  PurchaseFailureReason.storeUnavailable,
);

void main() {
  late GetIt sl;

  setUp(() {
    sl = GetIt.asNewInstance();
    const PurchasesModule(
      entitlementId: 'pro',
      backend: UnavailableBackend(),
    ).register(sl);
  });

  tearDown(() => sl.reset());

  test('entitles nobody', () async {
    final cubit = sl<EntitlementCubit>();
    expect((await cubit.identify('u1')).isOk, isTrue);
    expect(cubit.state, const EntitlementInactive());
    expect((await cubit.reset()).isOk, isTrue);
    expect(cubit.state, const EntitlementInactive());
    await cubit.close();
    expect(sl.isRegistered<FakePurchasesRepository>(), isFalse);
  });

  test('every store call reports the store unavailable', () async {
    final repository = sl<PurchasesRepository>();
    expect((await repository.offering()).failureOrNull, isUnavailable);
    expect((await repository.purchase(plan)).failureOrNull, isUnavailable);
    expect((await repository.restore()).failureOrNull, isUnavailable);
    expect((await repository.managementUrl()).failureOrNull, isUnavailable);
    expect(
      (await repository.presentCustomerCenter()).failureOrNull,
      isUnavailable,
    );
    expect(
      (await repository.recordAdAttribution(lookUp: true)).valueOrNull,
      isFalse,
    );
  });

  test('the paywall fails to load with the store unavailable', () async {
    final paywall = sl<PaywallCubit>();
    await paywall.load();
    expect(paywall.state.loadFailure, isUnavailable);
    await paywall.close();
  });
}

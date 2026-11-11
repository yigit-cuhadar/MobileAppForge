import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_purchases/forge_purchases.dart';

const monthly = Plan(
  id: 'pro_monthly',
  period: PlanPeriod.monthly,
  price: r'$4.99',
  priceAmount: 4.99,
  currencyCode: 'USD',
);
const yearly = Plan(
  id: 'pro_yearly',
  period: PlanPeriod.yearly,
  price: r'$39.99',
  priceAmount: 39.99,
  currencyCode: 'USD',
  trial: OfferPeriod(7, PeriodUnit.day),
);
const lifetime = Plan(
  id: 'pro_lifetime',
  period: PlanPeriod.lifetime,
  price: r'$99.99',
  priceAmount: 99.99,
  currencyCode: 'USD',
);

void main() {
  late DateTime now;
  late FakePurchasesRepository repository;

  setUp(() async {
    now = DateTime.utc(2026, 1, 1);
    repository = FakePurchasesRepository(
      plans: const [monthly, yearly, lifetime],
      purchaseDelay: Duration.zero,
      clock: () => now,
    );
    await repository.configure();
  });

  Future<Entitlement> buy(Plan plan) async =>
      (await repository.purchase(plan)).valueOrNull!;

  Future<Entitlement> current() => repository.watchEntitlement().first;

  group('stream', () {
    test('emits nothing before configure', () async {
      final fresh = FakePurchasesRepository(plans: const [monthly]);
      final values = <Entitlement>[];
      final subscription = fresh.watchEntitlement().listen(values.add);
      await pumpEventQueue();
      expect(values, isEmpty);

      await fresh.configure();
      await pumpEventQueue();
      expect(values, [const Entitlement.none()]);
      await subscription.cancel();
    });

    test('a late listener gets the latest value first', () async {
      await buy(monthly);
      expect((await current()).isActive, isTrue);
    });

    test('listeners see every change in order', () async {
      final values = <bool>[];
      final subscription = repository.watchEntitlement().listen(
        (e) => values.add(e.isActive),
      );
      await buy(monthly);
      await repository.reset();
      await pumpEventQueue();
      expect(values, [false, true, false]);
      await subscription.cancel();
    });
  });

  group('purchase', () {
    test('activates a monthly plan for one month', () async {
      final entitlement = await buy(monthly);

      expect(
        entitlement,
        Entitlement(
          isActive: true,
          productId: monthly.id,
          expiresAt: DateTime.utc(2026, 2, 1),
          willRenew: true,
          store: PurchaseStore.test,
        ),
      );
      expect(await current(), entitlement);
    });

    test('lifetime never expires or renews', () async {
      await buy(lifetime);
      now = DateTime.utc(2040, 1, 1);
      repository.refresh();

      final entitlement = await current();
      expect(entitlement.isActive, isTrue);
      expect(entitlement.expiresAt, isNull);
      expect(entitlement.willRenew, isFalse);
    });

    test('an unknown plan is not available', () async {
      final result = await repository.purchase(
        const Plan(
          id: 'other',
          period: PlanPeriod.monthly,
          price: '',
          priceAmount: 0,
          currencyCode: 'USD',
        ),
      );
      expect(
        (result.failureOrNull! as PurchaseFailure).reason,
        PurchaseFailureReason.productNotAvailable,
      );
    });

    test('buying the active plan again is already owned', () async {
      await buy(monthly);
      final result = await repository.purchase(monthly);
      expect(
        (result.failureOrNull! as PurchaseFailure).reason,
        PurchaseFailureReason.alreadyOwned,
      );
    });

    test('buying another plan replaces the active one', () async {
      await buy(monthly);
      final entitlement = await buy(lifetime);
      expect(entitlement.productId, lifetime.id);
      expect(entitlement.isActive, isTrue);
    });

    for (final failure in const [
      PurchaseFailure(PurchaseFailureReason.cancelled),
      PurchaseFailure(PurchaseFailureReason.pending),
      PurchaseFailure(PurchaseFailureReason.storeUnavailable),
      NetworkFailure(),
    ]) {
      test('fails with $failure while the switch is set', () async {
        repository.failure = failure;
        expect((await repository.purchase(monthly)).failureOrNull, failure);
        expect((await repository.restore()).failureOrNull, failure);
        expect((await repository.offering()).failureOrNull, failure);
        expect(await current(), const Entitlement.none());

        repository.failure = null;
        expect((await repository.purchase(monthly)).isOk, isTrue);
      });
    }
  });

  group('trial and renewal', () {
    test(
      'a trial plan starts in trial, then renews into a paid year',
      () async {
        final trial = await buy(yearly);
        expect(trial.isInTrial, isTrue);
        expect(trial.expiresAt, DateTime.utc(2026, 1, 8));

        now = DateTime.utc(2026, 1, 8);
        repository.refresh();
        final paid = await current();
        expect(paid.isActive, isTrue);
        expect(paid.isInTrial, isFalse);
        expect(paid.expiresAt, DateTime.utc(2027, 1, 8));
      },
    );

    test('renews over several periods', () async {
      await buy(monthly);
      now = DateTime.utc(2026, 4, 15);
      repository.refresh();
      expect((await current()).expiresAt, DateTime.utc(2026, 5, 1));
    });

    test('a cancelled renewal expires at the end of the period', () async {
      await buy(monthly);
      repository.cancelRenewal();
      expect((await current()).willRenew, isFalse);

      now = DateTime.utc(2026, 1, 31);
      repository.refresh();
      expect((await current()).isActive, isTrue);

      now = DateTime.utc(2026, 2, 1);
      repository.refresh();
      expect(
        await current(),
        Entitlement(
          isActive: false,
          productId: monthly.id,
          expiresAt: DateTime.utc(2026, 2, 1),
          store: PurchaseStore.test,
        ),
      );
    });

    test('a trial is granted only once', () async {
      await buy(yearly);
      repository.cancelRenewal();
      now = DateTime.utc(2026, 2, 1);

      final again = await buy(yearly);
      expect(again.isInTrial, isFalse);
      expect(again.expiresAt, DateTime.utc(2027, 2, 1));
    });
  });

  group('users', () {
    test('entitlements stay with the user who bought them', () async {
      await repository.identify('a');
      await buy(monthly);

      await repository.reset();
      expect(await current(), const Entitlement.none());
      await repository.identify('b');
      expect(await current(), const Entitlement.none());
      await repository.identify('a');
      expect((await current()).isActive, isTrue);
    });

    test('restore moves the store purchase to the current user', () async {
      await repository.identify('a');
      await buy(monthly);
      await repository.identify('b');

      final restored = await repository.restore();
      expect(restored.valueOrNull!.isActive, isTrue);

      await repository.identify('a');
      expect(await current(), const Entitlement.none());
    });

    test('restore without purchases is not entitled', () async {
      expect(
        (await repository.restore()).valueOrNull,
        const Entitlement.none(),
      );
    });
  });

  test('offering lists the configured plans in order', () async {
    expect(
      (await repository.offering()).valueOrNull,
      const Offering([monthly, yearly, lifetime]),
    );
  });
}

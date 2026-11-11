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

PurchaseFailureReason? reasonOf(Result<Object?> result) =>
    switch (result.failureOrNull) {
      PurchaseFailure(:final reason) => reason,
      _ => null,
    };

void main() {
  late DateTime now;
  late FakePurchasesRepository repository;

  FakePurchasesRepository build({String? cachedUserId}) =>
      FakePurchasesRepository(
        plans: const [monthly, yearly, lifetime],
        purchaseDelay: Duration.zero,
        cachedUserId: cachedUserId,
        clock: () => now,
      );

  setUp(() async {
    now = DateTime.utc(2026, 1, 1);
    repository = build();
    await repository.configure();
    await repository.identify('a');
  });

  Future<Entitlement> buy(Plan plan) async =>
      (await repository.purchase(plan)).valueOrNull!;

  Future<Entitlement> current() => repository.watchEntitlement().first;

  Future<List<Entitlement>> emitted(Future<void> Function() act) async {
    final values = <Entitlement>[];
    final subscription = repository.watchEntitlement().listen(values.add);
    await act();
    await pumpEventQueue();
    await subscription.cancel();
    return values;
  }

  group('stream', () {
    test('emits nothing until a user is identified or reset', () async {
      repository = build();
      await repository.configure();
      expect(await emitted(() async {}), isEmpty);
      expect(await emitted(() => repository.reset()), [
        const Entitlement.none(),
      ]);
    });

    test('a late listener gets the latest value first', () async {
      await buy(monthly);
      expect((await current()).isActive, isTrue);
    });

    test('listeners see every change in order', () async {
      final values = await emitted(() async {
        await buy(monthly);
        await repository.reset();
      });
      expect(values.map((e) => e.isActive), [false, true, false]);
    });

    test('a failed switch replays nothing of the previous user', () async {
      await buy(monthly);
      repository.sessionFailure = const NetworkFailure();
      expect((await repository.identify('b')).failureOrNull, isNotNull);

      expect(
        await emitted(() async {
          repository.cancelRenewal();
          await repository.refresh();
        }),
        isEmpty,
      );
    });
  });

  group('session', () {
    test('switches fail while the session switch is set', () async {
      repository.sessionFailure = const NetworkFailure();
      expect(
        (await repository.identify('b')).failureOrNull,
        const NetworkFailure(),
      );
      expect((await repository.reset()).failureOrNull, isNotNull);
      final fresh = build()..sessionFailure = const NetworkFailure();
      expect((await fresh.configure()).failureOrNull, isNotNull);

      repository.sessionFailure = null;
      expect((await repository.identify('b')).isOk, isTrue);
    });

    test('a cold start resumes the cached user until reset', () async {
      repository = build(cachedUserId: 'a');
      await repository.configure();
      await buy(monthly);

      expect((await repository.reset()).valueOrNull, const Entitlement.none());
      expect((await repository.identify('a')).valueOrNull!.isActive, isTrue);
    });

    test('entitlements stay with the user who bought them', () async {
      await buy(monthly);
      expect((await repository.reset()).valueOrNull, const Entitlement.none());
      expect(
        (await repository.identify('b')).valueOrNull,
        const Entitlement.none(),
      );
      expect((await repository.identify('a')).valueOrNull!.isActive, isTrue);
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

      final entitlement = (await repository.refresh()).valueOrNull!;
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
      expect(reasonOf(result), PurchaseFailureReason.productNotAvailable);
    });

    test('buying the own active plan again is already owned', () async {
      await buy(monthly);
      expect(
        reasonOf(await repository.purchase(monthly)),
        PurchaseFailureReason.alreadyOwned,
      );
    });

    test('buying a plan another user holds transfers it', () async {
      await buy(monthly);
      await repository.identify('b');

      expect((await buy(monthly)).isActive, isTrue);
      expect(
        (await repository.identify('a')).valueOrNull,
        const Entitlement.none(),
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

    test('a pending purchase resolves later through the stream', () async {
      repository.failure = const PurchaseFailure(PurchaseFailureReason.pending);
      expect(
        reasonOf(await repository.purchase(monthly)),
        PurchaseFailureReason.pending,
      );
      repository.failure = null;

      final values = await emitted(() async => repository.approvePending());
      expect(values.map((e) => e.isActive), [false, true]);
    });
  });

  group('trial and renewal', () {
    test(
      'a trial plan starts in trial, then renews into a paid year',
      () async {
        final trial = await buy(yearly);
        expect(trial.isInTrial, isTrue);
        expect(trial.expiresAt, DateTime.utc(2026, 1, 8));

        now = DateTime.utc(2026, 1, 8);
        final paid = (await repository.refresh()).valueOrNull!;
        expect(paid.isActive, isTrue);
        expect(paid.isInTrial, isFalse);
        expect(paid.expiresAt, DateTime.utc(2027, 1, 8));
      },
    );

    test('renews over several periods', () async {
      await buy(monthly);
      now = DateTime.utc(2026, 4, 15);
      expect(
        (await repository.refresh()).valueOrNull!.expiresAt,
        DateTime.utc(2026, 5, 1),
      );
    });

    test('renewals clamp to month ends and keep the original day', () async {
      now = DateTime.utc(2026, 1, 31);
      expect((await buy(monthly)).expiresAt, DateTime.utc(2026, 2, 28));

      now = DateTime.utc(2026, 2, 28);
      expect(
        (await repository.refresh()).valueOrNull!.expiresAt,
        DateTime.utc(2026, 3, 31),
      );
    });

    test('a cancelled renewal expires at the end of the period', () async {
      await buy(monthly);
      repository.cancelRenewal();
      expect((await current()).willRenew, isFalse);

      now = DateTime.utc(2026, 1, 31);
      expect((await repository.refresh()).valueOrNull!.isActive, isTrue);

      now = DateTime.utc(2026, 2, 1);
      expect(
        (await repository.refresh()).valueOrNull,
        Entitlement(
          isActive: false,
          productId: monthly.id,
          expiresAt: DateTime.utc(2026, 2, 1),
          store: PurchaseStore.test,
        ),
      );
    });

    test(
      'trials are offered per user until their first subscription',
      () async {
        Future<OfferPeriod?> offeredTrial() async =>
            (await repository.offering()).valueOrNull!.plans
                .singleWhere((p) => p.id == yearly.id)
                .trial;

        expect(await offeredTrial(), yearly.trial);
        await buy(yearly);
        repository.cancelRenewal();
        now = DateTime.utc(2026, 2, 1);
        expect(await offeredTrial(), isNull);

        final again = await buy(yearly);
        expect(again.isInTrial, isFalse);
        expect(again.expiresAt, DateTime.utc(2027, 2, 1));

        await repository.identify('b');
        expect(await offeredTrial(), yearly.trial);
      },
    );
  });

  group('restore', () {
    test('moves the store purchase to the current user', () async {
      await buy(monthly);
      await repository.identify('b');

      expect((await repository.restore()).valueOrNull!.isActive, isTrue);
      expect(
        (await repository.identify('a')).valueOrNull,
        const Entitlement.none(),
      );
    });

    test('without purchases is not entitled', () async {
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

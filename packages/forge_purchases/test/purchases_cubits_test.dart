import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_purchases/forge_purchases.dart';
import 'package:mocktail/mocktail.dart';

class MockPurchasesRepository extends Mock implements PurchasesRepository {}

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
);
const active = Entitlement(isActive: true, productId: 'pro_monthly');

void main() {
  setUpAll(() => registerFallbackValue(monthly));

  group('EntitlementCubit', () {
    late FakePurchasesRepository store;

    EntitlementCubit build(
      PurchasesRepository repository, {
      DateTime Function()? clock,
    }) => EntitlementCubit(
      configure: ConfigurePurchases(repository),
      watchEntitlement: WatchEntitlement(repository),
      identify: IdentifyPurchaser(repository),
      reset: ResetPurchaser(repository),
      refresh: RefreshEntitlement(repository),
      getManagementUrl: GetManagementUrl(repository),
      clock: clock,
    );

    FakePurchasesRepository fake({String? cachedUserId}) =>
        FakePurchasesRepository(
          plans: const [monthly],
          purchaseDelay: Duration.zero,
          cachedUserId: cachedUserId,
        );

    Future<List<EntitlementState>> statesOf(
      EntitlementCubit cubit,
      Future<void> Function() act,
    ) async {
      final states = <EntitlementState>[];
      final subscription = cubit.stream.listen(states.add);
      await act();
      await pumpEventQueue();
      await subscription.cancel();
      return states;
    }

    setUp(() => store = fake());

    test('stays unknown until the first identify or reset', () async {
      final cubit = build(store);
      await pumpEventQueue();
      expect(cubit.state, const EntitlementUnknown());

      await cubit.reset();
      expect(cubit.state, const EntitlementInactive());
      await cubit.close();
    });

    test('follows identify and reset', () async {
      final cubit = build(store);
      final states = await statesOf(cubit, () async {
        await cubit.identify('a');
        await store.purchase(monthly);
        await pumpEventQueue();
        await cubit.reset();
        await cubit.identify('a');
      });

      expect(states.map((s) => s.runtimeType), [
        EntitlementInactive,
        EntitlementActive,
        EntitlementUnknown,
        EntitlementInactive,
        EntitlementUnknown,
        EntitlementActive,
      ]);
      await cubit.close();
    });

    test('identifying the same user again does nothing', () async {
      final cubit = build(store);
      await cubit.identify('a');
      expect(await statesOf(cubit, () => cubit.identify('a')), isEmpty);
      await cubit.close();
    });

    test('a cold start with a cached user is signed out by reset', () async {
      store = fake(cachedUserId: 'a');
      await store.configure();
      await store.purchase(monthly);

      final cubit = build(store);
      await cubit.reset();
      expect(cubit.state, const EntitlementInactive());

      await cubit.identify('a');
      expect(cubit.isActive, isTrue);
      await cubit.close();
    });

    test('a failed reset is inactive', () async {
      final cubit = build(store);
      await cubit.identify('a');
      await store.purchase(monthly);
      await pumpEventQueue();

      store.sessionFailure = const NetworkFailure();
      expect((await cubit.reset()).isOk, isFalse);
      expect(cubit.state, const EntitlementInactive());
      await cubit.close();
    });

    group('after a failed identify', () {
      late MockPurchasesRepository repository;
      late StreamController<Entitlement> entitlements;

      setUp(() {
        repository = MockPurchasesRepository();
        entitlements = StreamController<Entitlement>.broadcast();
        when(() => repository.watchEntitlement())
            .thenAnswer((_) => entitlements.stream);
        when(() => repository.configure())
            .thenAnswer((_) async => const Ok(null));
        when(() => repository.identify('a'))
            .thenAnswer((_) async => const Ok(active));
      });

      test('the next user never sees the previous user', () async {
        Result<Entitlement> identifyB = const Err(NetworkFailure());
        when(() => repository.identify('b')).thenAnswer((_) async => identifyB);
        final cubit = build(repository);
        await cubit.identify('a');
        expect(cubit.isActive, isTrue);

        final states = await statesOf(cubit, () async {
          expect((await cubit.identify('b')).isOk, isFalse);
          // The store is still on the previous user and keeps reporting it.
          entitlements.add(active);
        });
        expect(states, const [EntitlementUnknown()]);

        identifyB = const Ok(Entitlement.none());
        await cubit.identify('b');
        expect(cubit.state, const EntitlementInactive());
        await cubit.close();
      });
    });

    test('re-checks the store when the entitlement expires', () {
      fakeAsync((async) {
        final start = DateTime.utc(2026);
        DateTime now() => start.add(async.elapsed);
        final store = FakePurchasesRepository(
          plans: const [monthly],
          purchaseDelay: Duration.zero,
          clock: now,
        );
        final cubit = build(store, clock: now);
        unawaited(cubit.identify('a'));
        unawaited(store.purchase(monthly));
        async.elapse(Duration.zero);
        store.cancelRenewal();
        async.flushMicrotasks();
        expect(cubit.isActive, isTrue);

        async.elapse(const Duration(days: 30));
        expect(cubit.isActive, isTrue);
        async.elapse(const Duration(days: 1));
        expect(cubit.state, const EntitlementInactive());
        unawaited(cubit.close());
      });
    });
  });

  group('PaywallCubit', () {
    late MockPurchasesRepository repository;

    PaywallCubit build() => PaywallCubit(
      getOffering: GetOffering(repository),
      purchasePlan: PurchasePlan(repository),
      restorePurchases: RestorePurchases(repository),
    );

    const ready = PaywallState(
      status: PaywallStatus.ready,
      plans: [monthly, yearly],
      selected: monthly,
    );

    PaywallState readyWith(PaywallOutcome outcome, [Failure? failure]) =>
        PaywallState(
          status: PaywallStatus.ready,
          plans: ready.plans,
          selected: monthly,
          outcome: outcome,
          failure: failure,
        );

    setUp(() {
      repository = MockPurchasesRepository();
      when(() => repository.offering())
          .thenAnswer((_) async => const Ok(Offering([monthly, yearly])));
    });

    blocTest<PaywallCubit, PaywallState>(
      'loads the offering and selects the first plan',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => const [PaywallState(), ready],
    );

    blocTest<PaywallCubit, PaywallState>(
      'a failed load can be retried',
      setUp: () =>
          when(() => repository.offering())
              .thenAnswer((_) async => const Err(NetworkFailure())),
      build: build,
      act: (cubit) async {
        await cubit.load();
        when(() => repository.offering())
            .thenAnswer((_) async => const Ok(Offering([monthly, yearly])));
        await cubit.load();
      },
      expect: () => const [
        PaywallState(),
        PaywallState(
          status: PaywallStatus.loadFailed,
          loadFailure: NetworkFailure(),
        ),
        PaywallState(),
        ready,
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'purchases the selected plan',
      setUp: () =>
          when(() => repository.purchase(yearly))
              .thenAnswer((_) async => const Ok(active)),
      build: build,
      seed: () => ready,
      act: (cubit) => cubit
        ..select(yearly)
        ..purchase(),
      expect: () => const [
        PaywallState(
          status: PaywallStatus.ready,
          plans: [monthly, yearly],
          selected: yearly,
        ),
        PaywallState(
          status: PaywallStatus.purchasing,
          plans: [monthly, yearly],
          selected: yearly,
        ),
        PaywallState(
          status: PaywallStatus.ready,
          plans: [monthly, yearly],
          selected: yearly,
          outcome: PaywallOutcome.purchased,
        ),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'a purchase that does not activate the entitlement is not purchased',
      setUp: () =>
          when(() => repository.purchase(any()))
              .thenAnswer((_) async => const Ok(Entitlement.none())),
      build: build,
      seed: () => ready,
      act: (cubit) => cubit.purchase(),
      skip: 1,
      expect: () => [readyWith(PaywallOutcome.notEntitled)],
    );

    for (final (failure, outcome) in const [
      (
        PurchaseFailure(PurchaseFailureReason.cancelled),
        PaywallOutcome.cancelled,
      ),
      (PurchaseFailure(PurchaseFailureReason.pending), PaywallOutcome.pending),
      (
        PurchaseFailure(PurchaseFailureReason.storeUnavailable),
        PaywallOutcome.failed,
      ),
      (NetworkFailure(), PaywallOutcome.failed),
    ]) {
      blocTest<PaywallCubit, PaywallState>(
        '$failure ends as ${outcome.name}',
        setUp: () =>
            when(() => repository.purchase(any()))
                .thenAnswer((_) async => Err(failure)),
        build: build,
        seed: () => ready,
        act: (cubit) => cubit.purchase(),
        skip: 1,
        expect: () => [
          readyWith(outcome, outcome == PaywallOutcome.failed ? failure : null),
        ],
      );
    }

    blocTest<PaywallCubit, PaywallState>(
      'ignores a second tap while purchasing or restoring',
      setUp: () {
        when(() => repository.purchase(any()))
            .thenAnswer((_) async => const Ok(active));
        when(() => repository.restore())
            .thenAnswer((_) async => const Ok(active));
      },
      build: build,
      seed: () => ready,
      act: (cubit) =>
          Future.wait([cubit.purchase(), cubit.purchase(), cubit.restore()]),
      verify: (_) {
        verify(() => repository.purchase(monthly)).called(1);
        verifyNever(() => repository.restore());
      },
    );

    blocTest<PaywallCubit, PaywallState>(
      'a restore without an active entitlement has nothing to restore',
      setUp: () =>
          when(() => repository.restore())
              .thenAnswer((_) async => const Ok(Entitlement.none())),
      build: build,
      seed: () => ready,
      act: (cubit) => cubit.restore(),
      expect: () => [
        const PaywallState(
          status: PaywallStatus.restoring,
          plans: [monthly, yearly],
          selected: monthly,
        ),
        readyWith(PaywallOutcome.nothingToRestore),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'restore after a failed load keeps the load failure apart',
      setUp: () => when(() => repository.restore()).thenAnswer(
        (_) async =>
            const Err(PurchaseFailure(PurchaseFailureReason.storeUnavailable)),
      ),
      build: build,
      seed: () => const PaywallState(
        status: PaywallStatus.loadFailed,
        loadFailure: NetworkFailure(),
      ),
      act: (cubit) => cubit.restore(),
      expect: () => const [
        PaywallState(
          status: PaywallStatus.restoring,
          loadFailure: NetworkFailure(),
        ),
        PaywallState(
          status: PaywallStatus.loadFailed,
          loadFailure: NetworkFailure(),
          outcome: PaywallOutcome.failed,
          failure: PurchaseFailure(PurchaseFailureReason.storeUnavailable),
        ),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'cannot purchase before the offering is loaded',
      build: build,
      act: (cubit) => cubit.purchase(),
      expect: () => const <PaywallState>[],
      verify: (_) => verifyNever(() => repository.purchase(any())),
    );
  });
}

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
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

    EntitlementCubit build(PurchasesRepository repository) => EntitlementCubit(
      configure: ConfigurePurchases(repository),
      watchEntitlement: WatchEntitlement(repository),
      identify: IdentifyPurchaser(repository),
      reset: ResetPurchaser(repository),
    );

    setUp(
      () => store = FakePurchasesRepository(
        plans: const [monthly],
        purchaseDelay: Duration.zero,
      ),
    );

    test('starts unknown, then resolves after the fake configures', () async {
      final cubit = build(store);
      expect(cubit.state, const EntitlementUnknown());
      await pumpEventQueue();
      expect(cubit.state, const EntitlementInactive());
      await cubit.close();
    });

    test('follows identify and reset', () async {
      final cubit = build(store);
      final states = <EntitlementState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.identify('a');
      await store.purchase(monthly);
      await pumpEventQueue();
      expect(cubit.isActive, isTrue);

      await cubit.reset();
      await pumpEventQueue();
      expect(cubit.state, const EntitlementInactive());

      await cubit.identify('a');
      await pumpEventQueue();
      expect(cubit.isActive, isTrue);

      expect(states.whereType<EntitlementActive>(), hasLength(2));
      expect(
        states.whereType<EntitlementUnknown>(),
        hasLength(3),
        reason: 'unknown while each user switch resolves',
      );
      await subscription.cancel();
      await cubit.close();
    });

    test('identifying the same user again does nothing', () async {
      final cubit = build(store);
      await cubit.identify('a');
      await pumpEventQueue();
      final states = <EntitlementState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.identify('a');
      await pumpEventQueue();
      expect(states, isEmpty);
      await subscription.cancel();
      await cubit.close();
    });

    group('with a failing store', () {
      late MockPurchasesRepository repository;
      late StreamController<Entitlement> entitlements;

      setUp(() {
        repository = MockPurchasesRepository();
        entitlements = StreamController<Entitlement>();
        when(() => repository.watchEntitlement())
            .thenAnswer((_) => entitlements.stream);
      });

      blocTest<EntitlementCubit, EntitlementState>(
        'a failed configure is inactive',
        setUp: () =>
            when(() => repository.configure())
                .thenAnswer((_) async => const Err(UnknownFailure())),
        build: () => build(repository),
        expect: () => const [EntitlementInactive()],
      );

      blocTest<EntitlementCubit, EntitlementState>(
        'a failed identify keeps the previous user state',
        setUp: () {
          when(() => repository.configure()).thenAnswer((_) async {
            entitlements.add(active);
            return const Ok(null);
          });
          when(() => repository.identify('b'))
              .thenAnswer((_) async => const Err(NetworkFailure()));
        },
        build: () => build(repository),
        act: (cubit) async {
          await pumpEventQueue();
          final result = await cubit.identify('b');
          expect(result.failureOrNull, isA<NetworkFailure>());
        },
        expect: () => const [
          EntitlementActive(active),
          EntitlementUnknown(),
          EntitlementActive(active),
        ],
      );
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
      act: (cubit) => cubit.load(),
      expect: () => const [
        PaywallState(),
        PaywallState(
          status: PaywallStatus.loadFailed,
          failure: NetworkFailure(),
        ),
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
          PaywallState(
            status: PaywallStatus.ready,
            plans: ready.plans,
            selected: monthly,
            outcome: outcome,
            failure: outcome == PaywallOutcome.failed ? failure : null,
          ),
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
        const PaywallState(
          status: PaywallStatus.ready,
          plans: [monthly, yearly],
          selected: monthly,
          outcome: PaywallOutcome.nothingToRestore,
        ),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      'restore works after a failed load and returns to it',
      setUp: () =>
          when(() => repository.restore())
              .thenAnswer((_) async => const Ok(active)),
      build: build,
      seed: () => const PaywallState(
        status: PaywallStatus.loadFailed,
        failure: NetworkFailure(),
      ),
      act: (cubit) => cubit.restore(),
      expect: () => const [
        PaywallState(status: PaywallStatus.restoring),
        PaywallState(
          status: PaywallStatus.loadFailed,
          outcome: PaywallOutcome.restored,
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

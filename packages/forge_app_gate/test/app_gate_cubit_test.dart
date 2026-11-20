import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_app_gate/forge_app_gate.dart';
import 'package:forge_core/forge_core.dart';
import 'package:mocktail/mocktail.dart';

class MockAppGateRepository extends Mock implements AppGateRepository {}

final v15 = Version.tryParse('1.5')!;

void main() {
  late MockAppGateRepository repository;
  late AppGateRules rules;
  late AppGateRules fetched;
  late Result<void> refreshResult;
  late Completer<void> refreshing;

  AppGateCubit build() => AppGateCubit(
    check: CheckAppGate(repository),
    refresh: RefreshAppGate(repository),
    dismissUpdate: DismissUpdate(repository),
    openStore: OpenStore(repository),
  );

  setUpAll(() => registerFallbackValue(v15));

  setUp(() {
    repository = MockAppGateRepository();
    rules = const AppGateRules();
    fetched = const AppGateRules();
    refreshResult = const Ok(null);
    refreshing = Completer()..complete();
    when(() => repository.installedVersion())
        .thenAnswer((_) async => Ok(Version.tryParse('1.4')!));
    when(() => repository.rules()).thenAnswer((_) => rules);
    when(() => repository.refresh()).thenAnswer((_) async {
      await refreshing.future;
      if (refreshResult.isOk) rules = fetched;
      return refreshResult;
    });
    when(() => repository.loadDismissed())
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.saveDismissed(any()))
        .thenAnswer((_) async => const Ok(null));
    when(() => repository.openStore()).thenAnswer((_) async => const Ok(null));
  });

  test('starts open', () {
    expect(build().state, const AppGateState());
  });

  group('start', () {
    blocTest<AppGateCubit, AppGateState>(
      'checks the last rules first, then the fetched ones',
      setUp: () {
        rules = AppGateRules(recommended: v15);
        fetched = AppGateRules(minimum: v15);
        refreshing = Completer();
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        expect(cubit.state.status, UpdateRecommended(v15));
        refreshing.complete();
      },
      expect: () => [
        AppGateState(status: UpdateRecommended(v15)),
        const AppGateState(status: UpdateRequired()),
      ],
    );

    blocTest<AppGateCubit, AppGateState>(
      'a failed fetch keeps the last rules and the app usable',
      setUp: () {
        refreshResult = const Err(NetworkFailure());
        fetched = AppGateRules(minimum: v15);
      },
      build: build,
      act: (cubit) => cubit.start(),
      wait: Duration.zero,
      expect: () => const [AppGateState()],
    );

    blocTest<AppGateCubit, AppGateState>(
      'an unknown installed version stays open',
      setUp: () {
        rules = AppGateRules(minimum: v15);
        when(() => repository.installedVersion())
            .thenAnswer((_) async => const Err(UnknownFailure('no version')));
      },
      build: build,
      act: (cubit) => cubit.start(),
      wait: Duration.zero,
      expect: () => const [AppGateState()],
    );
  });

  blocTest<AppGateCubit, AppGateState>(
    'resumed fetches and checks again',
    setUp: () => fetched = const AppGateRules(maintenance: true),
    build: build,
    act: (cubit) => cubit.resumed(),
    expect: () => const [AppGateState(status: Maintenance(''))],
  );

  group('retry', () {
    blocTest<AppGateCubit, AppGateState>(
      'is busy while it fetches, then opens the app when maintenance ended',
      setUp: () => fetched = const AppGateRules(),
      seed: () => const AppGateState(status: Maintenance('')),
      build: build,
      act: (cubit) => cubit.retry(),
      expect: () => const [
        AppGateState(status: Maintenance(''), retrying: true),
        AppGateState(retrying: true),
        AppGateState(),
      ],
    );

    blocTest<AppGateCubit, AppGateState>(
      'stays in maintenance when the fetch fails',
      setUp: () {
        rules = const AppGateRules(maintenance: true);
        refreshResult = const Err(NetworkFailure());
      },
      seed: () => const AppGateState(status: Maintenance('')),
      build: build,
      act: (cubit) => cubit.retry(),
      expect: () => const [
        AppGateState(status: Maintenance(''), retrying: true),
        AppGateState(status: Maintenance('')),
      ],
    );

    blocTest<AppGateCubit, AppGateState>(
      'ignores a second tap while busy',
      setUp: () => refreshing = Completer(),
      seed: () => const AppGateState(status: Maintenance('')),
      build: build,
      act: (cubit) async {
        unawaited(cubit.retry());
        unawaited(cubit.retry());
        refreshing.complete();
      },
      verify: (_) => verify(() => repository.refresh()).called(1),
    );
  });

  group('dismissUpdate', () {
    blocTest<AppGateCubit, AppGateState>(
      'opens the app and saves the dismissed version',
      seed: () => AppGateState(status: UpdateRecommended(v15)),
      build: build,
      act: (cubit) => cubit.dismissUpdate(),
      expect: () => const [AppGateState()],
      verify: (_) => verify(() => repository.saveDismissed(v15)).called(1),
    );

    blocTest<AppGateCubit, AppGateState>(
      'a check that started before it does not bring the offer back',
      setUp: () => rules = AppGateRules(recommended: v15),
      seed: () => AppGateState(status: UpdateRecommended(v15)),
      build: build,
      act: (cubit) async {
        final installed = Completer<Result<Version>>();
        when(() => repository.installedVersion())
            .thenAnswer((_) => installed.future);
        final resumed = cubit.resumed();
        await pumpEventQueue();
        verify(() => repository.installedVersion()).called(1);
        await cubit.dismissUpdate();
        installed.complete(Ok(Version.tryParse('1.4')!));
        await resumed;
      },
      expect: () => const [AppGateState()],
    );

    blocTest<AppGateCubit, AppGateState>(
      'does nothing without an offer',
      build: build,
      act: (cubit) => cubit.dismissUpdate(),
      expect: () => const <AppGateState>[],
      verify: (_) => verifyNever(() => repository.saveDismissed(any())),
    );
  });

  group('once per launch', () {
    blocTest<AppGateCubit, AppGateState>(
      'a dismissed or answered offer does not come back on resume',
      setUp: () => fetched = AppGateRules(recommended: v15),
      build: build,
      act: (cubit) async {
        await cubit.resumed();
        await cubit.openStore();
        await cubit.resumed();
      },
      expect: () => [
        AppGateState(status: UpdateRecommended(v15)),
        const AppGateState(),
      ],
      verify: (_) => verifyNever(() => repository.saveDismissed(any())),
    );

    blocTest<AppGateCubit, AppGateState>(
      'an offer that is still up stays up on resume',
      setUp: () => fetched = AppGateRules(recommended: v15),
      build: build,
      act: (cubit) async {
        await cubit.resumed();
        await cubit.resumed();
      },
      expect: () => [AppGateState(status: UpdateRecommended(v15))],
    );

    blocTest<AppGateCubit, AppGateState>(
      'a required update still closes the app after an offer',
      setUp: () => fetched = AppGateRules(recommended: v15),
      build: build,
      act: (cubit) async {
        await cubit.resumed();
        await cubit.dismissUpdate();
        fetched = AppGateRules(minimum: v15);
        await cubit.resumed();
      },
      expect: () => [
        AppGateState(status: UpdateRecommended(v15)),
        const AppGateState(),
        const AppGateState(status: UpdateRequired()),
      ],
    );
  });

  blocTest<AppGateCubit, AppGateState>(
    'openStore from the required update keeps it',
    seed: () => const AppGateState(status: UpdateRequired()),
    build: build,
    act: (cubit) => cubit.openStore(),
    expect: () => const <AppGateState>[],
    verify: (_) => verify(() => repository.openStore()).called(1),
  );
}

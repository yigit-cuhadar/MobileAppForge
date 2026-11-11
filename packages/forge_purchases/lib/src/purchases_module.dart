import 'package:flutter/foundation.dart';
import 'package:forge_core/forge_core.dart';
import 'package:get_it/get_it.dart';

import 'data/fake_purchases_repository.dart';
import 'data/revenuecat_purchases_repository.dart';
import 'domain/purchases_models.dart';
import 'domain/purchases_repository.dart';
import 'domain/purchases_usecases.dart';
import 'presentation/entitlement_cubit.dart';
import 'presentation/paywall_cubit.dart';

/// Where purchases go: RevenueCat or the in-memory fake.
sealed class PurchasesBackend {
  const PurchasesBackend();
}

/// RevenueCat public SDK keys (`appl_…`, `goog_…`); they are not secrets.
final class RevenueCatBackend extends PurchasesBackend {
  const RevenueCatBackend({
    required this.appleApiKey,
    required this.googleApiKey,
  });

  final String appleApiKey;
  final String googleApiKey;
}

/// The fake, offering [plans]. Its controls are on the registered
/// [FakePurchasesRepository].
final class FakeBackend extends PurchasesBackend {
  const FakeBackend(this.plans);

  final List<Plan> plans;
}

/// Registers purchases for the app's single [entitlementId].
class PurchasesModule implements FeatureModule {
  const PurchasesModule({required this.entitlementId, required this.backend});

  final String entitlementId;
  final PurchasesBackend backend;

  @override
  void register(GetIt sl) {
    switch (backend) {
      case RevenueCatBackend(:final appleApiKey, :final googleApiKey):
        sl.registerLazySingleton<PurchasesRepository>(
          () => RevenueCatPurchasesRepository(
            apiKey: defaultTargetPlatform == TargetPlatform.android
                ? googleApiKey
                : appleApiKey,
            entitlementId: entitlementId,
          ),
        );
      case FakeBackend(:final plans):
        sl
          ..registerLazySingleton(() => FakePurchasesRepository(plans: plans))
          ..registerLazySingleton<PurchasesRepository>(
            () => sl<FakePurchasesRepository>(),
          );
    }
    sl
      ..registerFactory(() => ConfigurePurchases(sl()))
      ..registerFactory(() => IdentifyPurchaser(sl()))
      ..registerFactory(() => ResetPurchaser(sl()))
      ..registerFactory(() => WatchEntitlement(sl()))
      ..registerFactory(() => GetOffering(sl()))
      ..registerFactory(() => PurchasePlan(sl()))
      ..registerFactory(() => RestorePurchases(sl()))
      ..registerFactory(() => GetManagementUrl(sl()))
      ..registerLazySingleton(
        () => EntitlementCubit(
          configure: sl(),
          watchEntitlement: sl(),
          identify: sl(),
          reset: sl(),
        ),
      )
      ..registerFactory(
        () => PaywallCubit(
          getOffering: sl(),
          purchasePlan: sl(),
          restorePurchases: sl(),
        ),
      );
  }
}

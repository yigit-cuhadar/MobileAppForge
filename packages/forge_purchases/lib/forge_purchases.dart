/// Subscriptions and entitlements: RevenueCat, or an in-memory fake until
/// store accounts exist.
///
/// **Switching.** Only the backend changes; the app's code is the same:
/// `PurchasesModule(entitlementId: 'premium', backend: FakeBackend([...plans]))`
/// or `backend: RevenueCatBackend(appleApiKey: ..., googleApiKey: ...)`.
/// Plan ids are store product ids; keep the fake's ids equal to the real ones.
/// Wire the app's session to `EntitlementCubit.identify(uid)` / `reset()`.
///
/// **RevenueCat setup.** One project, one entitlement attached to every
/// product, products in a "current" offering as Monthly/Annual/Lifetime
/// packages.
/// - iOS: In-App Purchase capability; products and the Paid Apps agreement in
///   App Store Connect; an In-App Purchase key (.p8) uploaded to RevenueCat;
///   App Store Server Notifications pointed at RevenueCat. For simulator runs
///   without App Store Connect, a StoreKit Configuration file selected in the
///   Run scheme. Prefer Swift Package Manager (the SDK is leaving CocoaPods).
/// - Android: the `com.android.vending.BILLING` permission comes from the
///   Play Billing manifest merge (check it is in the merged manifest);
///   `MainActivity` launchMode `standard` or `singleTop`, or purchases
///   needing app switches get cancelled; Kotlin 2.1+ and compileSdk 35;
///   subscriptions in Play Console on an app uploaded to a test track, a
///   service account key uploaded to RevenueCat, Real-time developer
///   notifications sent to RevenueCat, license testers for test purchases.
///
/// **Server-trusted entitlements.** The client's entitlement is for UI gating
/// only; it can be tampered with. Anything that costs money or exposes paid
/// data is enforced by the backend: a RevenueCat webhook (with an
/// Authorization header secret) calls the app's backend, which stores the
/// entitlement under the app user id (the id passed to `identify`) and
/// enforces it in security rules or functions.
library;

export 'src/data/fake_purchases_repository.dart';
export 'src/domain/purchases_models.dart';
export 'src/domain/purchases_repository.dart';
export 'src/domain/purchases_usecases.dart';
export 'src/presentation/entitlement_cubit.dart';
export 'src/presentation/paywall_cubit.dart';
export 'src/purchases_module.dart';

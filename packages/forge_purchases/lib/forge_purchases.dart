/// Subscriptions and entitlements: RevenueCat, or an in-memory fake until
/// store accounts exist.
///
/// **Switching.** Only the backend changes; the app's code is the same:
/// `PurchasesModule(entitlementId: 'premium', backend: FakeBackend([...plans]))`
/// or `backend: RevenueCatBackend(appleApiKey: ..., googleApiKey: ...)`.
/// Plan ids follow RevenueCat (`productId` on the App Store,
/// `subscriptionId:basePlanId` on Play) and `Entitlement.productId` uses the
/// same form, so compare them with each other and pick plans by
/// `Plan.period`, never by hard-coded ids. The fake's ids are free.
/// Wire the app's session to `EntitlementCubit`: `identify(uid)` when signed
/// in, `reset()` when signed out, at startup and on every change; the state
/// stays unknown until then. For "Manage subscription", present
/// `EntitlementCubit.presentCustomerCenter()` (RevenueCat's Customer Center)
/// or open `EntitlementCubit.managementUrl()` where it gives false.
///
/// **RevenueCat setup.** One project, one entitlement attached to every
/// product, products in a "current" offering as Monthly/Annual/Lifetime
/// packages.
/// - iOS: In-App Purchase capability; products and the Paid Apps agreement in
///   App Store Connect; an In-App Purchase key (.p8) uploaded to RevenueCat;
///   App Store Server Notifications pointed at RevenueCat. For simulator runs
///   without App Store Connect, a StoreKit Configuration file selected in the
///   Run scheme. Prefer Swift Package Manager (the SDK is leaving CocoaPods).
///   Win-back offers (iOS 18+) are created in App Store Connect once the
///   subscription is approved; the paywall shows them as `Plan.winBack`.
/// - Customer Center (RevenueCat Pro plan, free below its revenue threshold):
///   enabled and themed under Project settings › Customer Center; its
///   retention offers map each product to a store promotional offer id
///   (Lifecycle › Retention), so the offers must exist in the store first.
/// - Android: the `com.android.vending.BILLING` permission comes from the
///   Play Billing manifest merge (check it is in the merged manifest);
///   `MainActivity` launchMode `standard` or `singleTop`, or purchases
///   needing app switches get cancelled; Kotlin 2.1+ and compileSdk 35;
///   subscriptions in Play Console on an app uploaded to a test track, a
///   service account key uploaded to RevenueCat, Real-time developer
///   notifications sent to RevenueCat, license testers for test purchases.
///
/// **Paid traffic.** `RecordAdAttribution` after the user is identified
/// asks Apple Search Ads (AdServices, iOS 14.3+, no tracking prompt)
/// whether the install came from a campaign; if so it sets the RevenueCat
/// custom attributes `ad_network` = `apple_search_ads` and `ad_campaign_id`
/// = the campaign id, and reloads the offering. A Targeting rule on those
/// attributes then serves another offering (e.g. one whose metadata makes
/// the paywall hard). Target campaign ids, not just the network: a device
/// in developer mode gets Apple's test record, campaign 1234567890. Add the
/// Apple AdServices integration (Basic) in RevenueCat for its own charts.
/// App Store privacy: declare Advertising Data (Usage Data), linked to the
/// user, not used for tracking.
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

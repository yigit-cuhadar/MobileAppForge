import 'package:forge_core/forge_core.dart';

enum PlanPeriod { monthly, yearly, lifetime }

enum PeriodUnit { day, week, month, year }

/// A length such as "7 days" or "1 month", kept in store units so the app
/// can phrase it.
class OfferPeriod extends Equatable {
  const OfferPeriod(this.count, this.unit);

  final int count;
  final PeriodUnit unit;

  @override
  List<Object?> get props => [count, unit];
}

/// A paid offer price, e.g. [price] per [period] for [cycles] periods: an
/// introductory price, or a [WinBackOffer]'s discount.
class IntroOffer extends Equatable {
  const IntroOffer({
    required this.price,
    required this.period,
    required this.cycles,
  });

  /// Localized, e.g. `€0.99`.
  final String price;
  final OfferPeriod period;
  final int cycles;

  @override
  List<Object?> get props => [price, period, cycles];
}

/// The store's offer to a lapsed subscriber (Apple's win-back offer):
/// either [free] for a while or a paid [discount]. Purchasing the plan that
/// carries it applies it.
class WinBackOffer extends Equatable {
  const WinBackOffer.free(this.id, OfferPeriod this.free) : discount = null;

  const WinBackOffer.discount(this.id, IntroOffer this.discount) : free = null;

  /// The store's offer id.
  final String id;
  final OfferPeriod? free;
  final IntroOffer? discount;

  @override
  List<Object?> get props => [id, free, discount];
}

/// One purchasable plan.
class Plan extends Equatable {
  const Plan({
    required this.id,
    required this.period,
    required this.price,
    required this.priceAmount,
    required this.currencyCode,
    this.trial,
    this.intro,
    this.winBack,
  });

  /// Store product id as RevenueCat reports it: `productId` on the App
  /// Store, `subscriptionId:basePlanId` on Google Play. It differs per
  /// platform, so match plans by [period] in app code.
  final String id;
  final PlanPeriod period;

  /// Localized price with currency, e.g. `€29.99`.
  final String price;
  final double priceAmount;

  /// ISO 4217, e.g. `EUR`.
  final String currencyCode;

  /// Free trial; only present when the user is eligible for it.
  final OfferPeriod? trial;

  /// Paid introductory price; only present when the user is eligible.
  final IntroOffer? intro;

  /// Only present when the user is eligible; it then takes the place of
  /// [trial] and [intro], which a lapsed subscriber does not get.
  final WinBackOffer? winBack;

  @override
  List<Object?> get props => [
    id,
    period,
    price,
    priceAmount,
    currencyCode,
    trial,
    intro,
    winBack,
  ];
}

/// The plans to show on a paywall, in display order, with the offering's
/// [metadata]: the store setup's own keys (RevenueCat's offering metadata),
/// which the app reads, e.g. to pick a paywall without an app update.
class Offering extends Equatable {
  const Offering(this.plans, {this.metadata = const {}});

  final List<Plan> plans;
  final Map<String, Object?> metadata;

  @override
  List<Object?> get props => [plans, metadata];
}

enum PurchaseStore { appStore, playStore, promotional, test, other }

/// The state of one entitlement for the current user. For UI gating only:
/// anything security-relevant is enforced by the backend.
class Entitlement extends Equatable {
  const Entitlement({
    required this.isActive,
    this.productId,
    this.expiresAt,
    this.willRenew = false,
    this.isInTrial = false,
    this.hasBillingIssue = false,
    this.store,
  });

  /// Never purchased.
  const Entitlement.none() : this(isActive: false);

  final bool isActive;

  /// The product that grants (or last granted) it, in the form of [Plan.id].
  final String? productId;

  /// Null for lifetime purchases.
  final DateTime? expiresAt;
  final bool willRenew;
  final bool isInTrial;

  /// The store could not charge the renewal. While still active the user is
  /// in a grace period and should be sent to the manage page.
  final bool hasBillingIssue;
  final PurchaseStore? store;

  @override
  List<Object?> get props => [
    isActive,
    productId,
    expiresAt,
    willRenew,
    isInTrial,
    hasBillingIssue,
    store,
  ];
}

/// A store purchase that did not complete. Network problems are
/// [NetworkFailure], anything unrecognised is [UnknownFailure].
final class PurchaseFailure extends Failure {
  const PurchaseFailure(this.reason, [String? message, Object? cause])
    : super(message ?? 'Purchase failed', cause: cause);

  final PurchaseFailureReason reason;

  @override
  String toString() => 'PurchaseFailure(${reason.name}): $message';
}

enum PurchaseFailureReason {
  /// The user dismissed the store sheet; not an error to show.
  cancelled,

  /// Purchases are impossible here: store problem, restrictions or billing
  /// not set up on the device.
  storeUnavailable,
  productNotAvailable,
  alreadyOwned,

  /// Awaiting approval (Ask to Buy, pending payment); the entitlement arrives
  /// later through the entitlement stream.
  pending,
}

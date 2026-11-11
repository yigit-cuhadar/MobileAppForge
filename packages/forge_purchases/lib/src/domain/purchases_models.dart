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

/// A paid introductory price, e.g. [price] per [period] for [cycles] periods.
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
  });

  /// Store product id.
  final String id;
  final PlanPeriod period;

  /// Localized price with currency, e.g. `€29.99`.
  final String price;
  final double priceAmount;

  /// ISO 4217, e.g. `EUR`.
  final String currencyCode;

  /// Free trial offered with the plan. The store decides eligibility at
  /// purchase time; a user who already had a trial pays immediately.
  final OfferPeriod? trial;
  final IntroOffer? intro;

  @override
  List<Object?> get props => [
    id,
    period,
    price,
    priceAmount,
    currencyCode,
    trial,
    intro,
  ];
}

/// The plans to show on a paywall, in display order.
class Offering extends Equatable {
  const Offering(this.plans);

  final List<Plan> plans;

  @override
  List<Object?> get props => [plans];
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

  /// The product that grants (or last granted) it.
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

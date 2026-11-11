import 'package:forge_core/forge_core.dart';

import '../domain/purchases_models.dart';
import '../domain/purchases_repository.dart';
import 'entitlement_channel.dart';

/// In-memory store for development and demos before any store account
/// exists. Simulates one device with one store account: its subscription
/// belongs to the user who bought or last restored it, trials are granted
/// once, and renewals and expiry follow [clock]. State lives for the process.
class FakePurchasesRepository implements PurchasesRepository {
  FakePurchasesRepository({
    required this._plans,
    this.purchaseDelay = const Duration(seconds: 1),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final List<Plan> _plans;
  final DateTime Function() _clock;

  /// How long the simulated store sheet takes.
  final Duration purchaseDelay;

  /// Returned by [offering], [purchase] and [restore] until cleared, e.g.
  /// `PurchaseFailure(PurchaseFailureReason.cancelled)` or `NetworkFailure()`.
  Failure? failure;

  final _channel = EntitlementChannel();
  var _anonymousCount = 0;
  String? _user;
  _Subscription? _subscription;
  bool _trialUsed = false;

  @override
  Future<Result<void>> configure() async {
    _user ??= _newAnonymousUser();
    _publish();
    return const Ok(null);
  }

  @override
  Future<Result<void>> identify(String userId) async {
    _user = userId;
    _publish();
    return const Ok(null);
  }

  @override
  Future<Result<void>> reset() async {
    _user = _newAnonymousUser();
    _publish();
    return const Ok(null);
  }

  @override
  Stream<Entitlement> watchEntitlement() => _channel.stream;

  @override
  Future<Result<Offering>> offering() => guard(() async {
    _throwFailure();
    if (_plans.isEmpty) {
      throw const PurchaseFailure(PurchaseFailureReason.productNotAvailable);
    }
    return Offering(_plans);
  });

  @override
  Future<Result<Entitlement>> purchase(Plan plan) => guard(() async {
    await Future<void>.delayed(purchaseDelay);
    _throwFailure();
    if (!_plans.contains(plan)) {
      throw const PurchaseFailure(PurchaseFailureReason.productNotAvailable);
    }
    final current = _subscription;
    if (current != null && current.plan.id == plan.id && current.isActive) {
      throw const PurchaseFailure(PurchaseFailureReason.alreadyOwned);
    }
    final now = _clock();
    final trial = _trialUsed ? null : plan.trial;
    if (trial != null) _trialUsed = true;
    _subscription = _Subscription(
      plan: plan,
      owner: _user!,
      inTrial: trial != null,
      periodEnd: switch (plan.period) {
        PlanPeriod.lifetime => null,
        _ when trial != null => _add(now, trial),
        _ => _addPlanPeriod(now, plan.period),
      },
      clock: _clock,
    );
    return _publish();
  });

  @override
  Future<Result<Entitlement>> restore() => guard(() async {
    await Future<void>.delayed(purchaseDelay);
    _throwFailure();
    _subscription?.owner = _user!;
    return _publish();
  });

  @override
  Future<Result<Uri>> managementUrl() async => Ok(storeSubscriptionsUrl());

  /// Simulates the user turning off auto-renew in the store settings.
  void cancelRenewal() {
    _subscription?.willRenew = false;
    _publish();
  }

  /// Re-reads the subscription against the clock and emits, like the SDK
  /// refreshing when the app returns to the foreground.
  void refresh() => _publish();

  String _newAnonymousUser() =>
      r'$anonymous:'
      '${_anonymousCount++}';

  void _throwFailure() {
    final failure = this.failure;
    if (failure != null) throw failure;
  }

  Entitlement _publish() {
    final subscription = _subscription;
    return _channel.add(
      subscription == null || subscription.owner != _user
          ? const Entitlement.none()
          : subscription.toEntitlement(),
    );
  }
}

class _Subscription {
  _Subscription({
    required this.plan,
    required this.owner,
    required this.inTrial,
    required this._periodEnd,
    required this._clock,
  });

  final Plan plan;
  String owner;
  bool inTrial;
  bool willRenew = true;
  DateTime? _periodEnd;
  final DateTime Function() _clock;

  /// Null for lifetime.
  DateTime? get periodEnd {
    final end = _periodEnd;
    if (end == null || !willRenew) return end;
    var renewed = end;
    while (!_clock().isBefore(renewed)) {
      renewed = _addPlanPeriod(renewed, plan.period);
      inTrial = false;
    }
    return _periodEnd = renewed;
  }

  bool get isActive {
    final end = periodEnd;
    return end == null || _clock().isBefore(end);
  }

  Entitlement toEntitlement() {
    final active = isActive;
    final lifetime = plan.period == PlanPeriod.lifetime;
    return Entitlement(
      isActive: active,
      productId: plan.id,
      expiresAt: periodEnd,
      willRenew: active && willRenew && !lifetime,
      isInTrial: inTrial,
      store: PurchaseStore.test,
    );
  }
}

DateTime _addPlanPeriod(DateTime from, PlanPeriod period) => switch (period) {
  PlanPeriod.monthly => _add(from, const OfferPeriod(1, PeriodUnit.month)),
  PlanPeriod.yearly => _add(from, const OfferPeriod(1, PeriodUnit.year)),
  PlanPeriod.lifetime => throw ArgumentError.value(period),
};

DateTime _add(DateTime from, OfferPeriod period) => switch (period.unit) {
  PeriodUnit.day => from.add(Duration(days: period.count)),
  PeriodUnit.week => from.add(Duration(days: 7 * period.count)),
  PeriodUnit.month => from.copyWith(month: from.month + period.count),
  PeriodUnit.year => from.copyWith(year: from.year + period.count),
};

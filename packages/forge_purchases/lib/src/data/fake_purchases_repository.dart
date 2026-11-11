import 'dart:math';

import 'package:forge_core/forge_core.dart';

import '../domain/purchases_models.dart';
import '../domain/purchases_repository.dart';
import 'entitlement_channel.dart';

/// In-memory store for development and demos before any store account
/// exists. Simulates one device with one store account: its subscription
/// belongs to the user who bought or last restored it (buying it again as
/// another user transfers it, like RevenueCat's default), a user is offered
/// trials until their first subscription, as on the App Store, and renewals
/// and expiry follow the clock. State lives for the process.
class FakePurchasesRepository implements PurchasesRepository {
  /// [cachedUserId] is the user the SDK would resume on a cold start.
  FakePurchasesRepository({
    required this._plans,
    this.purchaseDelay = const Duration(seconds: 1),
    this._cachedUserId,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final List<Plan> _plans;
  final String? _cachedUserId;
  final DateTime Function() _clock;

  /// How long the simulated store sheet takes.
  final Duration purchaseDelay;

  /// Returned by [offering], [purchase] and [restore] until cleared, e.g.
  /// `PurchaseFailure(PurchaseFailureReason.cancelled)` or `NetworkFailure()`.
  /// A pending purchase completes with [approvePending].
  Failure? failure;

  /// Returned by [configure], [identify] and [reset] until cleared.
  Failure? sessionFailure;

  final _channel = EntitlementChannel();
  var _anonymousCount = 0;
  String? _user;
  _Subscription? _subscription;
  final _trialUsers = <String>{};
  ({Plan plan, String owner})? _pending;

  @override
  Future<Result<void>> configure() => guard(() async {
    _throw(sessionFailure);
    _user ??= _cachedUserId ?? _newAnonymousUser();
  });

  @override
  Future<Result<Entitlement>> identify(String userId) =>
      _switchUser(() => userId);

  @override
  Future<Result<Entitlement>> reset() => _switchUser(
    () => _user!.startsWith(_anonymousPrefix) ? _user! : _newAnonymousUser(),
  );

  @override
  Stream<Entitlement> watchEntitlement() => _channel.stream;

  @override
  Future<Result<Entitlement>> refresh() async => Ok(_publish());

  @override
  Future<Result<Offering>> offering() => guard(() async {
    _throw(failure);
    if (_plans.isEmpty) {
      throw const PurchaseFailure(PurchaseFailureReason.productNotAvailable);
    }
    final eligible = !_trialUsers.contains(_user);
    return Offering([
      for (final plan in _plans) eligible ? plan : _withoutOffers(plan),
    ]);
  });

  @override
  Future<Result<Entitlement>> purchase(Plan plan) => guard(() async {
    await Future<void>.delayed(purchaseDelay);
    final failure = this.failure;
    if (failure is PurchaseFailure &&
        failure.reason == PurchaseFailureReason.pending) {
      _pending = (plan: plan, owner: _user!);
    }
    _throw(failure);
    final current = _subscription;
    if (current != null && current.plan.id == plan.id && current.isActive) {
      if (current.owner == _user) {
        throw const PurchaseFailure(PurchaseFailureReason.alreadyOwned);
      }
      current.owner = _user!;
      return _publish();
    }
    _start(plan, _user!);
    return _publish();
  });

  @override
  Future<Result<Entitlement>> restore() => guard(() async {
    await Future<void>.delayed(purchaseDelay);
    _throw(failure);
    _subscription?.owner = _user!;
    return _publish();
  });

  @override
  Future<Result<Uri>> managementUrl() async => Ok(storeSubscriptionsUrl());

  /// Completes the last pending purchase, as an approved Ask to Buy would.
  void approvePending() {
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    _start(pending.plan, pending.owner);
    _publish();
  }

  /// Simulates the user turning off auto-renew in the store settings.
  void cancelRenewal() {
    _subscription?.willRenew = false;
    _publish();
  }

  static const _anonymousPrefix = r'$anonymous:';

  String _newAnonymousUser() => '$_anonymousPrefix${_anonymousCount++}';

  Future<Result<Entitlement>> _switchUser(String Function() nextUser) {
    _channel.close();
    return guard(() async {
      _throw(sessionFailure);
      _user = nextUser();
      return _channel.open(_entitlement());
    });
  }

  void _start(Plan plan, String owner) {
    final configured = _plans.firstWhere(
      (p) => p.id == plan.id,
      orElse: () => throw const PurchaseFailure(
        PurchaseFailureReason.productNotAvailable,
      ),
    );
    final trial = _trialUsers.add(owner) ? configured.trial : null;
    _subscription = _Subscription(
      plan: configured,
      owner: owner,
      start: _clock(),
      trial: trial,
      clock: _clock,
    );
  }

  Entitlement _publish() => _channel.add(_entitlement());

  Entitlement _entitlement() {
    final subscription = _subscription;
    return subscription == null || subscription.owner != _user
        ? const Entitlement.none()
        : subscription.toEntitlement();
  }
}

void _throw(Failure? failure) {
  if (failure != null) throw failure;
}

Plan _withoutOffers(Plan plan) => Plan(
  id: plan.id,
  period: plan.period,
  price: plan.price,
  priceAmount: plan.priceAmount,
  currencyCode: plan.currencyCode,
);

class _Subscription {
  _Subscription({
    required this.plan,
    required this.owner,
    required DateTime start,
    required OfferPeriod? trial,
    required this._clock,
  }) : _trialEnd = trial == null ? null : _add(start, trial),
       _paidStart = trial == null ? start : _add(start, trial),
       _paidPeriods = trial == null ? 1 : 0;

  final Plan plan;
  String owner;
  bool willRenew = true;
  final DateTime Function() _clock;
  final DateTime? _trialEnd;

  /// Renewals count from here, so a subscription bought on the 31st renews
  /// on the last day of shorter months and on the 31st again after them.
  final DateTime _paidStart;

  /// Paid periods begun; 0 during the trial.
  int _paidPeriods;

  bool get _isLifetime => plan.period == PlanPeriod.lifetime;

  DateTime get _currentEnd => _paidPeriods == 0
      ? _trialEnd!
      : _addMonths(
          _paidStart,
          _paidPeriods * (plan.period == PlanPeriod.yearly ? 12 : 1),
        );

  /// Null for lifetime. Renews every period that has passed.
  DateTime? get periodEnd {
    if (_isLifetime) return null;
    while (willRenew && !_clock().isBefore(_currentEnd)) {
      _paidPeriods++;
    }
    return _currentEnd;
  }

  bool get isActive {
    final end = periodEnd;
    return end == null || _clock().isBefore(end);
  }

  Entitlement toEntitlement() {
    final end = periodEnd;
    final active = isActive;
    return Entitlement(
      isActive: active,
      productId: plan.id,
      expiresAt: end,
      willRenew: active && willRenew && !_isLifetime,
      isInTrial: !_isLifetime && _paidPeriods == 0,
      store: PurchaseStore.test,
    );
  }
}

DateTime _add(DateTime from, OfferPeriod period) => switch (period.unit) {
  PeriodUnit.day => from.add(Duration(days: period.count)),
  PeriodUnit.week => from.add(Duration(days: 7 * period.count)),
  PeriodUnit.month => _addMonths(from, period.count),
  PeriodUnit.year => _addMonths(from, 12 * period.count),
};

/// Clamps to the month's last day: Jan 31 + 1 month is Feb 28 (or 29).
DateTime _addMonths(DateTime from, int months) {
  final index = from.month - 1 + months;
  final year = from.year + index ~/ 12;
  final month = index % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return from.copyWith(year: year, month: month, day: min(from.day, lastDay));
}

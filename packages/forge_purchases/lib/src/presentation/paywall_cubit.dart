import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';

import '../domain/purchases_models.dart';
import '../domain/purchases_usecases.dart';

enum PaywallStatus { loading, loadFailed, ready, purchasing, restoring }

enum PaywallOutcome {
  purchased,

  /// The store charged, but the entitlement is not active: the product is
  /// not attached to the entitlement in the store setup. Ask the user to
  /// restore or contact support.
  notEntitled,
  restored,
  nothingToRestore,

  /// The user closed the store sheet; show nothing.
  cancelled,

  /// Awaiting approval; the entitlement arrives later via `EntitlementCubit`.
  pending,

  /// See [PaywallState.failure].
  failed,
}

class PaywallState extends Equatable {
  const PaywallState({
    this.status = PaywallStatus.loading,
    this.plans = const [],
    this.selected,
    this.loadFailure,
    this.outcome,
    this.failure,
  });

  final PaywallStatus status;
  final List<Plan> plans;
  final Plan? selected;

  /// Why the offering could not be loaded ([PaywallStatus.loadFailed]).
  final Failure? loadFailure;

  /// Result of the last purchase or restore; cleared when the next starts.
  final PaywallOutcome? outcome;

  /// Why the last purchase or restore failed ([PaywallOutcome.failed]).
  final Failure? failure;

  bool get isBusy =>
      status == PaywallStatus.purchasing || status == PaywallStatus.restoring;

  PaywallState _copyWith({
    PaywallStatus? status,
    Plan? selected,
    PaywallOutcome? outcome,
    Failure? failure,
  }) => PaywallState(
    status: status ?? this.status,
    plans: plans,
    selected: selected ?? this.selected,
    loadFailure: loadFailure,
    outcome: outcome,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    plans,
    selected,
    loadFailure,
    outcome,
    failure,
  ];
}

/// Drives an app-built paywall screen. Call [load] after creating it.
class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit({
    required this._getOffering,
    required this._purchasePlan,
    required this._restorePurchases,
  }) : super(const PaywallState());

  final GetOffering _getOffering;
  final PurchasePlan _purchasePlan;
  final RestorePurchases _restorePurchases;

  /// Selects the first plan; the offering's order is the display order.
  Future<void> load() async {
    if (state.isBusy) return;
    emit(const PaywallState());
    final result = await _getOffering();
    if (isClosed) return;
    emit(
      result.fold(
        (offering) => PaywallState(
          status: PaywallStatus.ready,
          plans: offering.plans,
          selected: offering.plans.first,
        ),
        (failure) => PaywallState(
          status: PaywallStatus.loadFailed,
          loadFailure: failure,
        ),
      ),
    );
  }

  void select(Plan plan) {
    if (state.status != PaywallStatus.ready) return;
    emit(state._copyWith(selected: plan));
  }

  /// Ignored while another purchase or restore runs.
  Future<void> purchase() async {
    final plan = state.selected;
    if (state.status != PaywallStatus.ready || plan == null) return;
    emit(state._copyWith(status: PaywallStatus.purchasing));
    final result = await _purchasePlan(plan);
    if (isClosed) return;
    _finish(
      result,
      (entitlement) => entitlement.isActive
          ? PaywallOutcome.purchased
          : PaywallOutcome.notEntitled,
    );
  }

  /// Also available when loading failed, so a buyer is never locked out.
  Future<void> restore() async {
    final status = state.status;
    if (status != PaywallStatus.ready && status != PaywallStatus.loadFailed) {
      return;
    }
    emit(state._copyWith(status: PaywallStatus.restoring));
    final result = await _restorePurchases();
    if (isClosed) return;
    _finish(
      result,
      (entitlement) => entitlement.isActive
          ? PaywallOutcome.restored
          : PaywallOutcome.nothingToRestore,
    );
  }

  void _finish(
    Result<Entitlement> result,
    PaywallOutcome Function(Entitlement) onOk,
  ) {
    final failure = result.failureOrNull;
    final outcome = switch (failure) {
      null => onOk(result.valueOrNull!),
      PurchaseFailure(reason: PurchaseFailureReason.cancelled) =>
        PaywallOutcome.cancelled,
      PurchaseFailure(reason: PurchaseFailureReason.pending) =>
        PaywallOutcome.pending,
      _ => PaywallOutcome.failed,
    };
    emit(
      state._copyWith(
        status: state.loadFailure == null
            ? PaywallStatus.ready
            : PaywallStatus.loadFailed,
        outcome: outcome,
        failure: outcome == PaywallOutcome.failed ? failure : null,
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';

import '../domain/purchases_models.dart';
import '../domain/purchases_usecases.dart';

sealed class EntitlementState extends Equatable {
  const EntitlementState();

  @override
  List<Object?> get props => [];
}

/// Not resolved yet, also while switching users; do not gate on it.
final class EntitlementUnknown extends EntitlementState {
  const EntitlementUnknown();
}

final class EntitlementInactive extends EntitlementState {
  const EntitlementInactive();
}

final class EntitlementActive extends EntitlementState {
  const EntitlementActive(this.entitlement);
  final Entitlement entitlement;

  @override
  List<Object?> get props => [entitlement];
}

/// App-wide entitlement state. Registered as a singleton; configures the
/// store on creation. The app calls [identify] and [reset] when its own
/// session changes so purchases follow the account.
class EntitlementCubit extends Cubit<EntitlementState> {
  EntitlementCubit({
    required ConfigurePurchases configure,
    required WatchEntitlement watchEntitlement,
    required this._identify,
    required this._reset,
  }) : super(const EntitlementUnknown()) {
    _subscription = watchEntitlement().listen(_onEntitlement);
    _queue = _start(configure);
  }

  final IdentifyPurchaser _identify;
  final ResetPurchaser _reset;
  late final StreamSubscription<Entitlement> _subscription;

  /// Configure, then user switches, one at a time and in call order.
  late Future<void> _queue;
  String? _userId;

  bool get isActive => state is EntitlementActive;

  Future<Result<void>> identify(String userId) =>
      _switchUser(userId, () => _identify(userId));

  Future<Result<void>> reset() => _switchUser(null, _reset.call);

  Future<void> _start(ConfigurePurchases configure) async {
    final result = await configure();
    // Without a configured store nothing will arrive; treat as not entitled.
    if (!result.isOk && state is EntitlementUnknown && !isClosed) {
      emit(const EntitlementInactive());
    }
  }

  Future<Result<void>> _switchUser(
    String? userId,
    Future<Result<void>> Function() action,
  ) {
    final run = _queue.then((_) async {
      if (userId == _userId) return const Ok<void>(null);
      final previousUser = _userId;
      final previousState = state;
      _userId = userId;
      if (!isClosed) emit(const EntitlementUnknown());
      final result = await action();
      // The store still holds the previous user, and so does its state.
      if (!result.isOk) {
        _userId = previousUser;
        if (state is EntitlementUnknown && !isClosed) emit(previousState);
      }
      return result;
    });
    _queue = run;
    return run;
  }

  void _onEntitlement(Entitlement entitlement) => emit(
    entitlement.isActive
        ? EntitlementActive(entitlement)
        : const EntitlementInactive(),
  );

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

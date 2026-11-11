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

/// Not resolved: before the first [EntitlementCubit.identify] or
/// [EntitlementCubit.reset] completes, while switching users, and after a
/// failed identify. Do not gate on it.
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
/// store on creation. The app calls [identify] or [reset] at startup and on
/// every session change, so purchases follow its account.
class EntitlementCubit extends Cubit<EntitlementState> {
  EntitlementCubit({
    required ConfigurePurchases configure,
    required WatchEntitlement watchEntitlement,
    required this._identify,
    required this._reset,
    required this._refresh,
    required this._getManagementUrl,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const EntitlementUnknown()) {
    _subscription = watchEntitlement().listen(_onEntitlement);
    _queue = configure();
  }

  final IdentifyPurchaser _identify;
  final ResetPurchaser _reset;
  final RefreshEntitlement _refresh;
  final GetManagementUrl _getManagementUrl;
  final DateTime Function() _clock;
  late final StreamSubscription<Entitlement> _subscription;
  Timer? _expiryTimer;

  /// Configure, then user switches, one at a time and in call order.
  late Future<void> _queue;

  /// Whether the store is on [_userId]; until then, stream values may
  /// belong to another user and are ignored.
  bool _resolved = false;
  String? _userId;

  bool get isActive => state is EntitlementActive;

  /// A failure leaves the state unknown; call again to retry.
  Future<Result<void>> identify(String userId) =>
      _switchUser(userId, () => _identify(userId), const EntitlementUnknown());

  /// A failure leaves the state inactive: a signed-out user is not entitled.
  Future<Result<void>> reset() =>
      _switchUser(null, _reset.call, const EntitlementInactive());

  /// The platform's manage-subscription page, for the app to open.
  Future<Result<Uri>> managementUrl() => _getManagementUrl();

  Future<Result<void>> _switchUser(
    String? userId,
    Future<Result<Entitlement>> Function() action,
    EntitlementState onFailure,
  ) {
    final run = _queue.then<Result<void>>((_) async {
      if (_resolved && userId == _userId) return const Ok(null);
      _resolved = false;
      _userId = userId;
      _expiryTimer?.cancel();
      if (!isClosed && state is! EntitlementUnknown) {
        emit(const EntitlementUnknown());
      }
      final result = await action();
      if (isClosed) return result;
      result.fold((entitlement) {
        _resolved = true;
        _show(entitlement);
      }, (_) => emit(onFailure));
      return result;
    });
    _queue = run;
    return run;
  }

  void _onEntitlement(Entitlement entitlement) {
    if (_resolved) _show(entitlement);
  }

  void _show(Entitlement entitlement) {
    emit(
      entitlement.isActive
          ? EntitlementActive(entitlement)
          : const EntitlementInactive(),
    );
    // Stores do not notify when a period simply runs out; check again then.
    _expiryTimer?.cancel();
    final expiresAt = entitlement.expiresAt;
    if (!entitlement.isActive || expiresAt == null) return;
    final wait = expiresAt.difference(_clock());
    if (wait > Duration.zero) _expiryTimer = Timer(wait, _refresh.call);
  }

  @override
  Future<void> close() async {
    _expiryTimer?.cancel();
    await _subscription.cancel();
    return super.close();
  }
}

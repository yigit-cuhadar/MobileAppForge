import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';

import '../domain/app_gate_status.dart';
import '../domain/app_gate_usecases.dart';

final class AppGateState extends Equatable {
  const AppGateState({this.status = const AppOpen(), this.retrying = false});

  final AppGateStatus status;

  /// Maintenance's Retry is fetching the rules.
  final bool retrying;

  @override
  List<Object?> get props => [status, retrying];
}

/// Whether the app may be used. Registered as a singleton; [AppGate] shows
/// it. Starts open, so nothing is closed by a check that cannot run. The
/// offer of a recommended version comes at most once per launch.
class AppGateCubit extends Cubit<AppGateState> {
  AppGateCubit({
    required this._check,
    required this._refresh,
    required this._dismissUpdate,
    required this._openStore,
  }) : super(const AppGateState());

  final CheckAppGate _check;
  final RefreshAppGate _refresh;
  final DismissUpdate _dismissUpdate;
  final OpenStore _openStore;

  /// Bumped by every change of status, so a check that started earlier
  /// does not overwrite it.
  int _turn = 0;

  /// The offer of an update was made this launch.
  bool _offered = false;

  /// Checks the rules the last launch fetched, without the network, then
  /// fetches them in the background. Await it before `runApp`, so the
  /// first frame shows the right thing.
  Future<void> start() async {
    await _checkNow();
    unawaited(resumed());
  }

  /// Fetches the rules and checks again. A failed fetch keeps the last
  /// rules.
  Future<void> resumed() async {
    await _refresh();
    await _checkNow();
  }

  /// Maintenance's Retry.
  Future<void> retry() async {
    if (state.retrying) return;
    emit(AppGateState(status: state.status, retrying: true));
    await _refresh();
    await _checkNow();
    if (state.retrying) emit(AppGateState(status: state.status));
  }

  /// Closes the offer of the recommended version for good, until another
  /// one is recommended.
  Future<void> dismissUpdate() async {
    if (state.status case UpdateRecommended(:final version)) {
      _turn++;
      emit(const AppGateState());
      await _dismissUpdate(version);
    }
  }

  /// Opens the store. From the offer of an update, closes it for this
  /// launch only.
  Future<void> openStore() async {
    if (state.status is UpdateRecommended) {
      _turn++;
      emit(const AppGateState());
    }
    await _openStore();
  }

  Future<void> _checkNow() async {
    final turn = ++_turn;
    var status = await _check();
    if (turn != _turn || isClosed) return;
    if (status is UpdateRecommended) {
      if (_offered && state.status is! UpdateRecommended) {
        status = const AppOpen();
      }
      _offered = true;
    }
    emit(AppGateState(status: status, retrying: state.retrying));
  }
}

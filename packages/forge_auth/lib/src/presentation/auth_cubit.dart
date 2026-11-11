import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';

import '../domain/auth_usecases.dart';
import '../domain/auth_user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Session not resolved yet; show a splash, do not redirect.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class Authenticated extends AuthState {
  const Authenticated(this.user);
  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// App-wide session state. Registered as a singleton; routers listen to it.
///
/// With [_signInAnonymously] (guest start), a signed-out session is replaced by
/// a new guest instead of emitting [Unauthenticated]; that state then only
/// means the guest sign-in failed.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required WatchAuthUser watchAuthUser,
    required this._signOut,
    required this._deleteAccount,
    this._signInAnonymously,
  }) : super(const AuthUnknown()) {
    _subscription = watchAuthUser().listen(_onUser);
  }

  final SignOut _signOut;
  final DeleteAccount _deleteAccount;
  final SignInAnonymously? _signInAnonymously;
  late final StreamSubscription<AuthUser?> _subscription;

  /// Tries the guest sign-in again after it failed ([Unauthenticated]).
  /// Does nothing without guest start.
  Future<void> retryGuestSignIn() async {
    if (_signInAnonymously == null || state is! Unauthenticated) return;
    emit(const AuthUnknown());
    await _onUser(null);
  }

  Future<void> _onUser(AuthUser? user) async {
    if (user != null) return emit(Authenticated(user));
    final signInAnonymously = _signInAnonymously;
    // The guest user arrives through the stream; only a failure needs a state.
    if (signInAnonymously != null && (await signInAnonymously()).isOk) return;
    if (!isClosed) emit(const Unauthenticated());
  }

  AuthUser? get user => switch (state) {
    Authenticated(:final user) => user,
    _ => null,
  };

  Future<Result<void>> signOut() => _signOut();
  Future<Result<void>> deleteAccount() => _deleteAccount();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}

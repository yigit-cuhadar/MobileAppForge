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
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required WatchAuthUser watchAuthUser,
    required this._signOut,
    required this._deleteAccount,
  }) : super(const AuthUnknown()) {
    _subscription = watchAuthUser().listen(
      (user) =>
          emit(user == null ? const Unauthenticated() : Authenticated(user)),
    );
  }

  final SignOut _signOut;
  final DeleteAccount _deleteAccount;
  late final StreamSubscription<AuthUser?> _subscription;

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

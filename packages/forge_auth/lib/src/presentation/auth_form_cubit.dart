import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_usecases.dart';
import '../domain/auth_user.dart';

enum AuthFormStatus {
  idle,
  loading,
  failure,
  resetSent,

  /// The next step discards the guest session; ask the user, then call
  /// `confirmReplaceGuest` or `cancelReplaceGuest`.
  confirmReplaceGuest,
}

class AuthFormState extends Equatable {
  const AuthFormState({this.status = AuthFormStatus.idle, this.failure});

  final AuthFormStatus status;
  final Failure? failure;

  bool get isLoading => status == AuthFormStatus.loading;

  @override
  List<Object?> get props => [status, failure];
}

/// Drives the sign-in / sign-up form. Success is not a state here: the
/// session change arrives through `AuthCubit`.
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit({
    required this._signInWithEmail,
    required this._signUpWithEmail,
    required this._signInWithProvider,
    required this._sendPasswordReset,
    required this._getCurrentUser,
  }) : super(const AuthFormState());

  final SignInWithEmail _signInWithEmail;
  final SignUpWithEmail _signUpWithEmail;
  final SignInWithProvider _signInWithProvider;
  final SendPasswordReset _sendPasswordReset;
  final GetCurrentUser _getCurrentUser;

  /// The action waiting for the user to confirm discarding the guest.
  Future<void> Function()? _pending;

  /// Signing in replaces a guest session, so a guest is asked first.
  Future<void> signIn(String email, String password) async {
    Future<void> action() =>
        _run(() => _signInWithEmail((email: email, password: password)));
    if (_getCurrentUser()?.isAnonymous ?? false) {
      return _askReplaceGuest(action);
    }
    return action();
  }

  Future<void> signUp(String email, String password) =>
      _run(() => _signUpWithEmail((email: email, password: password)));

  /// A guest is linked to the provider. If that account already exists, the
  /// user is asked before signing in to it instead.
  Future<void> signInWith(SocialProvider provider) => _run(
    () => _signInWithProvider((provider: provider, replaceGuest: false)),
    onAccountExists: () => _run(
      () => _signInWithProvider((provider: provider, replaceGuest: true)),
    ),
  );

  Future<void> resetPassword(String email) =>
      _run(() => _sendPasswordReset(email), onOk: AuthFormStatus.resetSent);

  Future<void> confirmReplaceGuest() async {
    final action = _pending;
    _pending = null;
    await action?.call();
  }

  void cancelReplaceGuest() {
    _pending = null;
    emit(const AuthFormState());
  }

  void _askReplaceGuest(Future<void> Function() action) {
    _pending = action;
    emit(const AuthFormState(status: AuthFormStatus.confirmReplaceGuest));
  }

  Future<void> _run(
    Future<Result<Object?>> Function() action, {
    AuthFormStatus onOk = AuthFormStatus.idle,
    Future<void> Function()? onAccountExists,
  }) async {
    if (state.isLoading) return;
    emit(const AuthFormState(status: AuthFormStatus.loading));
    final result = await action();
    if (isClosed) return;
    final failure = result.failureOrNull;
    if (onAccountExists != null &&
        failure is AuthFailure &&
        failure.code == accountExistsCode) {
      return _askReplaceGuest(onAccountExists);
    }
    emit(
      failure == null
          ? AuthFormState(status: onOk)
          : AuthFormState(status: AuthFormStatus.failure, failure: failure),
    );
  }
}

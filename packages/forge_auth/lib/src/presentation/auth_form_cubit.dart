import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';

import '../domain/auth_usecases.dart';
import '../domain/auth_user.dart';

enum AuthFormStatus { idle, loading, failure, resetSent }

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
  }) : super(const AuthFormState());

  final SignInWithEmail _signInWithEmail;
  final SignUpWithEmail _signUpWithEmail;
  final SignInWithProvider _signInWithProvider;
  final SendPasswordReset _sendPasswordReset;

  Future<void> signIn(String email, String password) =>
      _run(() => _signInWithEmail((email: email, password: password)));

  Future<void> signUp(String email, String password) =>
      _run(() => _signUpWithEmail((email: email, password: password)));

  Future<void> signInWith(SocialProvider provider) =>
      _run(() => _signInWithProvider(provider));

  Future<void> resetPassword(String email) =>
      _run(() => _sendPasswordReset(email), onOk: AuthFormStatus.resetSent);

  Future<void> _run(
    Future<Result<Object?>> Function() action, {
    AuthFormStatus onOk = AuthFormStatus.idle,
  }) async {
    if (state.isLoading) return;
    emit(const AuthFormState(status: AuthFormStatus.loading));
    final result = await action();
    if (isClosed) return;
    emit(
      result.fold(
        (_) => AuthFormState(status: onOk),
        (failure) =>
            AuthFormState(status: AuthFormStatus.failure, failure: failure),
      ),
    );
  }
}

import 'package:forge_core/forge_core.dart';

import 'auth_repository.dart';
import 'auth_user.dart';

typedef EmailCredentials = ({String email, String password});
typedef ProviderSignIn = ({SocialProvider provider, bool replaceGuest});

class WatchAuthUser {
  const WatchAuthUser(this._repository);
  final AuthRepository _repository;

  Stream<AuthUser?> call() => _repository.watchUser();
}

class GetCurrentUser {
  const GetCurrentUser(this._repository);
  final AuthRepository _repository;

  AuthUser? call() => _repository.currentUser;
}

class SignInAnonymously implements UseCase<AuthUser, NoParams> {
  const SignInAnonymously(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call([NoParams params = const NoParams()]) =>
      _repository.signInAnonymously();
}

class SignInWithEmail implements UseCase<AuthUser, EmailCredentials> {
  const SignInWithEmail(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(EmailCredentials params) =>
      _repository.signInWithEmail(params.email.trim(), params.password);
}

class SignUpWithEmail implements UseCase<AuthUser, EmailCredentials> {
  const SignUpWithEmail(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(EmailCredentials params) =>
      _repository.signUpWithEmail(params.email.trim(), params.password);
}

class SignInWithProvider implements UseCase<AuthUser, ProviderSignIn> {
  const SignInWithProvider(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(ProviderSignIn params) => _repository
      .signInWithProvider(params.provider, replaceGuest: params.replaceGuest);
}

class SendPasswordReset implements UseCase<void, String> {
  const SendPasswordReset(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(String params) =>
      _repository.sendPasswordReset(params.trim());
}

class SignOut implements UseCase<void, NoParams> {
  const SignOut(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repository.signOut();
}

class DeleteAccount implements UseCase<void, NoParams> {
  const DeleteAccount(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repository.deleteAccount();
}

class Reauthenticate implements UseCase<void, String> {
  const Reauthenticate(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(String params) =>
      _repository.reauthenticate(params);
}

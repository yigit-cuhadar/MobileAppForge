import 'package:forge_core/forge_core.dart';

import 'auth_repository.dart';
import 'auth_user.dart';

typedef EmailCredentials = ({String email, String password});

class WatchAuthUser {
  const WatchAuthUser(this._repository);
  final AuthRepository _repository;

  Stream<AuthUser?> call() => _repository.watchUser();
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

class SignInWithProvider implements UseCase<AuthUser, SocialProvider> {
  const SignInWithProvider(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(SocialProvider params) =>
      _repository.signInWithProvider(params);
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

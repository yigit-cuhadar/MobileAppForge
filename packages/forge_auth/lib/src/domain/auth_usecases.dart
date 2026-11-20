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

/// Creates the account (or links the guest) and mails the verification
/// link at once.
class SignUpWithEmail implements UseCase<AuthUser, EmailCredentials> {
  const SignUpWithEmail(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call(EmailCredentials params) async {
    final result = await _repository.signUpWithEmail(
      params.email.trim(),
      params.password,
    );
    // A failed send leaves the account as it is; the user resends it from
    // the verification page.
    if (result.isOk) await _repository.sendEmailVerification();
    return result;
  }
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

class SendEmailVerification implements UseCase<void, NoParams> {
  const SendEmailVerification(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repository.sendEmailVerification();
}

class ChangeEmail implements UseCase<void, String> {
  const ChangeEmail(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(String params) =>
      _repository.changeEmail(params.trim());
}

class GetVerificationSentAt {
  const GetVerificationSentAt(this._repository);
  final AuthRepository _repository;

  DateTime? call() => _repository.verificationSentAt;
}

class ReloadUser implements UseCase<AuthUser, NoParams> {
  const ReloadUser(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<AuthUser>> call([NoParams params = const NoParams()]) =>
      _repository.reloadUser();
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

class ReauthenticateWithProvider implements UseCase<void, SocialProvider> {
  const ReauthenticateWithProvider(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(SocialProvider params) =>
      _repository.reauthenticateWithProvider(params);
}

class ReauthenticateWithAppleCode implements UseCase<String, NoParams> {
  const ReauthenticateWithAppleCode(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<String>> call([NoParams params = const NoParams()]) =>
      _repository.reauthenticateWithAppleCode();
}

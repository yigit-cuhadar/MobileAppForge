import 'package:firebase_auth/firebase_auth.dart';
import 'package:forge_core/forge_core.dart';
import 'package:get_it/get_it.dart';

import 'data/firebase_auth_repository.dart';
import 'domain/auth_repository.dart';
import 'domain/auth_usecases.dart';
import 'presentation/auth_cubit.dart';
import 'presentation/auth_form_cubit.dart';

/// Registers the auth feature. Call after Firebase is initialized.
///
/// With [guestStart], the app always has a user: a signed-out session becomes
/// an anonymous guest, which signing up later upgrades in place.
class AuthModule implements FeatureModule {
  const AuthModule({this.guestStart = false});

  final bool guestStart;

  @override
  void register(GetIt sl) {
    sl
      ..registerLazySingleton<AuthRepository>(
        () => FirebaseAuthRepository(FirebaseAuth.instance),
      )
      ..registerFactory(() => WatchAuthUser(sl()))
      ..registerFactory(() => SignInAnonymously(sl()))
      ..registerFactory(() => SignInWithEmail(sl()))
      ..registerFactory(() => SignUpWithEmail(sl()))
      ..registerFactory(() => SignInWithProvider(sl()))
      ..registerFactory(() => SendPasswordReset(sl()))
      ..registerFactory(() => SignOut(sl()))
      ..registerFactory(() => DeleteAccount(sl()))
      ..registerLazySingleton(
        () => AuthCubit(
          watchAuthUser: sl(),
          signOut: sl(),
          deleteAccount: sl(),
          signInAnonymously: guestStart ? sl() : null,
        ),
      )
      ..registerFactory(
        () => AuthFormCubit(
          signInWithEmail: sl(),
          signUpWithEmail: sl(),
          signInWithProvider: sl(),
          sendPasswordReset: sl(),
        ),
      );
  }
}

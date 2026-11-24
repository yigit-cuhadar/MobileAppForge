import 'package:forge_core/forge_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google's own sign-in on the device: Credential Manager's account sheet on
/// Android, Google's sign-in sheet on iOS.
class NativeGoogleSignIn {
  /// [iosClientId] is the iOS OAuth client of the Firebase project. Android
  /// ignores it: the plugin reads the web client id from the
  /// `default_web_client_id` string that the google-services Gradle plugin
  /// generates from `google-services.json`.
  NativeGoogleSignIn({this._iosClientId});

  final String? _iosClientId;
  Future<void>? _initialized;

  /// The plugin must be initialized exactly once before any other call.
  Future<void> _initialize() => _initialized ??= GoogleSignIn.instance
      .initialize(clientId: _iosClientId)
      .onError<Object>((error, stack) {
        _initialized = null;
        Error.throwWithStackTrace(error, stack);
      });

  /// Shows the account sheet and returns the chosen account's ID token.
  /// Throws [GoogleSignInException] with
  /// [GoogleSignInExceptionCode.canceled] when the user closes it.
  Future<String> idToken() async {
    await _initialize();
    final account = await GoogleSignIn.instance.authenticate();
    return account.authentication.idToken ??
        (throw const AuthFailure('no Google ID token'));
  }

  /// Forgets the chosen account, so the next sign-in asks again.
  Future<void> signOut() async {
    await _initialize();
    await GoogleSignIn.instance.signOut();
  }
}

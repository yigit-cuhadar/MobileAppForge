import 'package:forge_core/forge_core.dart';

/// User-facing text of the auth screens. Apps pass their own instance to
/// localize or reword.
class AuthStrings {
  const AuthStrings({
    this.signIn = 'Sign in',
    this.signUp = 'Create account',
    this.signInWithEmail = 'Sign in with email',
    this.email = 'Email',
    this.password = 'Password',
    this.forgotPassword = 'Forgot password?',
    this.switchToSignUp = "Don't have an account? Create one",
    this.switchToSignIn = 'Already have an account? Sign in',
    this.continueWithGoogle = 'Continue with Google',
    this.continueWithApple = 'Continue with Apple',
    this.useEmail = 'Use email instead',
    this.otherOptions = 'Other options',
    this.continueAsGuest = 'Continue as guest',
    this.signingIn = 'Signing in…',
    this.terms = 'By continuing you agree to the {terms} and {privacy}.',
    this.termsLink = 'Terms',
    this.privacyLink = 'Privacy Policy',
    this.invalidEmail = 'Enter a valid email',
    this.shortPassword = 'Use at least 6 characters',
    this.resetSent = 'Password reset email sent',
    this.signInFailed = "Sign-in didn't finish. Try again.",
    this.retry = 'Retry',
    this.linkFailed = "Couldn't sign in. Try again.",
    this.notNow = 'Not now',
    this.replaceGuestTitle = 'Use existing account?',
    this.replaceGuestBody =
        "This device's guest data will be replaced by the account's.",
    this.replaceGuestConfirm = 'Use existing account',
    this.cancel = 'Cancel',
    this.errorFor = defaultErrorFor,
  });

  final String signIn;
  final String signUp;

  /// The email form's title in sign-in mode; in create mode it is [signUp].
  final String signInWithEmail;
  final String email;
  final String password;
  final String forgotPassword;
  final String switchToSignUp;
  final String switchToSignIn;
  final String continueWithGoogle;
  final String continueWithApple;
  final String useEmail;

  /// The email form's back link to the sign-in options.
  final String otherOptions;
  final String continueAsGuest;

  /// The running option's label.
  final String signingIn;

  /// The terms line, with `{terms}` and `{privacy}` where [termsLink] and
  /// [privacyLink] go.
  final String terms;
  final String termsLink;
  final String privacyLink;
  final String invalidEmail;
  final String shortPassword;
  final String resetSent;

  /// The sign-in page's snackbar for a failure no field shows; it has a
  /// [retry] action.
  final String signInFailed;
  final String retry;

  /// The link-account sheet's snackbar for a failed sign-in.
  final String linkFailed;
  final String notNow;
  final String replaceGuestTitle;
  final String replaceGuestBody;
  final String replaceGuestConfirm;
  final String cancel;

  /// The message under the email or password field for a failure that
  /// belongs to one (a wrong password, an email in use).
  final String Function(Failure failure) errorFor;

  static String defaultErrorFor(Failure failure) => switch (failure) {
    AuthFailure(:final code) => switch (code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email or password is incorrect',
      'email-already-in-use' => 'This email is already registered',
      'weak-password' => 'Password is too weak',
      'invalid-email' => 'Email address is not valid',
      _ => 'Could not sign in. Try again',
    },
    _ => 'Something went wrong. Try again',
  };
}

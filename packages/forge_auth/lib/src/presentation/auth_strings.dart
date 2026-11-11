import 'package:forge_core/forge_core.dart';

/// User-facing text of the auth screens. Apps pass their own instance to
/// localize or reword.
class AuthStrings {
  const AuthStrings({
    this.signIn = 'Sign in',
    this.signUp = 'Create account',
    this.email = 'Email',
    this.password = 'Password',
    this.forgotPassword = 'Forgot password?',
    this.switchToSignUp = "Don't have an account? Create one",
    this.switchToSignIn = 'Already have an account? Sign in',
    this.continueWithGoogle = 'Continue with Google',
    this.continueWithApple = 'Continue with Apple',
    this.invalidEmail = 'Enter a valid email',
    this.shortPassword = 'Use at least 6 characters',
    this.resetSent = 'Password reset email sent',
    this.replaceGuestTitle = 'Use existing account?',
    this.replaceGuestBody =
        'What you did as a guest on this device will be lost.',
    this.replaceGuestConfirm = 'Continue',
    this.cancel = 'Cancel',
    this.errorFor = defaultErrorFor,
  });

  final String signIn;
  final String signUp;
  final String email;
  final String password;
  final String forgotPassword;
  final String switchToSignUp;
  final String switchToSignIn;
  final String continueWithGoogle;
  final String continueWithApple;
  final String invalidEmail;
  final String shortPassword;
  final String resetSent;
  final String replaceGuestTitle;
  final String replaceGuestBody;
  final String replaceGuestConfirm;
  final String cancel;
  final String Function(Failure failure) errorFor;

  static String defaultErrorFor(Failure failure) => switch (failure) {
    NetworkFailure() => 'No internet connection',
    AuthFailure(:final code) => switch (code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email or password is incorrect',
      'email-already-in-use' => 'This email is already registered',
      'weak-password' => 'Password is too weak',
      'invalid-email' => 'Email address is not valid',
      'too-many-requests' => 'Too many attempts. Try again later',
      'requires-recent-login' => 'Please sign in again to continue',
      _ => 'Could not sign in. Try again',
    },
    _ => 'Something went wrong. Try again',
  };
}

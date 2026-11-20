import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_ui/forge_ui.dart';

import '../domain/auth_user.dart';
import 'auth_cubit.dart';
import 'auth_failure_field.dart';
import 'auth_form_cubit.dart';
import 'auth_strings.dart';
import 'provider_mark.dart';

/// The sign-in screen, on forge_ui's [SignInPage]: the app's [mark],
/// [name] and [tagline], the [providers], "Use email instead" opening the
/// email form, a guest link while nobody is signed in, and the terms line
/// with links to [onTerms] and [onPrivacy]. Needs `AuthCubit` above it.
/// Navigation after success belongs to the app: either its router reacts
/// to `AuthCubit`, or it passes [onSignedIn].
///
/// For a guest, creating an account or a provider sign-in upgrades the
/// guest in place; signing in to an existing account discards the guest
/// after the user confirms.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.mark,
    required this.name,
    required this.tagline,
    required this.onTerms,
    required this.onPrivacy,
    this.strings = const AuthStrings(),
    this.providers = const [],
    this.onSignedIn,
    this.initialSignUp = false,
  });

  final Widget mark;
  final String name;
  final String tagline;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final AuthStrings strings;

  /// Social sign-in buttons to show; each must be enabled in Firebase.
  final List<SocialProvider> providers;

  /// Called once when a session starts while the page is open: any
  /// non-guest one, or a guest one when nobody was signed in.
  final VoidCallback? onSignedIn;

  /// Opens straight on the email form's create-account mode.
  final bool initialSignUp;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthFormCubit>(),
      child: _AuthView(page: this),
    );
  }
}

class _AuthView extends StatefulWidget {
  const _AuthView({required this.page});

  final AuthPage page;

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  /// The email form's mode, or null while the options show.
  late bool? _signUp = widget.page.initialSignUp ? true : null;

  /// The option started last; it shows as running while the form loads.
  SignInOption? _option;
  String? _emailError;
  String? _passwordError;
  bool _signedIn = false;

  AuthStrings get _s => widget.page.strings;
  AuthFormCubit get _cubit => context.read<AuthFormCubit>();

  void _showEmail(bool? signUp) => setState(() {
    _signUp = signUp;
    _emailError = null;
    _passwordError = null;
  });

  String? _checkEmail(String email) =>
      emailShape.hasMatch(email) ? null : _s.invalidEmail;

  void _submit(String email, String password) {
    final emailError = _checkEmail(email);
    final passwordError = password.length >= 6 ? null : _s.shortPassword;
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError != null || passwordError != null) return;
    _option = SignInOption.email;
    _signUp! ? _cubit.signUp(email, password) : _cubit.signIn(email, password);
  }

  void _resetPassword(String email) {
    final error = _checkEmail(email);
    setState(() {
      _emailError = error;
      _passwordError = null;
    });
    if (error != null) return;
    _option = SignInOption.email;
    _cubit.resetPassword(email);
  }

  void _start(SignInOption option, Future<void> Function() action) {
    _option = option;
    action();
  }

  void _onFailure(Failure failure) {
    final field = failureField(failure);
    if (field == null) {
      return showForgeSnackbar(
        context,
        message: _s.signInFailed,
        actionLabel: _s.retry,
        onAction: _cubit.retry,
        error: true,
      );
    }
    final message = _s.errorFor(failure);
    setState(() {
      _emailError = field == AuthFailureField.email ? message : null;
      _passwordError = field == AuthFailureField.password ? message : null;
    });
  }

  Future<void> _confirmReplaceGuest() async {
    final cubit = _cubit;
    final confirmed = await confirmReplaceGuestData(
      context,
      title: _s.replaceGuestTitle,
      message: _s.replaceGuestBody,
      confirmLabel: _s.replaceGuestConfirm,
      cancelLabel: _s.cancel,
    );
    confirmed ? await cubit.confirmReplaceGuest() : cubit.cancelReplaceGuest();
  }

  SignInProvider? _provider(SocialProvider provider, SignInOption? running) {
    if (!widget.page.providers.contains(provider)) return null;
    final option = switch (provider) {
      SocialProvider.google => SignInOption.google,
      SocialProvider.apple => SignInOption.apple,
    };
    return SignInProvider(
      mark: ProviderMark(provider, enabled: running == null),
      label: switch (provider) {
        SocialProvider.google => _s.continueWithGoogle,
        SocialProvider.apple => _s.continueWithApple,
      },
      onPressed: () => _start(option, () => _cubit.signInWith(provider)),
    );
  }

  SignInEmailForm _emailForm(bool signUp) => SignInEmailForm(
    backLabel: _s.otherOptions,
    onBack: () => _showEmail(null),
    title: signUp ? _s.signUp : _s.signInWithEmail,
    emailLabel: _s.email,
    passwordLabel: _s.password,
    submitLabel: signUp ? _s.signUp : _s.signIn,
    onSubmit: _submit,
    forgotPasswordLabel: signUp ? null : _s.forgotPassword,
    onForgotPassword: signUp ? null : _resetPassword,
    switchLabel: signUp ? _s.switchToSignIn : _s.switchToSignUp,
    onSwitch: () => _showEmail(!signUp),
    emailError: _emailError,
    passwordError: _passwordError,
  );

  @override
  Widget build(BuildContext context) {
    final page = widget.page;
    final s = _s;
    final nobody = context.select<AuthCubit, bool>(
      (cubit) => cubit.state is Unauthenticated,
    );
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, state) =>
          page.onSignedIn != null &&
          state is Authenticated &&
          (!state.user.isAnonymous || previous is! Authenticated),
      listener: (_, _) {
        if (_signedIn) return;
        _signedIn = true;
        page.onSignedIn!();
      },
      child: BlocConsumer<AuthFormCubit, AuthFormState>(
        listener: (context, state) => switch (state.status) {
          AuthFormStatus.failure => _onFailure(state.failure!),
          AuthFormStatus.confirmReplaceGuest => _confirmReplaceGuest(),
          AuthFormStatus.resetSent => showForgeSnackbar(
            context,
            message: s.resetSent,
          ),
          _ => null,
        },
        builder: (context, state) {
          final running = state.isLoading ? _option : null;
          final signUp = _signUp;
          return SignInPage(
            mark: page.mark,
            name: page.name,
            tagline: page.tagline,
            apple: _provider(SocialProvider.apple, running),
            google: _provider(SocialProvider.google, running),
            useEmailLabel: s.useEmail,
            onUseEmail: () => _showEmail(false),
            guestLabel: nobody ? s.continueAsGuest : null,
            onGuest: nobody
                ? () => _start(SignInOption.guest, _cubit.continueAsGuest)
                : null,
            terms: SignInTerms(
              text: s.terms,
              termsLabel: s.termsLink,
              onTerms: page.onTerms,
              privacyLabel: s.privacyLink,
              onPrivacy: page.onPrivacy,
            ),
            signingInLabel: s.signingIn,
            email: signUp == null ? null : _emailForm(signUp),
            running: running,
          );
        },
      ),
    );
  }
}

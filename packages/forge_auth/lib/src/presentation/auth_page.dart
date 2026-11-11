import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_ui/forge_ui.dart';

import '../domain/auth_user.dart';
import 'auth_form_cubit.dart';
import 'auth_strings.dart';

/// Combined sign-in / sign-up screen. Navigation after success belongs to the
/// app's router, which reacts to `AuthCubit`.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    this.strings = const AuthStrings(),
    this.providers = const [],
    this.header,
  });

  final AuthStrings strings;

  /// Social sign-in buttons to show; each must be enabled in Firebase.
  final List<SocialProvider> providers;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthFormCubit>(),
      child: _AuthView(strings: strings, providers: providers, header: header),
    );
  }
}

class _AuthView extends StatefulWidget {
  const _AuthView({
    required this.strings,
    required this.providers,
    this.header,
  });

  final AuthStrings strings;
  final List<SocialProvider> providers;
  final Widget? header;

  @override
  State<_AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<_AuthView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;

  static final _emailPattern = RegExp(r'^\S+@\S+\.\S+$');

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) =>
      _emailPattern.hasMatch(value?.trim() ?? '')
      ? null
      : widget.strings.invalidEmail;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AuthFormCubit>();
    _signUp
        ? cubit.signUp(_email.text, _password.text)
        : cubit.signIn(_email.text, _password.text);
  }

  void _resetPassword() {
    final error = _validateEmail(_email.text);
    if (error != null) return _show(error);
    context.read<AuthFormCubit>().resetPassword(_email.text);
  }

  void _show(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return BlocConsumer<AuthFormCubit, AuthFormState>(
      listener: (context, state) => switch (state.status) {
        AuthFormStatus.failure => _show(s.errorFor(state.failure!)),
        AuthFormStatus.resetSent => _show(s.resetSent),
        _ => null,
      },
      builder: (context, state) {
        final cubit = context.read<AuthFormCubit>();
        return Scaffold(
          appBar: AppBar(title: Text(_signUp ? s.signUp : s.signIn)),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Gap.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.header != null) ...[
                            widget.header!,
                            const SizedBox(height: Gap.lg),
                          ],
                          ForgeTextField(
                            label: s.email,
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: Gap.md),
                          ForgeTextField(
                            label: s.password,
                            controller: _password,
                            obscure: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: [
                              _signUp
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            validator: (v) =>
                                (v?.length ?? 0) >= 6 ? null : s.shortPassword,
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: Gap.lg),
                          ForgeButton(
                            label: _signUp ? s.signUp : s.signIn,
                            loading: state.isLoading,
                            onPressed: _submit,
                          ),
                          if (!_signUp)
                            TextButton(
                              onPressed: state.isLoading
                                  ? null
                                  : _resetPassword,
                              child: Text(s.forgotPassword),
                            ),
                          TextButton(
                            onPressed: state.isLoading
                                ? null
                                : () => setState(() => _signUp = !_signUp),
                            child: Text(
                              _signUp ? s.switchToSignIn : s.switchToSignUp,
                            ),
                          ),
                          for (final provider in widget.providers) ...[
                            const SizedBox(height: Gap.sm),
                            OutlinedButton(
                              onPressed: state.isLoading
                                  ? null
                                  : () => cubit.signInWith(provider),
                              child: Text(switch (provider) {
                                SocialProvider.google => s.continueWithGoogle,
                                SocialProvider.apple => s.continueWithApple,
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

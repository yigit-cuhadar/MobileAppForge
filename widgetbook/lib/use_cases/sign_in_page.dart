import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// A placeholder provider mark; forge_auth passes the real ones.
class _ProviderMark extends StatelessWidget {
  const _ProviderMark({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.surface : null,
        border: filled
            ? null
            : Border.all(color: colors.lineStrong, width: 1.5),
      ),
    );
  }
}

SignInPage _page(BuildContext context, {SignInOption? running}) => SignInPage(
  mark: const Text('A'),
  name: context.knobs.string(label: 'Name', initialValue: '[APP NAME]'),
  tagline: context.knobs.string(label: 'Tagline', initialValue: '[TAGLINE]'),
  apple: SignInProvider(
    mark: const _ProviderMark(filled: true),
    label: 'Continue with Apple',
    onPressed: () {},
  ),
  google: SignInProvider(
    mark: const _ProviderMark(filled: false),
    label: 'Continue with Google',
    onPressed: () {},
  ),
  useEmailLabel: 'Use email instead',
  onUseEmail: () {},
  guestLabel: 'Continue as guest',
  onGuest: () {},
  terms: 'By continuing you agree to the Terms and Privacy Policy.',
  signingInLabel: 'Signing in…',
  running: running,
);

@widgetbook.UseCase(name: 'Options', type: SignInPage)
Widget signInOptions(BuildContext context) => _page(context);

@widgetbook.UseCase(name: 'Signing in', type: SignInPage)
Widget signingIn(BuildContext context) => _page(
  context,
  running: context.knobs.object.segmented<SignInOption>(
    label: 'Running',
    options: SignInOption.values,
    labelBuilder: (option) => option.name,
  ),
);

/// A failed sign-in: the error snackbar with Retry over the page.
@widgetbook.UseCase(name: 'Error', type: SignInPage)
Widget signInError(BuildContext context) => Stack(
  children: [
    _page(context),
    Positioned(
      left: Gap.md,
      right: Gap.md,
      bottom: Gap.md,
      child: SafeArea(
        child: ForgeSnackbar(
          message: "Sign-in didn't finish.",
          actionLabel: 'Retry',
          onAction: () {},
          error: true,
        ),
      ),
    ),
  ],
);

SignInEmailPage _email({String? passwordError}) => SignInEmailPage(
  backLabel: 'Other options',
  onBack: () {},
  title: 'Sign in with email',
  emailLabel: 'Email',
  passwordLabel: 'Password',
  signInLabel: 'Sign in',
  onSignIn: (_, _) {},
  passwordError: passwordError,
);

@widgetbook.UseCase(name: 'Email form', type: SignInEmailPage)
Widget emailForm(BuildContext context) => _email();

@widgetbook.UseCase(name: 'Email form · field error', type: SignInEmailPage)
Widget emailFormError(BuildContext context) =>
    _email(passwordError: 'Wrong password. Try again.');

/// The dialog `confirmReplaceGuestData` shows, over the scrim.
@widgetbook.UseCase(name: 'Replace guest data', type: SignInPage)
Widget replaceGuestData(BuildContext context) => ColoredBox(
  color: Theme.of(context).colorScheme.scrim,
  child: ForgeDialog(
    title: 'Use existing account?',
    message: "This device's guest data will be replaced by the account's.",
    action: ForgeButton(
      label: 'Use existing account',
      onPressed: () {},
      variant: ForgeButtonVariant.danger,
    ),
    cancel: ForgeButton(
      label: 'Cancel',
      onPressed: () {},
      variant: ForgeButtonVariant.secondary,
    ),
  ),
);

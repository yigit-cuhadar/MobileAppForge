import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_ui/forge_ui.dart';

import '../domain/auth_user.dart';
import 'auth_form_cubit.dart';
import 'auth_strings.dart';
import 'provider_mark.dart';

/// Asks a guest to keep their data in an account: forge_ui's
/// [LinkAccountSheet] with [title], [message] and the [providers]. A
/// provider sign-in links the guest in place (same uid) and closes the
/// sheet; when that account already exists the user is asked before
/// signing in to it instead. "Use email instead" closes the sheet and
/// calls [onUseEmail], where the app opens the email form in create mode.
Future<void> showLinkAccountSheet(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onUseEmail,
  AuthStrings strings = const AuthStrings(),
  List<SocialProvider> providers = const [],
}) => showForgeBottomSheet<void>(
  context: context,
  builder: (_) => BlocProvider(
    create: (_) => sl<AuthFormCubit>(),
    child: _LinkAccountView(
      title: title,
      message: message,
      onUseEmail: onUseEmail,
      strings: strings,
      providers: providers,
    ),
  ),
);

class _LinkAccountView extends StatefulWidget {
  const _LinkAccountView({
    required this.title,
    required this.message,
    required this.onUseEmail,
    required this.strings,
    required this.providers,
  });

  final String title;
  final String message;
  final VoidCallback onUseEmail;
  final AuthStrings strings;
  final List<SocialProvider> providers;

  @override
  State<_LinkAccountView> createState() => _LinkAccountViewState();
}

class _LinkAccountViewState extends State<_LinkAccountView> {
  SignInOption? _option;

  Future<void> _confirmReplaceGuest() async {
    final s = widget.strings;
    final cubit = context.read<AuthFormCubit>();
    final confirmed = await confirmReplaceGuestData(
      context,
      title: s.replaceGuestTitle,
      message: s.replaceGuestBody,
      confirmLabel: s.replaceGuestConfirm,
      cancelLabel: s.cancel,
    );
    confirmed ? await cubit.confirmReplaceGuest() : cubit.cancelReplaceGuest();
  }

  SignInProvider? _provider(SocialProvider provider, SignInOption? running) {
    if (!widget.providers.contains(provider)) return null;
    final s = widget.strings;
    return SignInProvider(
      mark: ProviderMark(provider, enabled: running == null),
      label: switch (provider) {
        SocialProvider.google => s.continueWithGoogle,
        SocialProvider.apple => s.continueWithApple,
      },
      onPressed: () {
        _option = switch (provider) {
          SocialProvider.google => SignInOption.google,
          SocialProvider.apple => SignInOption.apple,
        };
        context.read<AuthFormCubit>().signInWith(provider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return BlocConsumer<AuthFormCubit, AuthFormState>(
      listener: (context, state) {
        switch (state.status) {
          case AuthFormStatus.failure:
            showForgeSnackbar(context, message: s.linkFailed, error: true);
          case AuthFormStatus.confirmReplaceGuest:
            _confirmReplaceGuest();
          // Back to idle after loading: the sign-in went through.
          case AuthFormStatus.idle:
            Navigator.pop(context);
          case AuthFormStatus.loading ||
              AuthFormStatus.cancelled ||
              AuthFormStatus.resetSent:
        }
      },
      listenWhen: (previous, state) =>
          state.status != AuthFormStatus.idle || previous.isLoading,
      builder: (context, state) {
        final running = state.isLoading ? _option : null;
        return LinkAccountSheet(
          title: widget.title,
          message: widget.message,
          apple: _provider(SocialProvider.apple, running),
          google: _provider(SocialProvider.google, running),
          useEmailLabel: s.useEmail,
          onUseEmail: () {
            Navigator.pop(context);
            widget.onUseEmail();
          },
          notNowLabel: s.notNow,
          onNotNow: () => Navigator.pop(context),
          signingInLabel: s.signingIn,
          running: running,
        );
      },
    );
  }
}

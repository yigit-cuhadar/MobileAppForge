import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_ui/forge_ui.dart';

import 'auth_cubit.dart';
import 'auth_failure_field.dart';
import 'auth_strings.dart';
import 'email_verification_cubit.dart';

/// Stands in for the app while the signed-in user's address is not
/// verified (`AuthUser.needsEmailVerification`): the address it was sent
/// to, a waiting line, Resend with a cooldown, and "Use another email",
/// a sheet that sends the link to a new address of the same account or
/// signs out instead. While it shows, and whenever the app comes back, it checks for the
/// verification by itself. Needs `AuthCubit` above it; the app's router
/// leaves this page once the user is verified or signed out.
class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key, this.strings = const AuthStrings()});

  final AuthStrings strings;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EmailVerificationCubit>()..watch(),
      child: _VerificationView(strings: strings),
    );
  }
}

class _VerificationView extends StatefulWidget {
  const _VerificationView({required this.strings});

  final AuthStrings strings;

  @override
  State<_VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<_VerificationView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<EmailVerificationCubit>();
    _lifecycle = AppLifecycleListener(
      onShow: cubit.watch,
      onHide: cubit.stopWatching,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    final accountEmail = context.select<AuthCubit, String>(
      (cubit) => cubit.user?.email ?? '',
    );
    final cubit = context.read<EmailVerificationCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<EmailVerificationCubit, EmailVerificationState>(
          listenWhen: (previous, state) => previous.status != state.status,
          listener: (context, state) => switch (state.status) {
            EmailVerificationStatus.sent ||
            EmailVerificationStatus.emailChangeSent => showForgeSnackbar(
              context,
              message: s.emailSent,
            ),
            EmailVerificationStatus.failure => showForgeSnackbar(
              context,
              message: EmailVerificationCubit.isThrottled(state.failure)
                  ? s.tooManyEmails
                  : s.verificationFailed,
              error: true,
            ),
            _ => null,
          },
          builder: (context, state) {
            final email = state.pendingEmail ?? accountEmail;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Gap.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surfaceSunken,
                        ),
                        child: ForgeIcon(
                          ForgeIcons.mail,
                          size: 32,
                          color: colors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: Gap.md),
                    Text(
                      s.verifyEmailTitle,
                      textAlign: TextAlign.center,
                      style: text.titleLarge,
                    ),
                    const SizedBox(height: Gap.sm),
                    Text(
                      s.verifyEmailBody,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: Gap.lg),
                    SectionCard.plain(
                      title: s.sentTo,
                      child: Text(email, style: text.bodyLarge),
                    ),
                    const SizedBox(height: Gap.lg),
                    Progress.indeterminate(label: s.waitingForVerification),
                    const SizedBox(height: Gap.sm),
                    Text(
                      s.waitingForVerification,
                      textAlign: TextAlign.center,
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: Gap.lg),
                    ForgeButton(
                      label: state.resendIn > 0
                          ? s.resendIn.replaceAll(
                              '{seconds}',
                              '${state.resendIn}',
                            )
                          : s.resendEmail,
                      // A busy cubit ignores taps; only a waiting Resend is off.
                      onPressed: state.resendIn == 0 ? cubit.resend : null,
                      variant: ForgeButtonVariant.secondary,
                      loading: state.status == EmailVerificationStatus.sending,
                    ),
                    const SizedBox(height: Gap.sm),
                    ForgeButton(
                      label: s.useAnotherAccount,
                      onPressed: () => _changeEmail(context),
                      variant: ForgeButtonVariant.text,
                      loading:
                          state.status == EmailVerificationStatus.signingOut,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _changeEmail(BuildContext context) {
    final cubit = context.read<EmailVerificationCubit>();
    if (cubit.state.isBusy) return;
    showForgeBottomSheet<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _ChangeEmailSheet(strings: widget.strings),
      ),
    );
  }
}

/// The new address, Send link, and Sign out instead.
class _ChangeEmailSheet extends StatefulWidget {
  const _ChangeEmailSheet({required this.strings});

  final AuthStrings strings;

  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  final _email = TextEditingController();
  String? _error;

  AuthStrings get _s => widget.strings;

  void _send() {
    final email = _email.text.trim();
    if (!emailShape.hasMatch(email)) {
      return setState(() => _error = _s.invalidEmail);
    }
    setState(() => _error = null);
    context.read<EmailVerificationCubit>().changeEmail(email);
  }

  void _signOut() {
    final cubit = context.read<EmailVerificationCubit>();
    Navigator.pop(context);
    cubit.signOut();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return BlocConsumer<EmailVerificationCubit, EmailVerificationState>(
      listenWhen: (previous, state) => previous.status != state.status,
      listener: (context, state) => switch (state.status) {
        EmailVerificationStatus.emailChangeSent => Navigator.pop(context),
        EmailVerificationStatus.emailChangeFailed => setState(
          () => _error = s.errorFor(state.failure!),
        ),
        _ => null,
      },
      builder: (context, state) => ForgeBottomSheet(
        title: s.changeEmailTitle,
        action: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.sm,
          children: [
            ForgeButton(
              label: s.sendLink,
              onPressed: _send,
              size: ForgeButtonSize.large,
              loading: state.status == EmailVerificationStatus.changingEmail,
            ),
            ForgeButton(
              label: s.signOutInstead,
              onPressed: _signOut,
              variant: ForgeButtonVariant.text,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.md,
          children: [
            Text(
              s.changeEmailBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            ForgeTextField(
              label: s.newEmail,
              controller: _email,
              errorText: _error,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.send,
              autofillHints: const [AutofillHints.email],
              autofocus: true,
              onSubmitted: (_) => _send(),
            ),
          ],
        ),
      ),
    );
  }
}

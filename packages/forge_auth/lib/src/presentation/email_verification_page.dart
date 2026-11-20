import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_ui/forge_ui.dart';

import 'auth_cubit.dart';
import 'auth_strings.dart';
import 'email_verification_cubit.dart';

/// Stands in for the app while the signed-in user's address is not
/// verified (`AuthUser.needsEmailVerification`): the address it was sent
/// to, a waiting line, Resend with a cooldown, and a way out that signs
/// out. While it shows, and whenever the app comes back, it checks for the
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
    final email = context.select<AuthCubit, String>(
      (cubit) => cubit.user?.email ?? '',
    );
    final cubit = context.read<EmailVerificationCubit>();
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<EmailVerificationCubit, EmailVerificationState>(
          listenWhen: (previous, state) => previous.status != state.status,
          listener: (context, state) => switch (state.status) {
            EmailVerificationStatus.sent => showForgeSnackbar(
              context,
              message: s.emailSent,
            ),
            EmailVerificationStatus.failure => showForgeSnackbar(
              context,
              message: s.verificationFailed,
              error: true,
            ),
            _ => null,
          },
          builder: (context, state) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Gap.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ForgeIcon(ForgeIcons.mail, size: 32, color: colors.accent),
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
                    onPressed: cubit.useAnotherAccount,
                    variant: ForgeButtonVariant.text,
                    loading: state.status == EmailVerificationStatus.signingOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

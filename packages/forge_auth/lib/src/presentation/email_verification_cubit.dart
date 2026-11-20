import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';

import '../domain/auth_usecases.dart';

enum EmailVerificationStatus {
  idle,
  sending,
  sent,
  changingEmail,

  /// The link went to the new address; the change sheet closes.
  emailChangeSent,

  /// The new address was refused; the change sheet shows why.
  emailChangeFailed,
  signingOut,
  failure,
}

class EmailVerificationState extends Equatable {
  const EmailVerificationState({
    this.status = EmailVerificationStatus.idle,
    this.resendIn = 0,
    this.pendingEmail,
    this.failure,
  });

  final EmailVerificationStatus status;

  /// Seconds until the email can be sent again; 0 when it can.
  final int resendIn;

  /// The address a change of email sent its link to, which the page shows
  /// instead of the account's until it is confirmed.
  final String? pendingEmail;
  final Failure? failure;

  bool get isBusy => switch (status) {
    EmailVerificationStatus.sending ||
    EmailVerificationStatus.changingEmail ||
    EmailVerificationStatus.signingOut => true,
    _ => false,
  };

  @override
  List<Object?> get props => [status, resendIn, pendingEmail, failure];
}

/// Drives the verification page. While [watch]ing it reloads the user
/// every [checkEvery]; a verified address is not a state here: the
/// reloaded user arrives through `AuthCubit`, whose listeners move on.
/// Resend waits out [resendCooldown] from the last link this session
/// sent, including the one sent at sign-up.
class EmailVerificationCubit extends Cubit<EmailVerificationState> {
  EmailVerificationCubit({
    required this._reloadUser,
    required this._sendEmailVerification,
    required this._changeEmail,
    required GetVerificationSentAt getVerificationSentAt,
    required this._signOut,
  }) : super(const EmailVerificationState()) {
    if (getVerificationSentAt() case final sent?) {
      final waited = DateTime.now().difference(sent).inSeconds;
      if (waited < resendCooldown) _startCooldown(resendCooldown - waited);
    }
  }

  final ReloadUser _reloadUser;
  final SendEmailVerification _sendEmailVerification;
  final ChangeEmail _changeEmail;
  final SignOut _signOut;
  Timer? _cooldown;
  Timer? _watch;
  bool _reloading = false;

  /// How long Resend waits after an email went out, in seconds.
  static const resendCooldown = 60;

  static const checkEvery = Duration(seconds: 4);

  /// Firebase's answer when it already sent too many emails.
  static const _throttledCode = 'too-many-requests';

  /// Reloads the user now and then every [checkEvery], for while the page
  /// shows.
  void watch() {
    _watch?.cancel();
    _watch = Timer.periodic(checkEvery, (_) => _reload());
    _reload();
  }

  /// For while the page is hidden.
  void stopWatching() {
    _watch?.cancel();
    _watch = null;
  }

  /// Quiet: a failed reload is tried again on the next tick.
  Future<void> _reload() async {
    if (_reloading || state.status == EmailVerificationStatus.signingOut) {
      return;
    }
    _reloading = true;
    await _reloadUser();
    _reloading = false;
  }

  /// Sends the link again: to the new address while a change waits.
  Future<void> resend() async {
    if (state.isBusy || state.resendIn > 0) return;
    _emit(EmailVerificationStatus.sending);
    final pending = state.pendingEmail;
    final result = pending == null
        ? await _sendEmailVerification()
        : await _changeEmail(pending);
    if (isClosed) return;
    final failure = result.failureOrNull;
    if (failure == null || _throttled(failure)) {
      _startCooldown(resendCooldown);
    }
    failure == null
        ? _emit(EmailVerificationStatus.sent)
        : _emit(EmailVerificationStatus.failure, failure);
  }

  /// Sends the link to [email] instead; the account keeps its data.
  Future<void> changeEmail(String email) async {
    if (state.isBusy) return;
    _emit(EmailVerificationStatus.changingEmail);
    final result = await _changeEmail(email);
    if (isClosed) return;
    switch (result.failureOrNull) {
      case final failure?:
        if (_throttled(failure)) _startCooldown(resendCooldown);
        _emit(EmailVerificationStatus.emailChangeFailed, failure);
      case null:
        _startCooldown(resendCooldown);
        emit(
          EmailVerificationState(
            status: EmailVerificationStatus.emailChangeSent,
            resendIn: state.resendIn,
            pendingEmail: email.trim(),
          ),
        );
    }
  }

  /// Signs out; the session that follows (a new guest, or nobody) takes
  /// the user back to the start.
  Future<void> signOut() async {
    if (state.isBusy) return;
    stopWatching();
    _emit(EmailVerificationStatus.signingOut);
    final result = await _signOut();
    if (isClosed) return;
    switch (result.failureOrNull) {
      case final failure?:
        _emit(EmailVerificationStatus.failure, failure);
        watch();
      case null:
        _emit(EmailVerificationStatus.idle);
    }
  }

  static bool _throttled(Failure failure) =>
      failure is AuthFailure && failure.code == _throttledCode;

  void _startCooldown(int seconds) {
    _cooldown?.cancel();
    var left = seconds;
    _withResendIn(left);
    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (--left == 0) timer.cancel();
      _withResendIn(left);
    });
  }

  void _withResendIn(int seconds) => emit(
    EmailVerificationState(
      status: state.status,
      resendIn: seconds,
      pendingEmail: state.pendingEmail,
      failure: state.failure,
    ),
  );

  void _emit(EmailVerificationStatus status, [Failure? failure]) => emit(
    EmailVerificationState(
      status: status,
      resendIn: state.resendIn,
      pendingEmail: state.pendingEmail,
      failure: failure,
    ),
  );

  @override
  Future<void> close() {
    _cooldown?.cancel();
    _watch?.cancel();
    return super.close();
  }
}

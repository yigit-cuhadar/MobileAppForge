import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forge_core/forge_core.dart';

import '../domain/auth_usecases.dart';

enum EmailVerificationStatus { idle, sending, sent, signingOut, failure }

class EmailVerificationState extends Equatable {
  const EmailVerificationState({
    this.status = EmailVerificationStatus.idle,
    this.resendIn = 0,
    this.failure,
  });

  final EmailVerificationStatus status;

  /// Seconds until the email can be sent again; 0 when it can.
  final int resendIn;
  final Failure? failure;

  bool get isBusy => switch (status) {
    EmailVerificationStatus.sending ||
    EmailVerificationStatus.signingOut => true,
    _ => false,
  };

  @override
  List<Object?> get props => [status, resendIn, failure];
}

/// Drives the verification page. While [watch]ing it reloads the user
/// every [checkEvery]; a verified address is not a state here: the
/// reloaded user arrives through `AuthCubit`, whose listeners move on.
class EmailVerificationCubit extends Cubit<EmailVerificationState> {
  EmailVerificationCubit({
    required this._reloadUser,
    required this._sendEmailVerification,
    required this._signOut,
  }) : super(const EmailVerificationState());

  final ReloadUser _reloadUser;
  final SendEmailVerification _sendEmailVerification;
  final SignOut _signOut;
  Timer? _cooldown;
  Timer? _watch;
  bool _reloading = false;

  /// How long Resend waits after an email went out.
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

  Future<void> resend() async {
    if (state.isBusy || state.resendIn > 0) return;
    _emit(EmailVerificationStatus.sending);
    final result = await _sendEmailVerification();
    if (isClosed) return;
    final failure = result.failureOrNull;
    if (failure == null ||
        (failure is AuthFailure && failure.code == _throttledCode)) {
      _startCooldown();
    }
    failure == null
        ? _emit(EmailVerificationStatus.sent)
        : _emit(EmailVerificationStatus.failure, failure);
  }

  /// Signs out; the session that follows (a new guest, or nobody) takes
  /// the user back to the start.
  Future<void> useAnotherAccount() async {
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

  void _startCooldown() {
    _cooldown?.cancel();
    var left = resendCooldown;
    emit(EmailVerificationState(status: state.status, resendIn: left));
    _cooldown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (--left == 0) timer.cancel();
      emit(
        EmailVerificationState(
          status: state.status,
          resendIn: left,
          failure: state.failure,
        ),
      );
    });
  }

  void _emit(EmailVerificationStatus status, [Failure? failure]) => emit(
    EmailVerificationState(
      status: status,
      resendIn: state.resendIn,
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

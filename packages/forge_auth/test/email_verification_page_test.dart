import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_auth/forge_auth.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockVerificationCubit extends MockCubit<EmailVerificationState>
    implements EmailVerificationCubit {}

void main() {
  const user = AuthUser(
    id: 'u1',
    email: 'a@b.co',
    signInMethods: {SignInMethod.email},
  );
  late MockVerificationCubit cubit;
  late StreamController<EmailVerificationState> states;

  setUp(() {
    cubit = MockVerificationCubit();
    states = StreamController<EmailVerificationState>.broadcast();
    whenListen(
      cubit,
      states.stream,
      initialState: const EmailVerificationState(),
    );
    when(() => cubit.watch()).thenReturn(null);
    when(() => cubit.stopWatching()).thenReturn(null);
    when(() => cubit.resend()).thenAnswer((_) async {});
    when(() => cubit.useAnotherAccount()).thenAnswer((_) async {});
    sl.registerFactory<EmailVerificationCubit>(() => cubit);
  });

  tearDown(() async {
    await states.close();
    await sl.reset();
  });

  Future<void> pump(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = MockAuthCubit();
    when(() => auth.state).thenReturn(const Authenticated(user));
    when(() => auth.user).thenReturn(user);
    return tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: BlocProvider<AuthCubit>.value(
          value: auth,
          child: const EmailVerificationPage(),
        ),
      ),
    );
  }

  Future<void> emit(WidgetTester tester, EmailVerificationState state) async {
    when(() => cubit.state).thenReturn(state);
    states.add(state);
    await tester.pump();
    await tester.pump();
  }

  const s = AuthStrings();

  testWidgets('names the address it was sent to and watches for the '
      'verification', (tester) async {
    await pump(tester);

    expect(find.text(s.verifyEmailTitle), findsOneWidget);
    expect(find.text(s.sentTo), findsOneWidget);
    expect(find.text('a@b.co'), findsOneWidget);
    expect(find.text(s.waitingForVerification), findsOneWidget);
    verify(() => cubit.watch()).called(1);
  });

  testWidgets('Resend sends, then waits out its cooldown', (tester) async {
    await pump(tester);

    await tester.tap(find.text(s.resendEmail));
    verify(() => cubit.resend()).called(1);

    await emit(
      tester,
      const EmailVerificationState(
        status: EmailVerificationStatus.sent,
        resendIn: 42,
      ),
    );
    expect(find.text(s.emailSent), findsOneWidget);
    expect(find.text('Resend in 42s'), findsOneWidget);
    final resend = tester.widget<ForgeButton>(
      find.widgetWithText(ForgeButton, 'Resend in 42s'),
    );
    expect(resend.onPressed, isNull);
  });

  testWidgets('a failure shows the failure line', (tester) async {
    await pump(tester);

    await emit(
      tester,
      const EmailVerificationState(
        status: EmailVerificationStatus.failure,
        failure: NetworkFailure(),
      ),
    );

    expect(find.text(s.verificationFailed), findsOneWidget);
  });

  testWidgets('the way out signs out', (tester) async {
    await pump(tester);

    await tester.tap(find.text(s.useAnotherAccount));

    verify(() => cubit.useAnotherAccount()).called(1);
  });

  testWidgets('stops watching while hidden and starts again on return', (
    tester,
  ) async {
    await pump(tester);
    clearInteractions(cubit);

    final binding = tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    verify(() => cubit.stopWatching()).called(1);
    verifyNever(() => cubit.watch());

    binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    verify(() => cubit.watch()).called(1);
  });
}

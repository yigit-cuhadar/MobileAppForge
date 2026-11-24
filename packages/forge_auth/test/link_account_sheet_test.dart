import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_auth/forge_auth.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthFormCubit extends MockCubit<AuthFormState>
    implements AuthFormCubit {}

void main() {
  late MockAuthFormCubit form;
  late StreamController<AuthFormState> states;
  late int usedEmail;

  setUpAll(() => registerFallbackValue(SocialProvider.google));

  setUp(() {
    usedEmail = 0;
    form = MockAuthFormCubit();
    states = StreamController<AuthFormState>.broadcast();
    whenListen(form, states.stream, initialState: const AuthFormState());
    when(() => form.signInWith(any())).thenAnswer((_) async {});
    when(() => form.confirmReplaceGuest()).thenAnswer((_) async {});
    sl.registerFactory<AuthFormCubit>(() => form);
  });

  tearDown(() async {
    await states.close();
    await sl.reset();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showLinkAccountSheet(
                context,
                title: 'Keep your data',
                message: 'Create an account to back it up.',
                onUseEmail: () => usedEmail++,
                providers: const [SocialProvider.google],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> emit(WidgetTester tester, AuthFormState state) async {
    when(() => form.state).thenReturn(state);
    states.add(state);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('shows the title, message and options', (tester) async {
    await open(tester);

    expect(find.text('Keep your data'), findsOneWidget);
    expect(find.text('Create an account to back it up.'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Use email instead'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('Google links and the sheet closes once it went through', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Continue with Google'));
    verify(() => form.signInWith(SocialProvider.google)).called(1);

    await emit(tester, const AuthFormState(status: AuthFormStatus.loading));
    expect(find.text('Signing in…'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Keep your data'), findsOneWidget);

    await emit(tester, const AuthFormState());
    expect(find.text('Keep your data'), findsNothing);
  });

  testWidgets('a failure shows the snackbar over the open sheet', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Continue with Google'));
    await emit(tester, const AuthFormState(status: AuthFormStatus.loading));
    await emit(
      tester,
      const AuthFormState(
        status: AuthFormStatus.failure,
        failure: NetworkFailure(),
      ),
    );

    expect(find.text("Couldn't sign in. Try again."), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Keep your data'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a closed provider sheet keeps the sheet open, quietly', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Continue with Google'));
    await emit(tester, const AuthFormState(status: AuthFormStatus.loading));
    await emit(tester, const AuthFormState(status: AuthFormStatus.cancelled));

    expect(find.text("Couldn't sign in. Try again."), findsNothing);
    expect(find.text('Keep your data'), findsOneWidget);
  });

  testWidgets('an existing account asks before replacing the guest', (
    tester,
  ) async {
    await open(tester);
    await emit(
      tester,
      const AuthFormState(status: AuthFormStatus.confirmReplaceGuest),
    );

    expect(find.text('Use existing account?'), findsOneWidget);
    await tester.tap(find.text('Use existing account'));
    await tester.pumpAndSettle();
    verify(() => form.confirmReplaceGuest()).called(1);
  });

  testWidgets('Use email instead closes the sheet and hands over', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Use email instead'));
    await tester.pumpAndSettle();

    expect(find.text('Keep your data'), findsNothing);
    expect(usedEmail, 1);
  });

  testWidgets('Not now closes the sheet', (tester) async {
    await open(tester);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Keep your data'), findsNothing);
    expect(usedEmail, 0);
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_auth/forge_auth.dart';
import 'package:forge_auth/src/presentation/provider_mark.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockAuthFormCubit extends MockCubit<AuthFormState>
    implements AuthFormCubit {}

void main() {
  late MockAuthFormCubit form;

  setUpAll(() => registerFallbackValue(SocialProvider.google));

  setUp(() {
    form = MockAuthFormCubit();
    when(() => form.state).thenReturn(const AuthFormState());
    when(() => form.signInWith(any())).thenAnswer((_) async {});
    sl.registerFactory<AuthFormCubit>(() => form);
  });

  tearDown(sl.reset);

  Future<void> pump(WidgetTester tester) {
    final auth = MockAuthCubit();
    when(() => auth.state).thenReturn(const Unauthenticated());
    return tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: BlocProvider<AuthCubit>.value(
          value: auth,
          child: const AuthPage(providers: SocialProvider.values),
        ),
      ),
    );
  }

  Finder button(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byType(OutlinedButton),
  );

  Finder mark(String label, SocialProvider provider) => find.descendant(
    of: button(label),
    matching: find.byWidgetPredicate(
      (w) => w is ProviderMark && w.provider == provider,
    ),
  );

  for (final (provider, label) in [
    (SocialProvider.google, 'Continue with Google'),
    (SocialProvider.apple, 'Continue with Apple'),
  ]) {
    testWidgets('$label shows its mark and signs in with it', (tester) async {
      await pump(tester);

      expect(mark(label, provider), findsOneWidget);
      await tester.tap(button(label));
      verify(() => form.signInWith(provider)).called(1);
    });
  }

  testWidgets('the marks are the same size and left out of semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);

    final google = mark('Continue with Google', SocialProvider.google);
    final apple = mark('Continue with Apple', SocialProvider.apple);
    expect(tester.getSize(google), tester.getSize(apple));
    expect(
      tester.getSemantics(button('Continue with Google')),
      matchesSemantics(
        label: 'Continue with Google',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('the Google mark fades with the button while loading', (
    tester,
  ) async {
    when(() => form.state)
        .thenReturn(const AuthFormState(status: AuthFormStatus.loading));
    await pump(tester);

    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: mark('Continue with Google', SocialProvider.google),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, lessThan(1));
    await tester.tap(button('Continue with Google'));
    verifyNever(() => form.signInWith(any()));
  });
}

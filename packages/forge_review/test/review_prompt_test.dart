import 'package:bloc_test/bloc_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_review/forge_review.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockReach extends Mock implements ReachReviewMoment {}

class _MockRequest extends Mock implements RequestStoreReview {}

const _strings = ReviewPromptStrings(
  title: 'Enjoying [APP NAME]?',
  message: 'Your answer helps us improve.',
  yes: 'Yes!',
  no: 'Not really',
  close: 'Close',
  thanksTitle: 'Thanks for telling us',
  thanksMessage: 'Tell us what to improve.',
  writeToUs: 'Write to us',
);

void main() {
  group('ReviewPromptCubit', () {
    setUpAll(() => registerFallbackValue(const ReviewAppOpened(canAsk: false)));
    late _MockReach reach;
    late _MockRequest request;

    setUp(() {
      reach = _MockReach();
      request = _MockRequest();
    });

    ReviewPromptCubit build() =>
        ReviewPromptCubit(reachMoment: reach, requestStoreReview: request);

    blocTest<ReviewPromptCubit, ReviewPromptState>(
      'asks when the moment is due',
      setUp: () =>
          when(() => reach(any(that: isA<ReviewEvent>())))
              .thenAnswer((_) async => const Ok(true)),
      build: build,
      act: (cubit) => cubit.moment(id: 'w', highlight: true, canAsk: true),
      expect: () => [ReviewPromptState.ask],
    );

    blocTest<ReviewPromptCubit, ReviewPromptState>(
      'stays quiet when not due or failing',
      setUp: () =>
          when(() => reach(any()))
              .thenAnswer((_) async => const Err(UnknownFailure('x'))),
      build: build,
      act: (cubit) => cubit.moment(id: 'w', highlight: false, canAsk: true),
      expect: () => <ReviewPromptState>[],
    );

    blocTest<ReviewPromptCubit, ReviewPromptState>(
      'an app open asks when due',
      setUp: () =>
          when(() => reach(any(that: isA<ReviewAppOpened>())))
              .thenAnswer((_) async => const Ok(true)),
      build: build,
      act: (cubit) => cubit.opened(canAsk: true),
      expect: () => [ReviewPromptState.ask],
    );

    test('rate opens the platform prompt', () async {
      when(() => request()).thenAnswer((_) async => const Ok(null));
      await build().rate();
      verify(() => request()).called(1);
    });
  });

  group('showReviewPrompt', () {
    late ReviewAnswer? answer;
    late bool answered;

    Future<void> open(WidgetTester tester) async {
      answered = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ForgeTheme.light(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                answer = await showReviewPrompt(context, _strings);
                answered = true;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('Yes answers liked', (tester) async {
      await open(tester);
      await tester.tap(find.text('Yes!'));
      await tester.pumpAndSettle();
      expect((answered, answer), (true, ReviewAnswer.liked));
    });

    testWidgets('the close button answers nothing', (tester) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect((answered, answer), (true, null));
    });

    testWidgets('Not really thanks in the same dialog, then Write to us', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Not really'));
      await tester.pumpAndSettle();
      expect(answered, isFalse);
      expect(find.text('Thanks for telling us'), findsOneWidget);
      expect(find.text('Enjoying [APP NAME]?'), findsNothing);

      await tester.tap(find.text('Write to us'));
      await tester.pumpAndSettle();
      expect((answered, answer), (true, ReviewAnswer.writeToUs));
    });

    testWidgets('Close after the thanks answers nothing', (tester) async {
      await open(tester);
      await tester.tap(find.text('Not really'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect((answered, answer), (true, null));
    });
  });
}

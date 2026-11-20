import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_review/forge_review.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ReviewRepository {}

void main() {
  const rules = ReviewRules(firstAfter: 3, cooldown: Duration(days: 30));
  final now = DateTime(2026, 11, 20);
  late _MockRepository repository;
  late ReachReviewMoment reach;

  setUpAll(() => registerFallbackValue(const ReviewHistory()));

  setUp(() {
    repository = _MockRepository();
    reach = ReachReviewMoment(repository, rules, clock: () => now);
    when(() => repository.appVersion())
        .thenAnswer((_) async => const Ok('1.0.0'));
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));
  });

  void stored(ReviewHistory history) =>
      when(() => repository.load()).thenAnswer((_) async => Ok(history));

  test('counts a moment and asks at the third, recording the ask', () async {
    stored(const ReviewHistory(events: 2, lastEventId: 'w2'));

    final result = await reach((id: 'w3', highlight: false, canAsk: true));

    expect(result.valueOrNull, isTrue);
    verify(
      () => repository.save(
        ReviewHistory(
          events: 3,
          lastEventId: 'w3',
          askedAt: now,
          askedVersion: '1.0.0',
        ),
      ),
    ).called(1);
  });

  test('counts the same moment once', () async {
    stored(
      const ReviewHistory(events: 3, lastEventId: 'w3', askedVersion: '1.0.0'),
    );

    final result = await reach((id: 'w3', highlight: false, canAsk: true));

    expect(result.valueOrNull, isFalse);
    verifyNever(() => repository.save(any()));
  });

  test('where it cannot ask, counts without asking', () async {
    stored(const ReviewHistory(events: 2, lastEventId: 'w2'));

    final result = await reach((id: 'w3', highlight: true, canAsk: false));

    expect(result.valueOrNull, isFalse);
    verify(
      () => repository.save(const ReviewHistory(events: 3, lastEventId: 'w3')),
    ).called(1);
    verifyNever(() => repository.appVersion());
  });

  test('without the app version, counts without asking', () async {
    stored(const ReviewHistory(events: 2));
    when(() => repository.appVersion())
        .thenAnswer((_) async => const Err(UnknownFailure('no version')));

    final result = await reach((id: 'w3', highlight: false, canAsk: true));

    expect(result.valueOrNull, isFalse);
    verify(
      () => repository.save(const ReviewHistory(events: 3, lastEventId: 'w3')),
    ).called(1);
  });

  test('an unreadable history fails without saving', () async {
    when(() => repository.load())
        .thenAnswer((_) async => const Err(UnknownFailure('broken')));

    final result = await reach((id: 'w3', highlight: false, canAsk: true));

    expect(result.failureOrNull, isA<UnknownFailure>());
    verifyNever(() => repository.save(any()));
  });

  test('an ask that could not be recorded is not made', () async {
    stored(const ReviewHistory(events: 2));
    when(() => repository.save(any()))
        .thenAnswer((_) async => const Err(UnknownFailure('full')));

    final result = await reach((id: 'w3', highlight: false, canAsk: true));

    expect(result.isOk, isFalse);
  });
}

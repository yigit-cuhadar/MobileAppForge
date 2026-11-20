import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_review/forge_review.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ReviewRepository {}

void main() {
  const rules = ReviewRules(
    firstAfterEvents: 2,
    firstAfterDays: 3,
    cooldown: Duration(days: 30),
  );
  final now = DateTime(2026, 11, 20, 18, 30);
  final today = DateTime(2026, 11, 20);
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

  test('counts an event and asks at the second, recording the ask', () async {
    stored(const ReviewHistory(events: 1, lastEventId: 'w2'));

    final result = await reach(
      const ReviewEvent(id: 'w3', highlight: false, canAsk: true),
    );

    expect(result.valueOrNull, isTrue);
    verify(
      () => repository.save(
        ReviewHistory(
          events: 2,
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

    final result = await reach(
      const ReviewEvent(id: 'w3', highlight: false, canAsk: true),
    );

    expect(result.valueOrNull, isFalse);
    verifyNever(() => repository.save(any()));
  });

  test('where it cannot ask, counts without asking', () async {
    stored(const ReviewHistory(events: 2, lastEventId: 'w2'));

    final result = await reach(
      const ReviewEvent(id: 'w3', highlight: true, canAsk: false),
    );

    expect(result.valueOrNull, isFalse);
    verify(
      () => repository.save(const ReviewHistory(events: 3, lastEventId: 'w3')),
    ).called(1);
    verifyNever(() => repository.appVersion());
  });

  test('without the app version, counts without asking', () async {
    stored(const ReviewHistory(events: 1));
    when(() => repository.appVersion())
        .thenAnswer((_) async => const Err(UnknownFailure('no version')));

    final result = await reach(
      const ReviewEvent(id: 'w3', highlight: false, canAsk: true),
    );

    expect(result.valueOrNull, isFalse);
    verify(
      () => repository.save(const ReviewHistory(events: 2, lastEventId: 'w3')),
    ).called(1);
  });

  group('an app open', () {
    test('counts a new day and asks on the third', () async {
      stored(ReviewHistory(openDays: 2, lastOpenDay: DateTime(2026, 11, 18)));

      final result = await reach(const ReviewAppOpened(canAsk: true));

      expect(result.valueOrNull, isTrue);
      verify(
        () => repository.save(
          ReviewHistory(
            openDays: 3,
            lastOpenDay: today,
            askedAt: now,
            askedVersion: '1.0.0',
          ),
        ),
      ).called(1);
    });

    test('counts a day once', () async {
      stored(ReviewHistory(openDays: 2, lastOpenDay: today));

      final result = await reach(const ReviewAppOpened(canAsk: true));

      expect(result.valueOrNull, isFalse);
      verifyNever(() => repository.save(any()));
    });

    test('where it cannot ask, the day still counts, and a later open on '
        'it asks', () async {
      stored(ReviewHistory(openDays: 2, lastOpenDay: DateTime(2026, 11, 19)));
      await reach(const ReviewAppOpened(canAsk: false));
      verify(
        () => repository.save(ReviewHistory(openDays: 3, lastOpenDay: today)),
      ).called(1);

      stored(ReviewHistory(openDays: 3, lastOpenDay: today));
      expect(
        (await reach(const ReviewAppOpened(canAsk: true))).valueOrNull,
        isTrue,
      );
    });

    test('is never a highlight', () async {
      stored(
        ReviewHistory(
          openDays: 9,
          lastOpenDay: DateTime(2026, 9, 1),
          askedAt: DateTime(2026, 9, 1),
          askedVersion: '0.9.0',
        ),
      );

      expect(
        (await reach(const ReviewAppOpened(canAsk: true))).valueOrNull,
        isFalse,
      );
    });
  });

  test('an unreadable history fails without saving', () async {
    when(() => repository.load())
        .thenAnswer((_) async => const Err(UnknownFailure('broken')));

    final result = await reach(
      const ReviewEvent(id: 'w3', highlight: false, canAsk: true),
    );

    expect(result.failureOrNull, isA<UnknownFailure>());
    verifyNever(() => repository.save(any()));
  });

  test('an ask that could not be recorded is not made', () async {
    stored(const ReviewHistory(events: 1));
    when(() => repository.save(any()))
        .thenAnswer((_) async => const Err(UnknownFailure('full')));

    final result = await reach(
      const ReviewEvent(id: 'w3', highlight: false, canAsk: true),
    );

    expect(result.isOk, isFalse);
  });
}

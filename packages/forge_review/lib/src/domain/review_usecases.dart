import 'package:forge_core/forge_core.dart';

import 'review_repository.dart';
import 'review_rules.dart';

/// A moment the app may ask at, and whether the screen [canAsk] (not where
/// something else, such as a paywall, is shown).
sealed class ReviewMoment {
  const ReviewMoment({required this.canAsk});

  final bool canAsk;
}

/// An event the app counts, such as a finished workout: [id] counts once;
/// a [highlight] (such as a new record) may ask again later.
final class ReviewEvent extends ReviewMoment {
  const ReviewEvent({
    required this.id,
    required this.highlight,
    required super.canAsk,
  });

  final String id;
  final bool highlight;
}

/// The app was opened (launched or brought back); today counts once.
final class ReviewAppOpened extends ReviewMoment {
  const ReviewAppOpened({required super.canAsk});
}

/// Counts a moment and tells whether to ask now ([ReviewRules.due]). An
/// ask is recorded at once, whatever the user answers later.
class ReachReviewMoment implements UseCase<bool, ReviewMoment> {
  ReachReviewMoment(this._repository, this._rules, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ReviewRepository _repository;
  final ReviewRules _rules;
  final DateTime Function() _clock;

  @override
  Future<Result<bool>> call(ReviewMoment moment) async {
    final ReviewHistory stored;
    switch (await _repository.load()) {
      case Ok(:final value):
        stored = value;
      case Err(:final failure):
        return Err(failure);
    }
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final counted = switch (moment) {
      ReviewEvent(:final id) when stored.lastEventId != id => stored.copyWith(
        events: stored.events + 1,
        lastEventId: id,
      ),
      ReviewAppOpened() when stored.lastOpenDay != today => stored.copyWith(
        openDays: stored.openDays + 1,
        lastOpenDay: today,
      ),
      _ => stored,
    };
    var ask = false;
    var history = counted;
    if (moment.canAsk) {
      final version = await _repository.appVersion();
      if (version case Ok(value: final version)) {
        ask = _rules.due(
          counted,
          highlight: moment is ReviewEvent && moment.highlight,
          version: version,
          now: now,
        );
        if (ask) {
          history = counted.copyWith(askedAt: now, askedVersion: version);
        }
      }
    }
    if (history == stored) return Ok(ask);
    final saved = await _repository.save(history);
    return saved.map((_) => ask);
  }
}

class RequestStoreReview implements UseCase<void, NoParams> {
  const RequestStoreReview(this._repository);
  final ReviewRepository _repository;

  @override
  Future<Result<void>> call([NoParams params = const NoParams()]) =>
      _repository.requestReview();
}

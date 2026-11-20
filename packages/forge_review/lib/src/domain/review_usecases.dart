import 'package:forge_core/forge_core.dart';

import 'review_repository.dart';
import 'review_rules.dart';

/// A moment the app may ask at: its [id] (a moment counts once),
/// whether it is a [highlight], and whether the screen [canAsk] (not where
/// something else, such as a paywall, is shown).
typedef ReviewMomentParams = ({String id, bool highlight, bool canAsk});

/// Counts a moment and tells whether to ask now ([ReviewRules.due]). An
/// ask is recorded at once, whatever the user answers later.
class ReachReviewMoment implements UseCase<bool, ReviewMomentParams> {
  ReachReviewMoment(this._repository, this._rules, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ReviewRepository _repository;
  final ReviewRules _rules;
  final DateTime Function() _clock;

  @override
  Future<Result<bool>> call(ReviewMomentParams params) async {
    final ReviewHistory stored;
    switch (await _repository.load()) {
      case Ok(:final value):
        stored = value;
      case Err(:final failure):
        return Err(failure);
    }
    final counted = stored.lastEventId == params.id
        ? stored
        : stored.copyWith(events: stored.events + 1, lastEventId: params.id);
    var ask = false;
    var history = counted;
    if (params.canAsk) {
      final version = await _repository.appVersion();
      if (version case Ok(value: final version)) {
        final now = _clock();
        ask = _rules.due(
          counted,
          highlight: params.highlight,
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

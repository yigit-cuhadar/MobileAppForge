import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/review_usecases.dart';

/// Whether the screen should show the review prompt ([showReviewPrompt]).
enum ReviewPromptState { idle, ask }

/// Decides at a moment whether to ask for a review, and opens the
/// platform's review prompt for a user who likes the app.
class ReviewPromptCubit extends Cubit<ReviewPromptState> {
  ReviewPromptCubit({
    required this._reachMoment,
    required this._requestStoreReview,
  }) : super(ReviewPromptState.idle);

  final ReachReviewMoment _reachMoment;
  final RequestStoreReview _requestStoreReview;

  /// Counts event [id] and asks when the rules say so; see [ReviewEvent].
  /// A failure only means not asking.
  Future<void> moment({
    required String id,
    required bool highlight,
    required bool canAsk,
  }) => _reach(ReviewEvent(id: id, highlight: highlight, canAsk: canAsk));

  /// Counts today as a day the app was opened on, and asks when the rules
  /// say so.
  Future<void> opened({required bool canAsk}) =>
      _reach(ReviewAppOpened(canAsk: canAsk));

  Future<void> _reach(ReviewMoment moment) async {
    final ask = await _reachMoment(moment);
    if (isClosed) return;
    if (ask.valueOrNull ?? false) emit(ReviewPromptState.ask);
  }

  /// The user likes the app: the platform's review prompt.
  Future<void> rate() => _requestStoreReview();
}

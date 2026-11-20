import 'package:forge_core/forge_core.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/device_review_repository.dart';
import 'domain/review_repository.dart';
import 'domain/review_rules.dart';
import 'domain/review_usecases.dart';
import 'presentation/review_prompt_cubit.dart';

/// Registers the review prompt with the app's [rules].
class ReviewModule implements FeatureModule {
  const ReviewModule({required this.rules});

  final ReviewRules rules;

  @override
  void register(GetIt sl) {
    sl
      ..registerLazySingleton<ReviewRepository>(
        () => DeviceReviewRepository(
          SharedPreferencesAsync(),
          InAppReview.instance,
        ),
      )
      ..registerFactory(() => ReachReviewMoment(sl(), rules))
      ..registerFactory(() => RequestStoreReview(sl()))
      ..registerFactory(
        () => ReviewPromptCubit(reachMoment: sl(), requestStoreReview: sl()),
      );
  }
}

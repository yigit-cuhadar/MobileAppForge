/// Asks happy users for a store review and sends unhappy ones to the app's
/// feedback form.
///
/// Register `ReviewModule(rules: ReviewRules(...))`. At each moment the app
/// may ask (such as a finished workout), provide `sl<ReviewPromptCubit>()`,
/// call `moment(...)`, and when its state turns to `ask`, show
/// `showReviewPrompt` with the app's strings: on `liked` call `rate()`,
/// on `writeToUs` open the app's feedback form. The history lives on the
/// device, so a reinstall starts it again.
library;

export 'src/domain/review_repository.dart';
export 'src/domain/review_rules.dart';
export 'src/domain/review_usecases.dart';
export 'src/presentation/review_prompt_cubit.dart';
export 'src/presentation/review_prompt_dialog.dart';
export 'src/review_module.dart';

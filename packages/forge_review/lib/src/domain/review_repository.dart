import 'package:forge_core/forge_core.dart';

import 'review_rules.dart';

/// The review history kept on the device, the app's version, and the
/// platform's review prompt.
abstract interface class ReviewRepository {
  /// An empty history on a device that never stored one.
  Future<Result<ReviewHistory>> load();

  Future<Result<void>> save(ReviewHistory history);

  /// The installed app's version, such as "1.2.0".
  Future<Result<String>> appVersion();

  /// The platform's own review prompt (the App Store's, or Google Play's
  /// in-app review). The platform decides whether it shows, so success
  /// does not mean the user saw it; where there is none, nothing happens.
  Future<Result<void>> requestReview();
}

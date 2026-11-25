import 'package:forge_core/forge_core.dart';

/// Pushed messages this device takes, by the app's `LanguageTopics`.
abstract interface class TopicRepository {
  /// Takes [language]'s messages from now on, leaving every other
  /// language's topics. With a [segment] also that segment's, leaving the
  /// language's other segments; without one the segment topics stay as they
  /// are. The first call turns on push tokens and starts showing and
  /// reporting messages. Without a push token (iOS without APNs) it does
  /// nothing and succeeds.
  Future<Result<void>> follow(String language, {String? segment});
}

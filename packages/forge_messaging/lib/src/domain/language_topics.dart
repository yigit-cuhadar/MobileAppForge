/// The FCM topics of one kind of pushed message, one per language:
/// `<prefix>_<language>` for everyone of that language, and
/// `<prefix>_<language>_<segment>` for one of its [segments] (such as free
/// and paying users).
final class LanguageTopics {
  const LanguageTopics(
    this.prefix, {
    required this.languages,
    required this.segments,
  });

  final String prefix;

  /// Every language the app has, so a device leaves the others' topics.
  final List<String> languages;
  final List<String> segments;

  String topic(String language, {String? segment}) => segment == null
      ? '${prefix}_$language'
      : '${prefix}_${language}_$segment';
}

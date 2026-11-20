import 'package:flutter_test/flutter_test.dart';
import 'package:forge_review/forge_review.dart';

void main() {
  const rules = ReviewRules(firstAfter: 3, cooldown: Duration(days: 30));
  final now = DateTime(2026, 11, 20, 12);

  bool due(ReviewHistory history, {bool highlight = false, String v = '1.1'}) =>
      rules.due(history, highlight: highlight, version: v, now: now);

  group('the first ask', () {
    test('comes once the third moment was counted, highlight or not', () {
      expect(due(const ReviewHistory(events: 2)), isFalse);
      expect(due(const ReviewHistory(events: 3)), isTrue);
      expect(due(const ReviewHistory(events: 4)), isTrue);
    });
  });

  group('a later ask', () {
    ReviewHistory askedDaysAgo(int days, {String version = '1.0'}) =>
        ReviewHistory(
          events: 9,
          askedAt: now.subtract(Duration(days: days)),
          askedVersion: version,
        );

    test('needs a highlight', () {
      expect(due(askedDaysAgo(60)), isFalse);
      expect(due(askedDaysAgo(60), highlight: true), isTrue);
    });

    test('waits 30 days after the last ask', () {
      expect(due(askedDaysAgo(29), highlight: true), isFalse);
      expect(due(askedDaysAgo(30), highlight: true), isTrue);
    });

    test('never comes twice in one app version', () {
      expect(due(askedDaysAgo(90, version: '1.1'), highlight: true), isFalse);
    });
  });
}

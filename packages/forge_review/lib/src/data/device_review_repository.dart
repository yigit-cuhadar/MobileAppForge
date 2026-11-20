import 'package:forge_core/forge_core.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/review_repository.dart';
import '../domain/review_rules.dart';

/// Keeps the history in shared preferences, so it lives as long as the
/// install, and asks through `in_app_review`.
class DeviceReviewRepository implements ReviewRepository {
  DeviceReviewRepository(this._preferences, this._review);

  final SharedPreferencesAsync _preferences;
  final InAppReview _review;

  static const _events = 'forge_review.events';
  static const _lastEventId = 'forge_review.lastEventId';
  static const _openDays = 'forge_review.openDays';
  static const _lastOpenDay = 'forge_review.lastOpenDay';
  static const _askedAt = 'forge_review.askedAtMs';
  static const _askedVersion = 'forge_review.askedVersion';

  @override
  Future<Result<ReviewHistory>> load() => guard(() async {
    final askedAt = await _preferences.getInt(_askedAt);
    final lastOpenDay = await _preferences.getString(_lastOpenDay);
    return ReviewHistory(
      events: await _preferences.getInt(_events) ?? 0,
      lastEventId: await _preferences.getString(_lastEventId),
      openDays: await _preferences.getInt(_openDays) ?? 0,
      lastOpenDay: lastOpenDay == null ? null : DateTime.tryParse(lastOpenDay),
      askedAt: askedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(askedAt),
      askedVersion: await _preferences.getString(_askedVersion),
    );
  });

  @override
  Future<Result<void>> save(ReviewHistory history) => guard(() async {
    await _preferences.setInt(_events, history.events);
    if (history.lastEventId case final id?) {
      await _preferences.setString(_lastEventId, id);
    }
    await _preferences.setInt(_openDays, history.openDays);
    if (history.lastOpenDay case final day?) {
      // The local date alone, so a change of time zone keeps the day.
      await _preferences.setString(
        _lastOpenDay,
        day.toIso8601String().substring(0, 10),
      );
    }
    if (history.askedAt case final at?) {
      await _preferences.setInt(_askedAt, at.millisecondsSinceEpoch);
    }
    if (history.askedVersion case final version?) {
      await _preferences.setString(_askedVersion, version);
    }
  });

  @override
  Future<Result<String>> appVersion() =>
      guard(() async => (await PackageInfo.fromPlatform()).version);

  @override
  Future<Result<void>> requestReview() => guard(() async {
    if (await _review.isAvailable()) await _review.requestReview();
  });
}

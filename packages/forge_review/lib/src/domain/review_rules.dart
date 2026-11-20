import 'package:forge_core/forge_core.dart';

/// What the device remembers about asking for a review.
class ReviewHistory extends Equatable {
  const ReviewHistory({
    this.events = 0,
    this.lastEventId,
    this.askedAt,
    this.askedVersion,
  });

  /// The moments counted so far, such as finished workouts.
  final int events;

  /// The last moment counted, so the same one never counts twice.
  final String? lastEventId;

  /// When the app last asked; null before the first time.
  final DateTime? askedAt;

  /// The app version that last asked.
  final String? askedVersion;

  ReviewHistory copyWith({
    int? events,
    String? lastEventId,
    DateTime? askedAt,
    String? askedVersion,
  }) => ReviewHistory(
    events: events ?? this.events,
    lastEventId: lastEventId ?? this.lastEventId,
    askedAt: askedAt ?? this.askedAt,
    askedVersion: askedVersion ?? this.askedVersion,
  );

  @override
  List<Object?> get props => [events, lastEventId, askedAt, askedVersion];
}

/// When the app asks: first at any moment once [firstAfter] moments were
/// counted, later only at a highlight moment at least [cooldown] after the
/// last ask, and never twice in one app version.
class ReviewRules {
  const ReviewRules({required this.firstAfter, required this.cooldown});

  final int firstAfter;
  final Duration cooldown;

  /// Whether a moment, a [highlight] or not, asks now, after [history], in
  /// app [version].
  bool due(
    ReviewHistory history, {
    required bool highlight,
    required String version,
    required DateTime now,
  }) {
    if (history.askedVersion == version) return false;
    final askedAt = history.askedAt;
    if (askedAt == null) return history.events >= firstAfter;
    return highlight && !now.isBefore(askedAt.add(cooldown));
  }
}

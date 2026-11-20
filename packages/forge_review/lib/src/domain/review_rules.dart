import 'package:forge_core/forge_core.dart';

/// What the device remembers about asking for a review.
class ReviewHistory extends Equatable {
  const ReviewHistory({
    this.events = 0,
    this.lastEventId,
    this.openDays = 0,
    this.lastOpenDay,
    this.askedAt,
    this.askedVersion,
  });

  /// The events counted so far, such as finished workouts.
  final int events;

  /// The last event counted, so the same one never counts twice.
  final String? lastEventId;

  /// The different local calendar days the app was opened on.
  final int openDays;

  /// The last of them, at local midnight.
  final DateTime? lastOpenDay;

  /// When the app last asked; null before the first time.
  final DateTime? askedAt;

  /// The app version that last asked.
  final String? askedVersion;

  ReviewHistory copyWith({
    int? events,
    String? lastEventId,
    int? openDays,
    DateTime? lastOpenDay,
    DateTime? askedAt,
    String? askedVersion,
  }) => ReviewHistory(
    events: events ?? this.events,
    lastEventId: lastEventId ?? this.lastEventId,
    openDays: openDays ?? this.openDays,
    lastOpenDay: lastOpenDay ?? this.lastOpenDay,
    askedAt: askedAt ?? this.askedAt,
    askedVersion: askedVersion ?? this.askedVersion,
  );

  @override
  List<Object?> get props => [
    events,
    lastEventId,
    openDays,
    lastOpenDay,
    askedAt,
    askedVersion,
  ];
}

/// When the app asks: first at any moment once [firstAfterEvents] events
/// were counted or the app was opened on [firstAfterDays] different days,
/// whichever comes first; later only at a highlight moment at least
/// [cooldown] after the last ask; never twice in one app version.
class ReviewRules {
  const ReviewRules({
    required this.firstAfterEvents,
    required this.firstAfterDays,
    required this.cooldown,
  });

  final int firstAfterEvents;
  final int firstAfterDays;
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
    if (askedAt == null) {
      return history.events >= firstAfterEvents ||
          history.openDays >= firstAfterDays;
    }
    return highlight && !now.isBefore(askedAt.add(cooldown));
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_firebase/forge_firebase.dart';
import 'package:forge_notifications/forge_notifications.dart';

import '../domain/language_topics.dart';
import '../domain/topic_repository.dart';

/// [TopicRepository] over FCM topics. Messages arrive as notification
/// messages: the system shows them while the app is in the background; in
/// front, this shows them as local notification [notificationId], a newer
/// one replacing it. Taps on either add [tapPayload] to [_taps].
class FcmTopicRepository implements TopicRepository {
  FcmTopicRepository(
    this._messaging,
    this._topics, {
    required this.notificationId,
    required this.tapPayload,
    required this._onMessage,
    required Stream<RemoteMessage> onMessageOpenedApp,
    required this._notifications,
    required this._taps,
  }) : _onOpened = onMessageOpenedApp;

  final FirebaseMessaging _messaging;
  final LanguageTopics _topics;
  final int notificationId;
  final String tapPayload;
  final Stream<RemoteMessage> _onMessage;
  final Stream<RemoteMessage> _onOpened;
  final Future<Notifications> _notifications;
  final NotificationTaps _taps;
  var _listening = false;

  @override
  Future<Result<void>> follow(String language, {String? segment}) =>
      guard(() async {
        await _listen();
        // Off in the native config, so devices that never allow
        // notifications get no push token.
        await _messaging.setAutoInitEnabled(true);
        if (!await _hasToken()) return;
        for (final other in _topics.languages) {
          if (other == language) continue;
          await _messaging.unsubscribeFromTopic(_topics.topic(other));
          for (final each in _topics.segments) {
            await _messaging.unsubscribeFromTopic(
              _topics.topic(other, segment: each),
            );
          }
        }
        await _messaging.subscribeToTopic(_topics.topic(language));
        if (segment == null) return;
        for (final other in _topics.segments) {
          if (other == segment) continue;
          await _messaging.unsubscribeFromTopic(
            _topics.topic(language, segment: other),
          );
        }
        await _messaging.subscribeToTopic(
          _topics.topic(language, segment: segment),
        );
      }, mapper: mapFirebaseError);

  Future<void> _listen() async {
    if (_listening) return;
    _listening = true;
    _onMessage.listen(_show);
    _onOpened.listen((_) => _taps.add(tapPayload));
    if (await _messaging.getInitialMessage() != null) _taps.add(tapPayload);
  }

  /// iOS has no push token without APNs, and topics cannot be followed
  /// without one. Android without Play services fails to subscribe instead.
  Future<bool> _hasToken() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return true;
    if (await _messaging.getAPNSToken() != null) return true;
    Log.d('messaging', 'no APNs token; topics not followed');
    return false;
  }

  Future<void> _show(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title;
    final body = notification?.body;
    if (title == null && body == null) return;
    final result = await (await _notifications).show(
      notificationId,
      title: title ?? '',
      body: body ?? '',
      payload: tapPayload,
    );
    if (result.failureOrNull case final failure?) {
      Log.e('messaging', 'not shown: ${failure.message}');
    }
  }
}

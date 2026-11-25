import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_notifications/forge_notifications.dart';
import 'package:get_it/get_it.dart';

import 'data/fcm_topic_repository.dart';
import 'data/fcm_push_token_source.dart';
import 'domain/language_topics.dart';
import 'domain/push_token_source.dart';
import 'domain/topic_repository.dart';

/// Registers [TopicRepository] for the app's [topics] and [PushTokenSource].
/// Messages in front of the app show as local notification
/// [notificationId]; taps on them add [tapPayload] to the app's
/// [NotificationTaps]. Needs [NotificationTaps] and an async [Notifications]
/// registered before it.
class MessagingModule implements FeatureModule {
  const MessagingModule({
    required this.topics,
    required this.notificationId,
    required this.tapPayload,
  });

  final LanguageTopics topics;
  final int notificationId;
  final String tapPayload;

  @override
  void register(GetIt sl) {
    sl
      ..registerLazySingleton<TopicRepository>(
        () => FcmTopicRepository(
          FirebaseMessaging.instance,
          topics,
          notificationId: notificationId,
          tapPayload: tapPayload,
          onMessage: FirebaseMessaging.onMessage,
          onMessageOpenedApp: FirebaseMessaging.onMessageOpenedApp,
          notifications: sl.getAsync<Notifications>(),
          taps: sl(),
        ),
      )
      ..registerLazySingleton<PushTokenSource>(
        () => FcmPushTokenSource(FirebaseMessaging.instance),
      );
  }
}

/// Pushed messages over FCM topics, one per language, shown in front of the
/// app through forge_notifications, and the install's push token.
///
/// Register `MessagingModule` after the app's `NotificationTaps` and
/// `Notifications`, and call `TopicRepository.follow` once the device allows
/// notifications, again on resume after a failure.
///
/// ## App setup (firebase_messaging 17)
///
/// Push tokens stay off until the first follow. Android,
/// `android/app/src/main/AndroidManifest.xml`, in `<application>` (the
/// channel and icon are the app's local notification ones):
/// ```xml
/// <meta-data android:name="firebase_messaging_auto_init_enabled"
///   android:value="false"/>
/// <meta-data
///   android:name="com.google.firebase.messaging.default_notification_channel_id"
///   android:value="<channel id>"/>
/// <meta-data
///   android:name="com.google.firebase.messaging.default_notification_icon"
///   android:resource="@drawable/<androidIcon>"/>
/// ```
/// iOS, `Info.plist`: `FirebaseMessagingAutoInitEnabled` false; the Push
/// Notifications capability (`aps-environment`), `remote-notification` in
/// the background modes, and an APNs key uploaded to the Firebase project.
library;

export 'src/domain/push_token_source.dart';
export 'src/domain/language_topics.dart';
export 'src/domain/topic_repository.dart';
export 'src/messaging_module.dart';

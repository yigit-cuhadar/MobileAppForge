import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_messaging/forge_messaging.dart';
import 'package:forge_messaging/src/data/fcm_topic_repository.dart';
import 'package:forge_notifications/forge_notifications.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

class _MockNotifications extends Mock implements Notifications {}

const _topics = LanguageTopics(
  'news',
  languages: ['en', 'de'],
  segments: ['free', 'paid'],
);

void main() {
  late _MockMessaging messaging;
  late _MockNotifications notifications;
  late StreamController<RemoteMessage> messages;
  late StreamController<RemoteMessage> opened;
  late NotificationTaps taps;
  late List<String?> tapped;
  late FcmTopicRepository repository;

  setUp(() {
    messaging = _MockMessaging();
    notifications = _MockNotifications();
    messages = StreamController();
    opened = StreamController();
    taps = NotificationTaps();
    tapped = [];
    taps.stream.listen(tapped.add);
    when(() => messaging.getInitialMessage()).thenAnswer((_) async => null);
    when(() => messaging.getAPNSToken()).thenAnswer((_) async => null);
    when(() => messaging.setAutoInitEnabled(any())).thenAnswer((_) async {});
    when(() => messaging.subscribeToTopic(any())).thenAnswer((_) async {});
    when(() => messaging.unsubscribeFromTopic(any())).thenAnswer((_) async {});
    when(
      () => notifications.show(
        any(),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async => const Ok(null));
    repository = FcmTopicRepository(
      messaging,
      _topics,
      notificationId: 7,
      tapPayload: 'news',
      onMessage: messages.stream,
      onMessageOpenedApp: opened.stream,
      notifications: Future.value(notifications),
      taps: taps,
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    unawaited(messages.close());
    unawaited(opened.close());
  });

  test('names a language topic and its segments', () {
    expect(_topics.topic('en'), 'news_en');
    expect(_topics.topic('en', segment: 'paid'), 'news_en_paid');
  });

  test('follows its language and leaves the others', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final result = await repository.follow('en');

    expect(result.isOk, isTrue);
    verifyInOrder([
      () => messaging.unsubscribeFromTopic('news_de'),
      () => messaging.unsubscribeFromTopic('news_de_free'),
      () => messaging.unsubscribeFromTopic('news_de_paid'),
      () => messaging.subscribeToTopic('news_en'),
    ]);
    verifyNever(() => messaging.unsubscribeFromTopic('news_en'));
  });

  test('without a segment it keeps the segment topics', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await repository.follow('en');

    for (final topic in const ['news_en_free', 'news_en_paid']) {
      verifyNever(() => messaging.subscribeToTopic(topic));
      verifyNever(() => messaging.unsubscribeFromTopic(topic));
    }
  });

  test('follows its segment and leaves the others', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await repository.follow('en', segment: 'paid');
    verifyInOrder([
      () => messaging.subscribeToTopic('news_en'),
      () => messaging.unsubscribeFromTopic('news_en_free'),
      () => messaging.subscribeToTopic('news_en_paid'),
    ]);

    await repository.follow('en', segment: 'free');
    verifyInOrder([
      () => messaging.unsubscribeFromTopic('news_en_paid'),
      () => messaging.subscribeToTopic('news_en_free'),
    ]);
  });

  test('turns on push tokens before following', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await repository.follow('en');

    verifyInOrder([
      () => messaging.setAutoInitEnabled(true),
      () => messaging.subscribeToTopic('news_en'),
    ]);
  });

  test('on iOS without an APNs token it quietly follows nothing', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final result = await repository.follow('en');

    expect(result.isOk, isTrue);
    verify(() => messaging.setAutoInitEnabled(true)).called(1);
    verifyNever(() => messaging.subscribeToTopic(any()));
  });

  test('on iOS with an APNs token it follows', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    when(() => messaging.getAPNSToken()).thenAnswer((_) async => 'apns');

    await repository.follow('en');

    verify(() => messaging.subscribeToTopic('news_en')).called(1);
  });

  test('a failed subscription is a failure', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    when(() => messaging.subscribeToTopic(any()))
        .thenThrow(Exception('no Play services'));

    expect((await repository.follow('en')).isOk, isFalse);
  });

  test('shows a message arriving in front of the app', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await repository.follow('en');

    messages
      ..add(
        const RemoteMessage(
          notification: RemoteNotification(title: 'New', body: 'Items'),
        ),
      )
      ..add(const RemoteMessage(data: {'silent': 'yes'}));
    await pumpEventQueue();

    verify(
      () => notifications.show(7, title: 'New', body: 'Items', payload: 'news'),
    ).called(1);
  });

  test('shows nothing before the first follow', () async {
    messages.add(
      const RemoteMessage(notification: RemoteNotification(title: 'New')),
    );
    await pumpEventQueue();

    verifyNever(
      () => notifications.show(
        any(),
        title: any(named: 'title'),
        body: any(named: 'body'),
        payload: any(named: 'payload'),
      ),
    );
  });

  test('reports taps, including the one that launched the app', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    when(() => messaging.getInitialMessage())
        .thenAnswer((_) async => const RemoteMessage());

    await repository.follow('en');
    opened.add(const RemoteMessage());
    await pumpEventQueue();

    expect(tapped, ['news', 'news']);
  });

  test('listens once however often it follows', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await repository.follow('en');
    await repository.follow('de');

    verify(() => messaging.getInitialMessage()).called(1);
  });
}

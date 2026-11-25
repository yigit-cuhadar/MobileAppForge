import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_messaging/src/data/fcm_push_token_source.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessaging extends Mock implements FirebaseMessaging {}

void main() {
  late _MockMessaging messaging;
  late FcmPushTokenSource tokens;

  setUp(() {
    messaging = _MockMessaging();
    tokens = FcmPushTokenSource(messaging);
    when(() => messaging.isAutoInitEnabled).thenReturn(true);
    when(() => messaging.getAPNSToken()).thenAnswer((_) async => 'apns');
    // ignore: deprecated_member_use
    when(() => messaging.getToken()).thenAnswer((_) async => 'token');
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('reads the token once push tokens are on', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(await tokens.read(), 'token');
  });

  test('has none while push tokens are off, and asks for none', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    when(() => messaging.isAutoInitEnabled).thenReturn(false);

    expect(await tokens.read(), isNull);
    // ignore: deprecated_member_use
    verifyNever(() => messaging.getToken());
  });

  test('has none on iOS without an APNs token', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    when(() => messaging.getAPNSToken()).thenAnswer((_) async => null);

    expect(await tokens.read(), isNull);
    // ignore: deprecated_member_use
    verifyNever(() => messaging.getToken());
  });

  test('a failed read is no token', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    // ignore: deprecated_member_use
    when(() => messaging.getToken()).thenThrow(Exception('offline'));

    expect(await tokens.read(), isNull);
  });
}

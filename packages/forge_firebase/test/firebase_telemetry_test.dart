import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_firebase/forge_firebase.dart';
import 'package:mocktail/mocktail.dart';

class MockAnalytics extends Mock implements FirebaseAnalytics {}

class MockCrashlytics extends Mock implements FirebaseCrashlytics {}

void main() {
  late Directory directory;
  late MockAnalytics analytics;
  late MockCrashlytics crashlytics;

  /// What the SDKs were last told; null before anything.
  bool? collecting;

  /// The user ids Analytics and Crashlytics were last given.
  String? analyticsId;
  String? crashlyticsId;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('telemetry');
    analytics = MockAnalytics();
    crashlytics = MockCrashlytics();
    collecting = null;
    analyticsId = null;
    crashlyticsId = null;
    when(() => analytics.setAnalyticsCollectionEnabled(any())).thenAnswer(
      (call) async => collecting = call.positionalArguments.first as bool,
    );
    when(() => analytics.resetAnalyticsData()).thenAnswer((_) async {});
    when(() => analytics.setUserId(id: any(named: 'id'))).thenAnswer(
      (call) async => analyticsId = call.namedArguments[#id] as String?,
    );
    when(() => crashlytics.setUserIdentifier(any())).thenAnswer(
      (call) async => crashlyticsId = call.positionalArguments.first as String,
    );
    when(() => crashlytics.setCrashlyticsCollectionEnabled(any()))
        .thenAnswer((_) async {});
    when(() => crashlytics.deleteUnsentReports()).thenAnswer((_) async {});
  });

  tearDown(() => directory.deleteSync(recursive: true));

  FirebaseTelemetry telemetry({
    bool allowed = true,
    bool collectUnanswered = false,
  }) => FirebaseTelemetry(
    allowed: allowed,
    collectUnanswered: collectUnanswered,
    // Not created yet, as app support is on a first run.
    directory: () async => Directory('${directory.path}/support'),
    analytics: analytics,
    crashlytics: crashlytics,
  );

  /// A telemetry following [uid] that said [consent].
  Future<FirebaseTelemetry> answered(String uid, bool consent) async {
    final subject = telemetry();
    await subject.follow(uid);
    await subject.apply(uid, consent);
    return subject;
  }

  group('restore', () {
    test('collects nothing for nobody or a user never asked here', () async {
      await telemetry().restore(null);
      expect(collecting, isFalse);
      await telemetry().restore('u1');
      expect(collecting, isFalse);
    });

    test('applies only the signed-in user\'s own answer', () async {
      await answered('u1', true);
      await answered('u2', false);

      await telemetry().restore('u1');
      expect(collecting, isTrue);
      await telemetry().restore('u2');
      expect(collecting, isFalse);
      await telemetry().restore(null);
      expect(collecting, isFalse);
    });

    test('a failure is logged, never thrown, and leaves collection '
        'off', () async {
      await answered('u1', true);
      bool? crashlyticsOn;
      when(() => crashlytics.setCrashlyticsCollectionEnabled(any())).thenAnswer(
        (call) async => crashlyticsOn = call.positionalArguments.first as bool,
      );
      when(() => analytics.setAnalyticsCollectionEnabled(true))
          .thenThrow(Exception('no plugin'));
      final logged = <Object>[];
      final logError = Log.onError;
      Log.onError = (error, _, _) => logged.add(error);
      addTearDown(() => Log.onError = logError);

      await telemetry().restore('u1');

      expect(crashlyticsOn, isFalse);
      expect(collecting, isFalse);
      expect(logged, isNotEmpty);
    });
  });

  test('another user turns collection off until their answer', () async {
    final subject = await answered('u1', true);
    expect(collecting, isTrue);

    await subject.follow('u2');
    expect(collecting, isFalse);
    // The previous user's answer no longer applies.
    await subject.apply('u1', true);
    expect(collecting, isFalse);
    await subject.apply('u2', true);
    expect(collecting, isTrue);
  });

  test('following the same user again changes nothing', () async {
    final subject = await answered('u1', true);
    await subject.follow('u1');
    expect(collecting, isTrue);
  });

  test('never collects where not allowed, whatever the consent', () async {
    final subject = telemetry(allowed: false);
    await subject.follow('u1');
    await subject.apply('u1', true);
    expect(collecting, isFalse);
    verifyNever(() => crashlytics.setCrashlyticsCollectionEnabled(true));
  });

  test('of quick answers the latest wins', () async {
    final subject = telemetry();
    await subject.follow('u1');
    await Future.wait([subject.apply('u1', true), subject.apply('u1', false)]);
    expect(collecting, isFalse);
    await telemetry().restore('u1');
    expect(collecting, isFalse);
  });

  test('crash reports kept from before a yes are dropped, once', () async {
    final subject = await answered('u1', false);
    verifyNever(() => crashlytics.deleteUnsentReports());
    await subject.apply('u1', true);
    verify(() => crashlytics.deleteUnsentReports()).called(1);
    // Reports recorded with consent are left to be sent.
    await subject.apply('u1', true);
    verifyNever(() => crashlytics.deleteUnsentReports());
  });

  test('a yes that fails on the way is not saved', () async {
    when(() => crashlytics.deleteUnsentReports())
        .thenThrow(Exception('no plugin'));
    final subject = telemetry();
    await subject.follow('u1');
    expect((await subject.apply('u1', true)).isOk, isFalse);
    expect(collecting, isFalse);

    await telemetry().restore('u1');
    expect(collecting, isFalse);
  });

  test('forgetting a user stops collection and records no', () async {
    final subject = await answered('u1', true);
    expect((await subject.forget('u1')).isOk, isTrue);
    expect(collecting, isFalse);
    verify(() => analytics.resetAnalyticsData()).called(1);
    await telemetry().restore('u1');
    expect(collecting, isFalse);
  });

  test(
    'a failure is reported, not thrown, and later calls still run',
    () async {
      when(() => analytics.setAnalyticsCollectionEnabled(any()))
          .thenThrow(Exception('no plugin'));
      final subject = telemetry();
      expect((await subject.follow('u1')).isOk, isFalse);
      expect((await subject.apply('u1', false)).isOk, isFalse);
    },
  );

  group('opt-out', () {
    FirebaseTelemetry optOut() => telemetry(collectUnanswered: true);

    test('collects for a user who never answered once that is '
        'known', () async {
      final subject = optOut();
      await subject.follow('u1');
      expect(collecting, isFalse);
      await subject.apply('u1', null);
      expect(collecting, isTrue);

      await optOut().restore('u1');
      expect(collecting, isTrue);
    });

    test('collects nothing at launch for a user with no answer '
        'here', () async {
      await optOut().restore('u1');
      expect(collecting, isFalse);
    });

    test('an explicit no still wins', () async {
      final subject = optOut();
      await subject.follow('u1');
      await subject.apply('u1', false);
      expect(collecting, isFalse);
      await optOut().restore('u1');
      expect(collecting, isFalse);
    });

    test('crash reports recorded while collecting by default are '
        'kept', () async {
      final subject = optOut();
      await subject.follow('u1');
      await subject.apply('u1', null);
      verify(() => crashlytics.deleteUnsentReports()).called(1);
      await subject.apply('u1', null);
      await subject.apply('u1', true);
      verifyNever(() => crashlytics.deleteUnsentReports());
    });

    test(
      'a user who never answered is not collected for when opt-in',
      () async {
        final subject = telemetry();
        await subject.follow('u1');
        await subject.apply('u1', null);
        expect(collecting, isFalse);
        await telemetry().restore('u1');
        expect(collecting, isFalse);
      },
    );
  });

  group('user id', () {
    test('is the followed uid while collecting', () async {
      final subject = await answered('u1', true);
      expect(analyticsId, 'u1');
      expect(crashlyticsId, 'u1');

      await subject.follow('u2');
      expect(analyticsId, isNull);
      expect(crashlyticsId, isEmpty);
      await subject.apply('u2', true);
      expect(analyticsId, 'u2');

      await subject.follow(null);
      expect(analyticsId, isNull);
    });

    test('is set at launch only when collecting', () async {
      await answered('u1', true);
      await answered('u2', false);
      await telemetry().restore('u1');
      expect(analyticsId, 'u1');
      await telemetry().restore('u2');
      expect(analyticsId, isNull);
    });

    test('is never set where collection is not allowed', () async {
      final subject = telemetry(allowed: false);
      await subject.follow('u1');
      await subject.apply('u1', true);
      verifyNever(() => analytics.setUserId(id: 'u1'));
      verifyNever(() => crashlytics.setUserIdentifier('u1'));
    });

    test('is cleared on forget', () async {
      final subject = await answered('u1', true);
      await subject.forget('u1');
      expect(analyticsId, isNull);
      expect(crashlyticsId, isEmpty);
    });
  });

  group('logScreen and setUserProperty', () {
    test('forward to Analytics', () async {
      when(() => analytics.logScreenView(screenName: any(named: 'screenName')))
          .thenAnswer((_) async {});
      when(
        () => analytics.setUserProperty(
          name: any(named: 'name'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await telemetry().logScreen('today');
      await telemetry().setUserProperty('level', 'beginner');
      await telemetry().setUserProperty('level', null);

      verify(() => analytics.logScreenView(screenName: 'today')).called(1);
      verify(() => analytics.setUserProperty(name: 'level', value: 'beginner'))
          .called(1);
      verify(() => analytics.setUserProperty(name: 'level', value: null))
          .called(1);
    });

    test('a failure is swallowed', () async {
      when(() => analytics.logScreenView(screenName: any(named: 'screenName')))
          .thenThrow(Exception('no plugin'));
      when(
        () => analytics.setUserProperty(
          name: any(named: 'name'),
          value: any(named: 'value'),
        ),
      ).thenThrow(Exception('no plugin'));

      await expectLater(telemetry().logScreen('today'), completes);
      await expectLater(
        telemetry().setUserProperty('level', 'beginner'),
        completes,
      );
    });
  });

  group('logEvent', () {
    test('forwards the name and parameters to Analytics', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await telemetry().logEvent('paywall_view', {'layout': 'a'});
      await telemetry().logEvent('app_tour');

      verify(
        () => analytics.logEvent(
          name: 'paywall_view',
          parameters: {'layout': 'a'},
        ),
      ).called(1);
      verify(() => analytics.logEvent(name: 'app_tour', parameters: const {}))
          .called(1);
    });

    test('a failure is swallowed and not reported', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenThrow(Exception('no plugin'));
      final logged = <Object>[];
      final logError = Log.onError;
      Log.onError = (error, _, _) => logged.add(error);
      addTearDown(() => Log.onError = logError);

      await expectLater(telemetry().logEvent('paywall_view'), completes);
      expect(logged, isEmpty);
    });
  });

  group('while collection was off', () {
    /// Calls to Analytics that only count while it collects, as they came.
    late List<String> sent;

    setUp(() {
      sent = [];
      when(() => analytics.setAnalyticsCollectionEnabled(any())).thenAnswer((
        call,
      ) async {
        collecting = call.positionalArguments.first as bool;
        sent.add('collect $collecting');
      });
      when(() => analytics.setUserId(id: any(named: 'id'))).thenAnswer((
        call,
      ) async {
        analyticsId = call.namedArguments[#id] as String?;
        sent.add('id $analyticsId');
      });
      when(
        () => analytics.setUserProperty(
          name: any(named: 'name'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((call) async {
        sent.add(
          '${call.namedArguments[#name]} ${call.namedArguments[#value]}',
        );
      });
    });

    test('the id and the properties are sent once it starts', () async {
      final subject = telemetry(collectUnanswered: true);
      await subject.follow('u1');
      await subject.setUserProperty('level', 'beginner');
      await subject.setUserProperty('goal', null);
      sent.clear();

      await subject.apply('u1', null);

      expect(sent, [
        'collect true',
        'id u1',
        'level beginner',
        'goal null',
      ]);
    });

    test('a forgotten user leaves no properties behind', () async {
      final subject = await answered('u1', true);
      await subject.setUserProperty('level', 'beginner');
      await subject.forget('u1');
      await subject.follow('u2');
      sent.clear();

      await subject.apply('u2', true);

      expect(sent, ['collect true', 'id u2']);
    });
  });
}

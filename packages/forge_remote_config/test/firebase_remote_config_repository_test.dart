import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_remote_config/src/data/firebase_remote_config_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteConfig extends Mock implements FirebaseRemoteConfig {}

// ignore: invalid_use_of_protected_member
RemoteConfigValue value(String? raw, ValueSource source) =>
    RemoteConfigValue(raw == null ? null : utf8.encode(raw), source);

final unknown = value(null, ValueSource.valueStatic);

void main() {
  late MockRemoteConfig config;
  late FirebaseRemoteConfigRepository repository;
  late Completer<bool> fetch;

  setUpAll(() {
    registerFallbackValue(
      RemoteConfigSettings(
        fetchTimeout: Duration.zero,
        minimumFetchInterval: Duration.zero,
      ),
    );
  });

  setUp(() {
    config = MockRemoteConfig();
    fetch = Completer();
    when(() => config.setConfigSettings(any())).thenAnswer((_) async {});
    when(() => config.setDefaults(any())).thenAnswer((_) async {});
    when(() => config.ensureInitialized()).thenAnswer((_) async {});
    when(() => config.fetchAndActivate()).thenAnswer((_) => fetch.future);
    when(() => config.getValue(any())).thenReturn(unknown);
    repository = FirebaseRemoteConfigRepository(
      config,
      defaults: const {'layout': 'a', 'on': true, 'count': 3, 'ratio': 0.5},
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    );
  });

  group('initialize', () {
    test(
      'sets settings and defaults, then loads the activated values',
      () async {
        final result = await repository.initialize();

        expect(result.isOk, isTrue);
        final settings =
            verifyInOrder([
                  () => config.setConfigSettings(captureAny()),
                  () => config.setDefaults(const {
                    'layout': 'a',
                    'on': true,
                    'count': 3,
                    'ratio': 0.5,
                  }),
                  () => config.ensureInitialized(),
                  () => config.fetchAndActivate(),
                ]).first.captured.single
                as RemoteConfigSettings;
        expect(settings.fetchTimeout, const Duration(seconds: 10));
        expect(settings.minimumFetchInterval, const Duration(hours: 1));
      },
    );

    test('does not wait for the fetch', () async {
      // The fetch never completes here.
      expect((await repository.initialize()).isOk, isTrue);
    });

    test('a failed fetch never reaches the app', () async {
      expect((await repository.initialize()).isOk, isTrue);

      fetch.completeError(
        FirebaseException(plugin: 'firebase_remote_config', code: 'throttled'),
      );
      // An unhandled error here would fail the test.
      await pumpEventQueue();
    });

    test('a failed local setup is an Err, and still fetches', () async {
      when(() => config.ensureInitialized()).thenThrow(
        FirebaseException(plugin: 'firebase_remote_config', message: 'boom'),
      );

      final result = await repository.initialize();

      expect(result.failureOrNull, isA<UnknownFailure>());
      verify(() => config.fetchAndActivate()).called(1);
    });
  });

  group('reads', () {
    test('the app default stands in while the SDK has no value', () {
      expect(repository.getString('layout'), 'a');
      expect(repository.getBool('on'), isTrue);
      expect(repository.getInt('count'), 3);
      expect(repository.getDouble('ratio'), 0.5);
    });

    test('an activated or default value comes from the SDK', () {
      when(() => config.getValue('layout'))
          .thenReturn(value('b', ValueSource.valueRemote));
      when(() => config.getValue('on'))
          .thenReturn(value('false', ValueSource.valueRemote));
      when(() => config.getValue('count'))
          .thenReturn(value('7', ValueSource.valueDefault));
      when(() => config.getValue('ratio'))
          .thenReturn(value('0.25', ValueSource.valueRemote));

      expect(repository.getString('layout'), 'b');
      expect(repository.getBool('on'), isFalse);
      expect(repository.getInt('count'), 7);
      expect(repository.getDouble('ratio'), 0.25);
    });

    test('a key without a default reads as the SDK static value', () {
      expect(repository.getString('missing'), '');
      expect(repository.getBool('missing'), isFalse);
      expect(repository.getInt('missing'), 0);
      expect(repository.getDouble('missing'), 0);
    });
  });
}

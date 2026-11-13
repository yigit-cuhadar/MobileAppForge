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
RemoteConfigValue remote(String raw) =>
    RemoteConfigValue(utf8.encode(raw), ValueSource.valueRemote);

// ignore: invalid_use_of_protected_member
final unknown = RemoteConfigValue(null, ValueSource.valueStatic);

const defaults = <String, Object>{
  'layout': 'a',
  'on': true,
  'count': 3,
  'ratio': 0.5,
  'whole': 1,
  'whole_double': 2.0,
  'fraction': 1.5,
};

/// The SDK's two stores: [fetched] by `fetch`, [active] by `activate`,
/// which reads see.
void main() {
  late MockRemoteConfig config;
  late FirebaseRemoteConfigRepository repository;
  late Map<String, String> fetched;
  late Map<String, String> active;
  late Map<String, String> server;
  late Completer<void> fetch;

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
    fetched = {};
    active = {};
    server = {};
    fetch = Completer()..complete();
    when(() => config.setConfigSettings(any())).thenAnswer((_) async {});
    when(() => config.ensureInitialized()).thenAnswer((_) async {});
    when(() => config.activate()).thenAnswer((_) async {
      active = {...fetched};
      return true;
    });
    when(() => config.fetch()).thenAnswer((_) async {
      await fetch.future;
      fetched = {...server};
    });
    when(() => config.getValue(any())).thenAnswer((call) {
      final raw = active[call.positionalArguments.single as String];
      return raw == null ? unknown : remote(raw);
    });
    repository = FirebaseRemoteConfigRepository(
      config,
      defaults: defaults,
      minimumFetchInterval: const Duration(hours: 1),
    );
  });

  group('initialize', () {
    test('activates the last fetch, then fetches in the background', () async {
      final result = await repository.initialize();

      expect(result.isOk, isTrue);
      final settings =
          verifyInOrder([
                () => config.setConfigSettings(captureAny()),
                () => config.ensureInitialized(),
                () => config.activate(),
                () => config.fetch(),
              ]).first.captured.single
              as RemoteConfigSettings;
      expect(settings.minimumFetchInterval, const Duration(hours: 1));
      verifyNever(() => config.fetchAndActivate());
    });

    test(
      'values fetched in a session apply from the next initialize',
      () async {
        server['layout'] = 'b';

        await repository.initialize();
        await pumpEventQueue();
        expect(repository.getString('layout'), 'a');

        await repository.initialize();
        expect(repository.getString('layout'), 'b');
      },
    );

    test('does not wait for the fetch', () async {
      fetch = Completer();
      expect((await repository.initialize()).isOk, isTrue);
    });

    test('a failed fetch never reaches the app', () async {
      fetch = Completer();
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
      verify(() => config.fetch()).called(1);
    });
  });

  group('reads', () {
    test('a key without a server value reads the app default', () async {
      void expectDefaults() {
        expect(repository.getString('layout'), 'a');
        expect(repository.getBool('on'), isTrue);
        expect(repository.getInt('count'), 3);
        expect(repository.getDouble('ratio'), 0.5);
      }

      expectDefaults();
      await repository.initialize();
      expectDefaults();
    });

    test('a number default serves int when integral, and double', () {
      expect(repository.getDouble('whole'), 1.0);
      expect(repository.getInt('whole'), 1);
      expect(repository.getInt('whole_double'), 2);
      expect(repository.getDouble('whole_double'), 2.0);
      expect(repository.getInt('fraction'), 0);
      expect(repository.getDouble('fraction'), 1.5);
    });

    test('a server value is parsed as the SDK parses it', () {
      active = {
        'layout': 'b',
        'on': 'false',
        'count': '7',
        'ratio': '0.25',
        'whole': '7.0',
        'flag': '1',
      };

      expect(repository.getString('layout'), 'b');
      expect(repository.getBool('on'), isFalse);
      expect(repository.getInt('count'), 7);
      expect(repository.getDouble('count'), 7.0);
      expect(repository.getDouble('ratio'), 0.25);
      expect(repository.getInt('whole'), 0);
      expect(repository.getBool('flag'), isTrue);
    });

    test('a key without a value or default reads as empty', () {
      expect(repository.getString('missing'), '');
      expect(repository.getBool('missing'), isFalse);
      expect(repository.getInt('missing'), 0);
      expect(repository.getDouble('missing'), 0);
    });
  });
}

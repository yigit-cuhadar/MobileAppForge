import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:forge_app_gate/forge_app_gate.dart';
import 'package:forge_app_gate/src/data/remote_app_gate_repository.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_remote_config/forge_remote_config.dart';
import 'package:mocktail/mocktail.dart';

class MockRemoteConfig extends Mock implements RemoteConfigRepository {}

void main() {
  late FakeRemoteConfigRepository config;
  late Directory directory;
  late String installed;
  late bool storeOpens;

  RemoteAppGateRepository repository({
    String? platform = 'ios',
    RemoteConfigRepository? remote,
  }) => RemoteAppGateRepository(
    remote ?? config,
    platform: platform,
    installedVersion: () async => installed,
    directory: () async => directory,
    launchStore: () async => storeOpens,
  );

  setUp(() {
    config = FakeRemoteConfigRepository(AppGateModule.remoteConfigDefaults);
    directory = Directory.systemTemp.createTempSync('app_gate_');
    installed = '1.4.0';
    storeOpens = true;
  });

  tearDown(() => directory.deleteSync(recursive: true));

  group('rules', () {
    test('the defaults ask nothing', () {
      expect(repository().rules(), const AppGateRules());
    });

    test("reads this platform's versions only", () {
      config.values.addAll({
        'min_version_ios': '1.2',
        'recommended_version_ios': '1.5.0',
        'min_version_android': '3.0',
        'recommended_version_android': '3.1',
      });

      expect(
        repository().rules(),
        AppGateRules(
          minimum: Version.tryParse('1.2'),
          recommended: Version.tryParse('1.5'),
        ),
      );
      expect(
        repository(platform: 'android').rules(),
        AppGateRules(
          minimum: Version.tryParse('3'),
          recommended: Version.tryParse('3.1'),
        ),
      );
      expect(repository(platform: null).rules(), const AppGateRules());
    });

    test('a value that is not a version asks nothing', () {
      config.values['min_version_ios'] = 'soon';
      expect(repository().rules().minimum, isNull);
    });

    test('maintenance is one switch with an optional message', () {
      config.values.addAll({
        'maintenance': 'true',
        'maintenance_message': '  Back at 10:00 ',
      });

      expect(
        repository(platform: 'android').rules(),
        const AppGateRules(
          maintenance: true,
          maintenanceMessage: 'Back at 10:00',
        ),
      );
    });
  });

  test('refresh asks Remote Config for every gate key', () async {
    final remote = MockRemoteConfig();
    when(() => remote.refresh(any())).thenAnswer((_) async => const Ok(null));

    await repository(remote: remote).refresh();

    verify(
      () => remote.refresh(AppGateModule.remoteConfigDefaults.keys.toSet()),
    ).called(1);
  });

  group('installedVersion', () {
    test('parses the platform version', () async {
      expect(
        (await repository().installedVersion()).valueOrNull,
        Version.tryParse('1.4'),
      );
    });

    test('is an Err when it is not a version', () async {
      installed = 'dev';
      expect((await repository().installedVersion()).isOk, isFalse);
    });
  });

  group('dismissed', () {
    test('nothing is dismissed at first', () async {
      expect((await repository().loadDismissed()).valueOrNull, isNull);
    });

    test('a dismissal is kept across launches', () async {
      await repository().saveDismissed(Version.tryParse('1.5')!);

      expect(
        (await repository().loadDismissed()).valueOrNull,
        Version.tryParse('1.5'),
      );
    });

    test('reads its own save at once', () async {
      final gate = repository();
      final save = gate.saveDismissed(Version.tryParse('1.5')!);
      expect((await gate.loadDismissed()).valueOrNull, Version.tryParse('1.5'));
      await save;
    });

    test('an unreadable file reads as nothing dismissed', () async {
      File('${directory.path}/app_gate.json').writeAsStringSync('{oops');
      final result = await repository().loadDismissed();
      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });

  group('openStore', () {
    test('is Ok when the store opens', () async {
      expect((await repository().openStore()).isOk, isTrue);
    });

    test('is an Err when nothing opens it', () async {
      storeOpens = false;
      expect((await repository().openStore()).isOk, isFalse);
    });
  });
}

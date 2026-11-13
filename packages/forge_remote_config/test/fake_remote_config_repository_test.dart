import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_remote_config/forge_remote_config.dart';

void main() {
  late FakeRemoteConfigRepository repository;

  setUp(() {
    repository = FakeRemoteConfigRepository(const {
      'layout': 'a',
      'on': true,
      'count': 3,
      'ratio': 0.5,
    });
  });

  test('reads the defaults', () {
    expect(repository.getString('layout'), 'a');
    expect(repository.getBool('on'), isTrue);
    expect(repository.getInt('count'), 3);
    expect(repository.getDouble('ratio'), 0.5);
  });

  test('values override the defaults at once', () {
    repository.values
      ..['layout'] = 'b'
      ..['on'] = false;

    expect(repository.getString('layout'), 'b');
    expect(repository.getBool('on'), isFalse);
    expect(repository.getInt('count'), 3);
  });

  test('a key without a value or default reads as empty', () {
    expect(repository.getString('missing'), '');
    expect(repository.getBool('missing'), isFalse);
    expect(repository.getInt('missing'), 0);
    expect(repository.getDouble('missing'), 0);
  });

  test('initialize returns the set failure until cleared', () async {
    expect((await repository.initialize()).isOk, isTrue);

    repository.failure = const NetworkFailure();
    expect(
      (await repository.initialize()).failureOrNull,
      isA<NetworkFailure>(),
    );

    repository.failure = null;
    expect((await repository.initialize()).isOk, isTrue);
  });
}

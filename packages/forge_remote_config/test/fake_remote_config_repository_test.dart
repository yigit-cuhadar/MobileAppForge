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
      'whole': 1,
      'whole_double': 2.0,
      'fraction': 1.5,
    });
  });

  test('reads the defaults', () {
    expect(repository.getString('layout'), 'a');
    expect(repository.getBool('on'), isTrue);
    expect(repository.getInt('count'), 3);
    expect(repository.getDouble('ratio'), 0.5);
  });

  test('a number default serves int when integral, and double', () {
    expect(repository.getDouble('whole'), 1.0);
    expect(repository.getInt('whole'), 1);
    expect(repository.getInt('whole_double'), 2);
    expect(repository.getDouble('whole_double'), 2.0);
    expect(repository.getInt('fraction'), 0);
    expect(repository.getDouble('fraction'), 1.5);
  });

  test('values override the defaults at once', () {
    repository.values
      ..['layout'] = 'b'
      ..['on'] = false;

    expect(repository.getString('layout'), 'b');
    expect(repository.getBool('on'), isFalse);
    expect(repository.getInt('count'), 3);
  });

  test('server strings are parsed as Firebase parses them', () {
    repository.values.addAll({
      'on': 'false',
      'count': '7',
      'ratio': '0.25',
      'whole': '7.0',
      'flag': '1',
    });

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

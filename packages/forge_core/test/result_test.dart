import 'package:forge_core/forge_core.dart';
import 'package:test/test.dart';

void main() {
  group('guard', () {
    test('wraps a value in Ok', () async {
      final result = await guard(() async => 42);
      expect(result.valueOrNull, 42);
      expect(result.isOk, isTrue);
    });

    test('uses the mapper for thrown errors', () async {
      final result = await guard<int>(
        () async => throw const FormatException('bad'),
        mapper: (e) =>
            e is FormatException ? const ValidationFailure('bad') : null,
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('falls back to UnknownFailure when the mapper declines', () async {
      final result = await guard<int>(
        () async => throw StateError('x'),
        mapper: (_) => null,
      );
      expect(result.failureOrNull, isA<UnknownFailure>());
    });

    test('passes a thrown Failure through unchanged', () async {
      const failure = NotFoundFailure();
      final result = await guard<int>(() async => throw failure);
      expect(result.failureOrNull, same(failure));
    });

    test('reports mapped errors to Log.onError', () async {
      Object? reported;
      Log.onError = (error, _, _) => reported = error;
      addTearDown(() => Log.onError = null);
      final error = StateError('x');
      await guard<int>(() async => throw error);
      expect(reported, same(error));
    });
  });

  test('map transforms Ok and keeps Err', () {
    expect(const Ok(2).map((v) => v * 2).valueOrNull, 4);
    const Result<int> err = Err(NetworkFailure());
    expect(err.map((v) => v * 2).failureOrNull, isA<NetworkFailure>());
  });
}

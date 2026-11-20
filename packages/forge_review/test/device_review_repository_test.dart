import 'package:flutter_test/flutter_test.dart';
import 'package:forge_review/src/data/device_review_repository.dart';
import 'package:forge_review/forge_review.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockInAppReview extends Mock implements InAppReview {}

void main() {
  late _MockInAppReview review;
  late DeviceReviewRepository repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    review = _MockInAppReview();
    repository = DeviceReviewRepository(SharedPreferencesAsync(), review);
  });

  test('a device that never stored a history reads an empty one', () async {
    expect((await repository.load()).valueOrNull, const ReviewHistory());
  });

  test('keeps the history it saves', () async {
    final history = ReviewHistory(
      events: 4,
      lastEventId: 'w4',
      openDays: 3,
      lastOpenDay: DateTime(2026, 11, 20),
      askedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      askedVersion: '1.2.0',
    );

    await repository.save(history);

    expect((await repository.load()).valueOrNull, history);
  });

  test('reads the installed version', () async {
    PackageInfo.setMockInitialValues(
      appName: 'App',
      packageName: 'com.example.app',
      version: '1.2.0',
      buildNumber: '7',
      buildSignature: '',
    );

    expect((await repository.appVersion()).valueOrNull, '1.2.0');
  });

  test('asks the platform only where it has a review prompt', () async {
    when(() => review.isAvailable()).thenAnswer((_) async => false);
    await repository.requestReview();
    verifyNever(() => review.requestReview());

    when(() => review.isAvailable()).thenAnswer((_) async => true);
    when(() => review.requestReview()).thenAnswer((_) async {});
    expect((await repository.requestReview()).isOk, isTrue);
    verify(() => review.requestReview()).called(1);
  });
}

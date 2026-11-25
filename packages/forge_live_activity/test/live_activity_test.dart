import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_core/forge_core.dart';
import 'package:forge_live_activity/forge_live_activity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel('forge_live_activity');
  const pressMethods = MethodChannel('forge_live_activity/presses');
  const activity = LiveActivity();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;
  late bool? shows;
  late bool tapped;

  setUp(() {
    calls = [];
    shows = true;
    tapped = false;
    messenger.setMockMethodCallHandler(methods, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'end':
          throw PlatformException(code: 'boom');
        case 'takeTap':
          final was = tapped;
          tapped = false;
          return was;
      }
      return shows;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(methods, null));

  group('show', () {
    final staleAt = DateTime.utc(2026, 11, 11, 18, 2);

    test('sends the content as JSON with its stale date', () async {
      final result = await activity.show({
        'title': 'Item',
        'at': 1000,
        'parts': [true, false],
        'none': null,
      }, staleAt: staleAt);

      expect(result.isOk, isTrue);
      final arguments = calls.single.arguments as Map;
      expect(calls.single.method, 'show');
      expect(jsonDecode(arguments['json'] as String), {
        'title': 'Item',
        'at': 1000,
        'parts': [true, false],
        'none': null,
      });
      expect(arguments['staleAt'], staleAt.millisecondsSinceEpoch);
    });

    test('without a stale date sends none', () async {
      await activity.show({'title': 'Item'});
      expect((calls.single.arguments as Map)['staleAt'], isNull);
    });

    test('Live Activities turned off is a failure, to try again', () async {
      shows = false;
      final result = await activity.show({'title': 'Item'});
      expect(result.failureOrNull, isA<UnknownFailure>());
    });

    test('below iOS 16.2 (no answer) is no failure', () async {
      shows = null;
      expect((await activity.show({'title': 'Item'})).isOk, isTrue);
    });
  });

  test('a native failure is a failure, not a throw', () async {
    final result = await activity.end();
    expect(calls.single.method, 'end');
    expect(result.failureOrNull, isA<UnknownFailure>());
  });

  group('taps', () {
    Future<void> nativeSays(String method) => messenger.handlePlatformMessage(
      methods.name,
      methods.codec.encodeMethodCall(MethodCall(method)),
      (_) {},
    );

    test('the one that launched the app is taken on listening', () async {
      tapped = true;
      final taps = <void>[];
      final subscription = activity.taps().listen(taps.add);
      await pumpEventQueue();
      expect(taps, hasLength(1));
      expect(calls.single.method, 'takeTap');
      await subscription.cancel();
    });

    test('a later one is taken when the plugin says so, once', () async {
      final taps = <void>[];
      final subscription = activity.taps().listen(taps.add);
      await pumpEventQueue();
      expect(taps, isEmpty);

      tapped = true;
      await nativeSays('tapped');
      await nativeSays('tapped');
      await pumpEventQueue();
      expect(taps, hasLength(1));
      await subscription.cancel();
    });
  });

  group('presses', () {
    late List<String> kept;

    setUp(() {
      kept = [];
      messenger.setMockMethodCallHandler(pressMethods, (call) async {
        calls.add(call);
        final taken = kept;
        kept = [];
        return taken;
      });
    });

    tearDown(() => messenger.setMockMethodCallHandler(pressMethods, null));

    Future<void> nativeSays(Object? action) => messenger.handlePlatformMessage(
      pressMethods.name,
      pressMethods.codec.encodeMethodCall(MethodCall('press', action)),
      (_) {},
    );

    test('those pressed while the app did not run are taken on '
        'listening', () async {
      kept = ['extend', 'skip'];
      final actions = <String>[];
      final subscription = activity.presses().listen(
        (press) => actions.add(press.action),
      );
      await pumpEventQueue();
      expect(calls.single.method, 'takePresses');
      expect(actions, ['extend', 'skip']);
      await subscription.cancel();
    });

    test('later ones come as the plugin sends them', () async {
      final actions = <String>[];
      final subscription = activity.presses().listen((press) {
        actions.add(press.action);
        press.handled();
      });
      await pumpEventQueue();
      await nativeSays('shorten');
      await nativeSays(3);
      await pumpEventQueue();
      expect(actions, ['shorten']);
      await subscription.cancel();
    });

    test('the plugin is answered once the press is handled', () async {
      final presses = <LiveActivityPress>[];
      final subscription = activity.presses().listen(presses.add);
      await pumpEventQueue();
      var answered = false;
      unawaited(nativeSays('extend').then((_) => answered = true));
      await pumpEventQueue();
      expect(presses.single.action, 'extend');
      expect(answered, isFalse);
      presses.single.handled();
      await pumpEventQueue();
      expect(answered, isTrue);
      await subscription.cancel();
    });
  });
}

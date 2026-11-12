import 'package:flutter_test/flutter_test.dart';
import 'package:forge_notifications/forge_notifications.dart';

void main() {
  late NotificationTaps taps;

  setUp(() => taps = NotificationTaps());

  test('taps before anyone listens reach the first listener', () async {
    taps
      ..add('launch')
      ..add(null);
    final heard = <String?>[];

    taps.stream.listen(heard.add);
    taps.add('later');
    await pumpEventQueue();

    expect(heard, ['launch', null, 'later']);
  });

  test('a new listener replaces the old one', () async {
    final first = <String?>[];
    final second = <String?>[];
    var firstDone = false;

    taps.stream.listen(first.add, onDone: () => firstDone = true);
    taps.add('a');
    await pumpEventQueue();
    taps.stream.listen(second.add);
    taps.add('b');
    await pumpEventQueue();

    expect(first, ['a']);
    expect(firstDone, isTrue);
    expect(second, ['b']);
  });

  test('taps after a cancel wait for the next listener', () async {
    final first = <String?>[];
    final subscription = taps.stream.listen(first.add);
    await subscription.cancel();

    taps.add('while away');
    final second = <String?>[];
    taps.stream.listen(second.add);
    await pumpEventQueue();

    expect(first, isEmpty);
    expect(second, ['while away']);
  });
}

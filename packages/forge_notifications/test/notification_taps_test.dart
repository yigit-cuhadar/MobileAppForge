import 'package:flutter_test/flutter_test.dart';
import 'package:forge_notifications/forge_notifications.dart';

void main() {
  test('taps before anyone listens reach the first listener', () async {
    final taps = NotificationTaps()
      ..add('launch')
      ..add(null);
    final heard = <String?>[];

    taps.stream.listen(heard.add);
    taps.add('later');
    await pumpEventQueue();

    expect(heard, ['launch', null, 'later']);
  });
}

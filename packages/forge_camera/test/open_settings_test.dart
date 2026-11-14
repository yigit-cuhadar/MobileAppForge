import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_camera/forge_camera.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("openSettings asks the platform for the app's own settings", () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.spencerccf.app_settings/methods'),
          (call) async {
            calls.add(call);
            return null;
          },
        );

    await openSettings();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'openSettings');
    expect(calls.single.arguments, {
      'asAnotherTask': false,
      'type': 'settings',
    });
  });
}

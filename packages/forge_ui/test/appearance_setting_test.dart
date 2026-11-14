import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  testWidgets('picking a segment reports its theme mode', (tester) async {
    final picked = <ThemeMode>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Scaffold(
          body: AppearanceSetting(
            label: 'Appearance',
            lightLabel: 'Light',
            darkLabel: 'Dark',
            systemLabel: 'System',
            value: ThemeMode.system,
            onChanged: picked.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dark'));
    await tester.tap(find.text('Light'));
    expect(picked, [ThemeMode.dark, ThemeMode.light]);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(body: child),
    ),
  );

  testWidgets('a signed-in user shows initials and opens the account', (
    tester,
  ) async {
    var taps = 0;
    await pump(
      tester,
      ProfileHeader(
        initials: 'AB',
        name: 'Item title',
        detail: 'user@example.com',
        onTap: () => taps++,
      ),
    );

    expect(find.text('AB'), findsOneWidget);
    await tester.tap(find.text('Item title'));
    expect(taps, 1);
  });

  testWidgets('a guest shows the person icon instead of initials', (
    tester,
  ) async {
    await pump(
      tester,
      ProfileHeader.guest(
        name: 'Guest',
        detail: 'Create an account to keep your data',
        onTap: () {},
      ),
    );

    final icons = tester
        .widgetList<ForgeIcon>(find.byType(ForgeIcon))
        .map((i) => i.icon);
    expect(icons, contains(ForgeIcons.person));
    expect(icons, contains(ForgeIcons.chevronRight));
  });
}

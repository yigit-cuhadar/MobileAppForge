import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:forge_widgetbook/use_cases/list_row.dart';

void main() {
  testWidgets('the info hint row builds and its icon opens the sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: const Scaffold(body: Builder(builder: infoHintRow)),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('About this field'), findsOneWidget);

    await tester.tap(find.byType(ForgeIcon));
    await tester.pumpAndSettle();

    expect(find.byType(ForgeBottomSheet), findsOneWidget);
    expect(find.text('About this field'), findsOneWidget);
    expect(find.text('One line that explains the field.'), findsOneWidget);
  });
}

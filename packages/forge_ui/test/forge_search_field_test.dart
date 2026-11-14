import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  late List<String> changes;

  setUp(() => changes = []);

  Future<void> pump(
    WidgetTester tester, {
    VoidCallback? onFilters,
    int activeFilters = 0,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: ForgeSearchField(
            hint: 'Search',
            clearLabel: 'Clear',
            onChanged: changes.add,
            onFilters: onFilters,
            filtersLabel: 'Filters',
            activeFilters: activeFilters,
          ),
        ),
      ),
    ),
  );

  testWidgets('shows the clear button only while it holds text', (
    tester,
  ) async {
    await pump(tester);
    final clear = find.bySemanticsLabel('Clear');

    expect(clear, findsNothing);
    await tester.enterText(find.byType(TextField), 'query');
    await tester.pump();
    expect(changes, ['query']);
    expect(clear, findsOneWidget);

    await tester.tap(clear);
    await tester.pump();

    expect(changes, ['query', '']);
    expect(find.text('query'), findsNothing);
    expect(clear, findsNothing);
  });

  testWidgets('the filter button shows its count and calls onFilters', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, onFilters: () => taps++, activeFilters: 2);

    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Filters'));

    expect(taps, 1);
  });

  testWidgets('no filter button without onFilters', (tester) async {
    await pump(tester);

    expect(find.bySemanticsLabel('Filters'), findsNothing);
    expect(
      tester.getSize(find.byType(ForgeSearchField)).height,
      ForgeTheme.tapMin,
    );
  });
}

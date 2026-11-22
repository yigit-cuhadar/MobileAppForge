import 'package:material_ui/material_ui.dart';
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

  testWidgets('the tap-only form calls onTap and never takes the keyboard', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Scaffold(
          body: ForgeSearchField.tapOnly(hint: 'Search', onTap: () => taps++),
        ),
      ),
    );

    expect(find.byType(EditableText), findsNothing);
    expect(
      tester.getSize(find.byType(ForgeSearchField)).height,
      ForgeTheme.tapMin,
    );
    await tester.tap(find.text('Search'));
    await tester.pump();

    expect(taps, 1);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.bySemanticsLabel('Search'), findsOneWidget);
  });

  testWidgets('a page focuses the field through its focus node', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Scaffold(
          body: ForgeSearchField(
            hint: 'Search',
            clearLabel: 'Clear',
            onChanged: changes.add,
            focusNode: focus,
          ),
        ),
      ),
    );

    expect(tester.testTextInput.isVisible, isFalse);
    focus.requestFocus();
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
    final outline = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ForgeSearchField),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((outline.foregroundDecoration! as BoxDecoration).border, isNotNull);
  });

  testWidgets('draws no border of its own inside the pill', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await tester.pump();

    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
  });

  testWidgets('with a heroTag only the pill flies, easing its width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(Gap.md),
              child: ForgeSearchField.tapOnly(
                hint: 'Search',
                heroTag: 'search',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: Padding(
                        padding: const EdgeInsets.all(Gap.md),
                        child: ForgeSearchField(
                          hint: 'Search',
                          clearLabel: 'Clear',
                          onChanged: changes.add,
                          onFilters: () {},
                          filtersLabel: 'Filters',
                          heroTag: 'search',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Finder pill() => find
        .ancestor(of: find.text('Search'), matching: find.byType(Container))
        .first;
    final filter = find.byWidgetPredicate(
      (widget) => widget is ForgeIcon && widget.icon == ForgeIcons.filterList,
    );
    final start = tester.getRect(pill()).width;

    await tester.tap(find.text('Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final shuttle = pill();
    final mid = tester.getRect(shuttle).width;
    expect(filter, findsOneWidget);
    expect(find.descendant(of: shuttle, matching: filter), findsNothing);

    await tester.pumpAndSettle();
    final end = tester.getRect(find.byType(TextField)).width;
    expect(end, lessThan(start));
    expect(mid, inExclusiveRange(end, start));
  });

  testWidgets('the flying pill keeps its height while the navigator resizes', (
    tester,
  ) async {
    // A keyboard opening shrinks the navigator mid-flight.
    final height = ValueNotifier<double>(600);
    await tester.pumpWidget(
      ValueListenableBuilder(
        valueListenable: height,
        builder: (_, value, child) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: 400, height: value, child: child),
        ),
        child: MaterialApp(
          theme: ForgeTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(Gap.md),
                child: ForgeSearchField.tapOnly(
                  hint: 'Search',
                  heroTag: 'search',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: Padding(
                          padding: const EdgeInsets.all(Gap.md),
                          child: ForgeSearchField(
                            hint: 'Search',
                            clearLabel: 'Clear',
                            onChanged: changes.add,
                            heroTag: 'search',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    height.value = 300;
    await tester.pump(const Duration(milliseconds: 100));
    final shuttle = find
        .ancestor(of: find.text('Search'), matching: find.byType(Container))
        .first;
    expect(tester.getRect(shuttle).height, ForgeTheme.tapMin);
    await tester.pumpAndSettle();
  });

  testWidgets('a summary sits between the pill and the filter button', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: ForgeSearchField(
              hint: 'Search',
              clearLabel: 'Clear',
              onChanged: changes.add,
              onFilters: () {},
              filtersLabel: 'Filters',
              summary: ForgeChip(
                label: '5 filters',
                selected: true,
                showCheck: false,
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      ),
    );
    final pill = tester.getRect(find.byType(TextField));
    final chip = tester.getRect(find.byType(ForgeChip));
    final filter = tester.getRect(
      find.byWidgetPredicate(
        (widget) => widget is ForgeIcon && widget.icon == ForgeIcons.filterList,
      ),
    );
    expect(chip.left, greaterThan(pill.right));
    expect(chip.right, lessThan(filter.left));
    await tester.tap(find.text('5 filters'));
    expect(taps, 1);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: ForgeTheme.light(),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(Gap.md), child: child),
      ),
    ),
  );

  group('ForgeTextField', () {
    testWidgets('puts its unit at the end of the box', (tester) async {
      await pump(
        tester,
        ForgeTextField(
          label: 'Height',
          unit: 'cm',
          controller: TextEditingController(text: '180'),
        ),
      );

      final box = tester.getRect(find.byType(TextField));
      final unit = tester.getRect(find.text('cm'));
      expect(box.contains(unit.center), isTrue);
      // At the box's end, as ForgeNumberField's unit.
      expect(unit.left, greaterThan(box.center.dx));
    });

    testWidgets('puts the label above a 44px box', (tester) async {
      await pump(tester, const ForgeTextField(label: 'Name', hint: 'e.g. X'));

      expect(tester.getSize(find.byType(TextField)).height, 44);
      expect(
        tester.getBottomLeft(find.text('Name')).dy,
        lessThan(tester.getTopLeft(find.byType(TextField)).dy),
      );
    });

    testWidgets('shows the validator message under the box', (tester) async {
      final form = GlobalKey<FormState>();
      await pump(
        tester,
        Form(
          key: form,
          child: ForgeTextField(
            label: 'Name',
            validator: (v) => v!.isEmpty ? 'Enter a name.' : null,
          ),
        ),
      );

      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Enter a name.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Enter a name.')).dy,
        greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
      );

      await tester.enterText(find.byType(TextField), 'Item name');
      expect(form.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('Enter a name.'), findsNothing);
    });

    testWidgets('Form.reset clears the text and the message', (tester) async {
      final form = GlobalKey<FormState>();
      await pump(
        tester,
        Form(
          key: form,
          child: ForgeTextField(
            label: 'Name',
            validator: (v) => v!.length < 3 ? 'Too short.' : null,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'ab');
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Too short.'), findsOneWidget);

      form.currentState!.reset();
      await tester.pump();

      expect(find.text('ab'), findsNothing);
      expect(find.text('Too short.'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('a disabled field takes no input', (tester) async {
      await pump(tester, const ForgeTextField(label: 'Email', enabled: false));

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('the note form grows from one line to three, then stops', (
      tester,
    ) async {
      await pump(tester, const ForgeTextField(label: 'Note', multiline: true));
      double height() => tester.getSize(find.byType(TextField)).height;

      expect(height(), 44);
      await tester.enterText(find.byType(TextField), 'One\nTwo');
      await tester.pump();
      final two = height();
      expect(two, greaterThan(44));
      await tester.enterText(find.byType(TextField), 'One\nTwo\nThree');
      await tester.pump();
      final three = height();
      expect(three, greaterThan(two));
      await tester.enterText(
        find.byType(TextField),
        'One\nTwo\nThree\nFour\nFive',
      );
      await tester.pump();
      expect(height(), three);
    });

    testWidgets('input stops at maxLength with no counter', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(
        tester,
        ForgeTextField(
          label: 'Note',
          multiline: true,
          maxLength: 5,
          controller: controller,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Item title');
      await tester.pump();

      expect(controller.text, 'Item ');
      expect(find.textContaining('/5'), findsNothing);
      expect(tester.getSize(find.byType(TextField)).height, 44);
    });

    testWidgets('a caller-set error shows and goes as the caller changes it', (
      tester,
    ) async {
      final changes = <String>[];
      Widget field(String? error) => ForgeTextField(
        label: 'Count',
        errorText: error,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: changes.add,
      );
      await pump(tester, field('Enter a number'));
      final colors = ForgeStyle.of(tester.element(find.byType(TextField)))
          .colors;

      expect(find.text('Enter a number'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Count')).style!.color,
        colors.danger,
      );

      await tester.enterText(find.byType(TextField), '1a2');
      expect(changes, ['12']);
      expect(find.text('12'), findsOneWidget);

      await pump(tester, field(null));
      expect(find.text('Enter a number'), findsNothing);
    });

    testWidgets('the tap-only form looks like the field and calls onTap', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        Column(
          children: [
            const ForgeTextField(label: 'Typed', hint: 'Hint'),
            ForgeTextField.tapOnly(
              label: 'Picked',
              value: '[VALUE]',
              onTap: () => taps++,
            ),
          ],
        ),
      );
      final box = find.byType(InputDecorator).last;

      expect(find.byType(EditableText), findsOneWidget);
      expect(
        tester.getSize(box).height,
        tester.getSize(find.byType(TextField)).height,
      );
      expect(find.text('[VALUE]'), findsOneWidget);

      await tester.tap(find.text('[VALUE]'));
      await tester.pump();
      expect(taps, 1);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(
        tester.getSemantics(find.text('Picked')),
        matchesSemantics(
          isButton: true,
          hasTapAction: true,
          label: 'Picked\n[VALUE]',
        ),
      );
    });

    testWidgets('the tap-only form shows the hint until there is a value', (
      tester,
    ) async {
      await pump(
        tester,
        ForgeTextField.tapOnly(
          label: 'Picked',
          value: null,
          hint: 'Pick one',
          onTap: () {},
        ),
      );

      expect(find.text('Pick one'), findsOneWidget);
    });

    testWidgets('autofocus raises the keyboard as a dialog opens', (
      tester,
    ) async {
      await pump(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showForgeDialog<void>(
              context: context,
              builder: (_) => const ForgeDialog(
                title: 'Item title',
                message: 'One line.',
                field: ForgeTextField(label: 'Name', autofocus: true),
                action: SizedBox(),
                cancel: SizedBox(),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      );
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.testTextInput.isVisible, isTrue);
    });

    testWidgets('reads the label out with the field', (tester) async {
      await pump(tester, const ForgeTextField(label: 'Name'));

      expect(find.bySemanticsLabel('Name'), findsOneWidget);
    });
  });

  group('ForgeNumberField', () {
    testWidgets('is a 96×36 box that reports what is typed', (tester) async {
      final changes = <String>[];
      await pump(
        tester,
        Align(
          alignment: Alignment.topRight,
          child: ForgeNumberField(
            label: 'Field one',
            unit: 'kg',
            onChanged: changes.add,
          ),
        ),
      );

      expect(
        tester.getSize(
          find
              .descendant(
                of: find.byType(ForgeNumberField),
                matching: find.byType(Container),
              )
              .first,
        ),
        ForgeNumberField.size,
      );
      expect(find.text('kg'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Field one')), findsOneWidget);
      await tester.enterText(find.byType(TextField), '36.5');

      expect(changes, ['36.5']);
    });

    testWidgets('a pair of boxes, each with its side small at its start, '
        'reports each side', (tester) async {
      final left = <String>[];
      final right = <String>[];
      await pump(
        tester,
        ListRowCard(
          children: [
            ListRow(
              title: 'Item title',
              error: 'Enter both sides.',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: Gap.sm,
                children: [
                  // One-letter sides: the test font draws every glyph a
                  // full em wide.
                  ForgeNumberField(
                    label: 'Item title',
                    side: 'L',
                    unit: 'cm',
                    onChanged: left.add,
                  ),
                  ForgeNumberField(
                    label: 'Item title',
                    side: 'R',
                    unit: 'cm',
                    onChanged: right.add,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      expect(tester.takeException(), isNull);
      final leftBox = tester.getRect(find.byType(ForgeNumberField).first);
      expect(
        tester.getRect(find.text('L')).left,
        lessThan(tester.getRect(find.byType(EditableText).first).left),
      );
      expect(leftBox.contains(tester.getCenter(find.text('L'))), isTrue);
      expect(find.text('cm'), findsNWidgets(2));
      expect(find.text('Enter both sides.'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Item title, L')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Item title, R')), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '36.5');
      await tester.enterText(find.byType(TextField).last, '36');
      expect(left, ['36.5']);
      expect(right, ['36']);
    });

    testWidgets('takes taps across a 44px band', (tester) async {
      await pump(
        tester,
        Align(
          alignment: Alignment.topRight,
          child: ForgeNumberField(
            label: 'Field one',
            unit: 'kg',
            onChanged: (_) {},
          ),
        ),
      );
      final band = tester.getRect(find.byType(ForgeNumberField));
      expect(band.height, ForgeTheme.tapMin);

      await tester.tapAt(Offset(band.center.dx, band.top + 1));
      await tester.pump();

      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('the compact form is a unit-free 34px box of its width, the '
        'value at its end', (tester) async {
      final changes = <String>[];
      await pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: ForgeNumberField.compact(
            label: 'Field one',
            width: 70,
            onChanged: changes.add,
          ),
        ),
      );

      expect(
        tester.getSize(
          find
              .descendant(
                of: find.byType(ForgeNumberField),
                matching: find.byType(Container),
              )
              .first,
        ),
        const Size(70, ForgeNumberField.compactHeight),
      );
      expect(
        tester.getSize(find.byType(ForgeNumberField)).height,
        ForgeTheme.tapMin,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).textAlign,
        TextAlign.end,
      );
      // The one text is the empty box's dash: no unit.
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '82.5');

      expect(changes, ['82.5']);
    });

    testWidgets('the tall form is a unit-free 40px box of its width, the '
        'value at its start', (tester) async {
      final changes = <String>[];
      await pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: ForgeNumberField.tall(
            label: 'Field one',
            width: 70,
            onChanged: changes.add,
          ),
        ),
      );

      expect(
        tester.getSize(
          find
              .descendant(
                of: find.byType(ForgeNumberField),
                matching: find.byType(Container),
              )
              .first,
        ),
        const Size(70, ForgeNumberField.tallHeight),
      );
      expect(
        tester.getSize(find.byType(ForgeNumberField)).height,
        ForgeTheme.tapMin,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).textAlign,
        TextAlign.start,
      );
      // The one text is the empty box's dash: no unit.
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '82.5');

      expect(changes, ['82.5']);
    });

    testWidgets('an invalid tall box has a danger border, also while '
        'typing', (tester) async {
      Future<void> pumpField({required bool invalid}) => pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: ForgeNumberField.tall(
            label: 'Field one',
            width: 70,
            onChanged: (_) {},
            invalid: invalid,
          ),
        ),
      );
      Border border() =>
          (tester
                          .widget<Container>(
                            find
                                .descendant(
                                  of: find.byType(ForgeNumberField),
                                  matching: find.byType(Container),
                                )
                                .first,
                          )
                          .decoration!
                      as BoxDecoration)
                  .border!
              as Border;

      await pumpField(invalid: false);
      final colors = ForgeStyle.of(
        tester.element(find.byType(ForgeNumberField)),
      ).colors;
      expect(border().top, BorderSide(color: colors.lineStrong));

      await pumpField(invalid: true);
      expect(border().top, BorderSide(color: colors.danger, width: 1.5));
      await tester.tap(find.byType(ForgeNumberField));
      await tester.pump();
      expect(border().top, BorderSide(color: colors.danger, width: 1.5));
    });
  });

  testWidgets('an empty error marks the field without a line under it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(),
        home: const Scaffold(
          body: ForgeTextField(label: 'Feet', errorText: ''),
        ),
      ),
    );

    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    expect(decoration.enabledBorder, isA<OutlineInputBorder>());
    expect(
      (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
      ForgeTheme.light().extension<ForgeStyle>()!.colors.danger,
    );
    expect(find.byType(Text), findsOneWidget); // the label only
  });
}

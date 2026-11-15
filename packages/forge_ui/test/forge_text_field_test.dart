import 'package:flutter/material.dart';
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

    testWidgets('the compact form is a unit-free 34px box of its width', (
      tester,
    ) async {
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
      // The one text is the empty box's dash: no unit.
      expect(find.byType(Text), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '82.5');

      expect(changes, ['82.5']);
    });
  });
}

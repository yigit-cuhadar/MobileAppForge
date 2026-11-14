import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light().copyWith(platform: platform),
        home: Scaffold(body: Center(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ForgeSwitch', () {
    testWidgets('reports the flipped value when tapped', (tester) async {
      final changes = <bool>[];
      await pump(tester, ForgeSwitch(value: false, onChanged: changes.add));

      await tester.tap(find.byType(ForgeSwitch));

      expect(changes, [true]);
      expect(
        tester.getSemantics(find.byType(ForgeSwitch)),
        matchesSemantics(
          hasToggledState: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('reads as disabled without onChanged', (tester) async {
      await pump(tester, const ForgeSwitch(value: true, onChanged: null));

      expect(
        tester.getSemantics(find.byType(ForgeSwitch)),
        matchesSemantics(
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
        ),
      );
    });

    testWidgets('takes the platform size: 52×32 on Android, 50×30 on iOS', (
      tester,
    ) async {
      Size track() => tester.getSize(
        find
            .descendant(
              of: find.byType(ForgeSwitch),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );

      await pump(tester, ForgeSwitch(value: true, onChanged: (_) {}));
      expect(track(), const Size(52, 32));
      expect(
        tester.getSize(find.byType(ForgeSwitch)).height,
        ForgeTheme.tapMin,
      );

      await pump(
        tester,
        ForgeSwitch(value: true, onChanged: (_) {}),
        platform: TargetPlatform.iOS,
      );
      expect(track(), const Size(50, 30));
    });
  });

  group('ForgeCheckbox', () {
    testWidgets('reports the flipped value across a 44px target', (
      tester,
    ) async {
      final changes = <bool>[];
      await pump(tester, ForgeCheckbox(value: true, onChanged: changes.add));
      final target = tester.getRect(find.byType(ForgeCheckbox));

      expect(target.size, const Size.square(ForgeTheme.tapMin));
      await tester.tapAt(target.topLeft + const Offset(2, 2));

      expect(changes, [false]);
      expect(
        tester.getSemantics(find.byType(ForgeCheckbox)),
        matchesSemantics(
          hasCheckedState: true,
          isChecked: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('is square on Android and round on iOS', (tester) async {
      BorderRadiusGeometry? radius() =>
          (tester
                      .widget<Container>(
                        find.descendant(
                          of: find.byType(ForgeCheckbox),
                          matching: find.byType(Container),
                        ),
                      )
                      .decoration!
                  as BoxDecoration)
              .borderRadius;

      await pump(tester, ForgeCheckbox(value: false, onChanged: (_) {}));
      expect(radius(), BorderRadius.circular(6));

      await pump(
        tester,
        ForgeCheckbox(value: false, onChanged: (_) {}),
        platform: TargetPlatform.iOS,
      );
      expect(radius(), BorderRadius.circular(ForgeCheckbox.size / 2));
    });
  });
}

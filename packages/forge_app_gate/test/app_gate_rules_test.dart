import 'package:flutter_test/flutter_test.dart';
import 'package:forge_app_gate/forge_app_gate.dart';

Version v(String text) => Version.tryParse(text)!;

void main() {
  group('Version', () {
    test('parses dotted numbers and ignores build and pre-release', () {
      expect(v('1.4.2').parts, [1, 4, 2]);
      expect(v(' 2.0 ').parts, [2, 0]);
      expect(v('1.4.2+17').parts, [1, 4, 2]);
      expect(v('1.4.2-beta').parts, [1, 4, 2]);
    });

    test('anything else is not a version', () {
      for (final text in ['', ' ', 'v1.2', '1..2', '1.x', 'latest']) {
        expect(Version.tryParse(text), isNull, reason: text);
      }
    });

    test('compares part by part, numerically', () {
      expect(v('1.9.0') < v('1.10.0'), isTrue);
      expect(v('1.10.0') < v('1.9.0'), isFalse);
      expect(v('1.2.3') < v('2.0'), isTrue);
      expect(v('2') < v('1.99.99'), isFalse);
      expect(v('1.4.2').compareTo(v('1.4.2')), 0);
    });

    test('missing parts are zeros', () {
      expect(v('1.4'), v('1.4.0'));
      expect(v('1.4').compareTo(v('1.4.0')), 0);
      expect(v('1.4') < v('1.4.1'), isTrue);
      expect(v('1.4'), isNot(v('1.4.1')));
    });
  });

  group('AppGateRules.statusFor', () {
    const installed = Version([1, 4, 0]);

    test('nothing set leaves the app open', () {
      expect(const AppGateRules().statusFor(installed), const AppOpen());
    });

    test('below the minimum requires the update', () {
      expect(
        AppGateRules(minimum: v('1.5')).statusFor(installed),
        const UpdateRequired(),
      );
    });

    test('at or above the minimum is open', () {
      expect(
        AppGateRules(minimum: v('1.4')).statusFor(installed),
        const AppOpen(),
      );
      expect(
        AppGateRules(minimum: v('1.3.9')).statusFor(installed),
        const AppOpen(),
      );
    });

    test('below the recommended version offers it', () {
      expect(
        AppGateRules(
          minimum: v('1.0'),
          recommended: v('1.6'),
        ).statusFor(installed),
        UpdateRecommended(v('1.6')),
      );
    });

    test('the minimum wins over the recommended version', () {
      expect(
        AppGateRules(
          minimum: v('1.5'),
          recommended: v('1.6'),
        ).statusFor(installed),
        const UpdateRequired(),
      );
    });

    test('a dismissed offer stays away until another version is '
        'recommended', () {
      final rules = AppGateRules(recommended: v('1.6'));
      expect(
        rules.statusFor(installed, dismissed: v('1.6.0')),
        const AppOpen(),
      );
      expect(
        AppGateRules(recommended: v('1.7'))
            .statusFor(installed, dismissed: v('1.6')),
        UpdateRecommended(v('1.7')),
      );
    });

    test('at the recommended version is open', () {
      expect(
        AppGateRules(recommended: v('1.4.0')).statusFor(installed),
        const AppOpen(),
      );
    });

    test('maintenance closes the app whatever the version', () {
      final rules = AppGateRules(
        minimum: v('9'),
        maintenance: true,
        maintenanceMessage: 'Back at 10:00',
      );
      expect(rules.statusFor(installed), const Maintenance('Back at 10:00'));
      expect(rules.statusFor(null), const Maintenance('Back at 10:00'));
    });

    test('an unknown installed version is never closed by a version', () {
      expect(
        AppGateRules(minimum: v('9'), recommended: v('9')).statusFor(null),
        const AppOpen(),
      );
    });
  });
}

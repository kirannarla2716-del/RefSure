import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/core/utils/test_data_seeder.dart';

void main() {
  group('DemoModePolicy', () {
    test('enables automatic demo data in debug builds', () {
      expect(
        DemoModePolicy.evaluate(
          isDebugBuild: true,
          explicitDemoMode: false,
        ),
        isTrue,
      );
    });

    test('enables automatic demo data for an explicit demo build', () {
      expect(
        DemoModePolicy.evaluate(
          isDebugBuild: false,
          explicitDemoMode: true,
        ),
        isTrue,
      );
    });

    test('disables automatic demo data in a normal release build', () {
      expect(
        DemoModePolicy.evaluate(
          isDebugBuild: false,
          explicitDemoMode: false,
        ),
        isFalse,
      );
    });
  });
}

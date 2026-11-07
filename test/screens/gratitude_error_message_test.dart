import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/screens/main_screens.dart';

void main() {
  group('gratitudeErrorMessage', () {
    test('distinguishes duplicate, ineligible, and wrong-role outcomes', () {
      expect(
        gratitudeErrorMessage('already-exists'),
        'You have already thanked this referrer.',
      );
      expect(
        gratitudeErrorMessage('failed-precondition'),
        contains('completes a referral'),
      );
      expect(
        gratitudeErrorMessage('permission-denied'),
        contains('Only job seekers'),
      );
      expect(
        gratitudeErrorMessage('FAILED_PRECONDITION'),
        contains('completes a referral'),
      );
    });

    test('uses service detail for an operational failure', () {
      expect(
        gratitudeErrorMessage('unavailable', serviceMessage: 'Try later.'),
        'Try later.',
      );
    });

    test('uses a retryable fallback when no service detail is available', () {
      expect(
        gratitudeErrorMessage('service-error'),
        contains('Please try again'),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/providers/app_provider.dart';

void main() {
  test('allows unavailable callable fallback only for seeded demo jobs', () {
    expect(
      shouldUseDemoReferralFallback(
        demoMode: true,
        jobId: 'seed_job_001',
        errorCode: 'not-found',
      ),
      isTrue,
    );
    expect(
      shouldUseDemoReferralFallback(
        demoMode: false,
        jobId: 'seed_job_001',
        errorCode: 'not-found',
      ),
      isFalse,
    );
    expect(
      shouldUseDemoReferralFallback(
        demoMode: true,
        jobId: 'production-job',
        errorCode: 'not-found',
      ),
      isFalse,
    );
    expect(
      shouldUseDemoReferralFallback(
        demoMode: true,
        jobId: 'seed_job_001',
        errorCode: 'permission-denied',
      ),
      isFalse,
    );
  });
}

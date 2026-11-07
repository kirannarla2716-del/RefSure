import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/services/trusted_application_service.dart';

class _FakeTransport implements TrustedApplicationTransport {
  _FakeTransport({this.response, this.error});

  final Map<String, dynamic>? response;
  final Exception? error;
  String? functionName;
  Map<String, dynamic>? data;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    this.functionName = functionName;
    this.data = data;
    if (error != null) throw error!;
    return response!;
  }
}

void main() {
  test('transition command IDs are stable for retries', () {
    final first = trustedTransitionCommandId(
      applicationId: 'app-1',
      expectedVersion: 3,
      toStatus: AppStatus.shortlisted,
    );
    final retry = trustedTransitionCommandId(
      applicationId: 'app-1',
      expectedVersion: 3,
      toStatus: AppStatus.shortlisted,
    );
    expect(first, retry);
    expect(first, 'transition:app-1:3:shortlisted');
  });

  test('transition command IDs change with command semantics', () {
    final baseline = trustedTransitionCommandId(
      applicationId: 'app-1',
      expectedVersion: 3,
      toStatus: AppStatus.shortlisted,
    );
    expect(
      trustedTransitionCommandId(
        applicationId: 'app-1',
        expectedVersion: 4,
        toStatus: AppStatus.shortlisted,
      ),
      isNot(baseline),
    );
  });

  test('submission uses callable transport and sends only jobId', () async {
    final transport = _FakeTransport(
      response: {
        'applicationId': 'app-1',
        'status': 'pending',
        'version': 1,
        'idempotent': false,
      },
    );
    final service = TrustedApplicationService(transport: transport);
    final result = await service.submitApplication(jobId: 'job-1');
    expect(transport.functionName, 'submitApplication');
    expect(transport.data, {'jobId': 'job-1'});
    expect(result.applicationId, 'app-1');
    expect(result.version, 1);
  });

  test('transition includes stable command and expected version', () async {
    final transport = _FakeTransport(
      response: {
        'applicationId': 'app-1',
        'status': 'shortlisted',
        'version': 4,
        'idempotent': false,
      },
    );
    final service = TrustedApplicationService(transport: transport);
    await service.transitionApplication(
      applicationId: 'app-1',
      expectedVersion: 3,
      toStatus: AppStatus.shortlisted,
      note: 'Proceed',
    );
    expect(transport.functionName, 'transitionApplication');
    expect(transport.data, {
      'applicationId': 'app-1',
      'commandId': 'transition:app-1:3:shortlisted',
      'expectedVersion': 3,
      'toStatus': 'shortlisted',
      'note': 'Proceed',
    });
  });

  test('referred transition includes the referral receipt reference', () async {
    final transport = _FakeTransport(
      response: {
        'applicationId': 'app-1',
        'status': 'referred',
        'version': 5,
        'idempotent': false,
      },
    );
    final service = TrustedApplicationService(transport: transport);
    await service.transitionApplication(
      applicationId: 'app-1',
      expectedVersion: 4,
      toStatus: AppStatus.referred,
      receiptReference: 'REF-2026-001',
    );
    expect(transport.data?['receiptReference'], 'REF-2026-001');
  });

  test('transport failures remain trusted exceptions', () async {
    final service = TrustedApplicationService(
      transport: _FakeTransport(
        error: const TrustedApplicationException(
          code: 'unavailable',
          message: 'Offline',
        ),
      ),
    );
    expect(
      () => service.submitApplication(jobId: 'job-1'),
      throwsA(
        isA<TrustedApplicationException>()
            .having((error) => error.code, 'code', 'unavailable'),
      ),
    );
  });
}

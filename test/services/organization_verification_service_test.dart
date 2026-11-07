import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/services/organization_verification_service.dart';

class _FakeTransport implements OrganizationVerificationTransport {
  _FakeTransport(this.handler);

  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  ) handler;

  @override
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data,
  ) =>
      handler(name, data);
}

void main() {
  test('never exposes an internal transport message', () async {
    final service = OrganizationVerificationService(
      transport: _FakeTransport((_, __) async {
        throw const OrganizationVerificationTransportException(
          'internal',
          'internal',
        );
      }),
    );

    final result = await service.requestCode(email: 'person@company.com');

    expect(result.success, isFalse);
    expect(
        result.error, 'Organization verification is temporarily unavailable.');
    expect(result.error, isNot(contains('internal')));
  });

  test('maps callable error codes to safe actionable copy', () async {
    final service = OrganizationVerificationService(
      transport: _FakeTransport((_, __) async => {
            'success': false,
            'error': 'resource_exhausted',
          }),
    );

    final result = await service.verifyCode(
      challengeId: 'challenge-1',
      email: 'person@company.com',
      code: '123456',
    );

    expect(
      result.error,
      'Too many verification attempts. Please wait before trying again.',
    );
  });

  test('redacts arbitrary backend error text', () async {
    final service = OrganizationVerificationService(
      transport: _FakeTransport((_, __) async => {
            'success': false,
            'error': 'Database connection string leaked',
            'message': 'internal',
          }),
    );

    final result = await service.requestCode(email: 'person@company.com');

    expect(
        result.error, 'Organization verification is temporarily unavailable.');
    expect(result.message, isNull);
  });
}

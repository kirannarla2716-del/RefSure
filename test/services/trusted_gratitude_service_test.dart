import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/services/trusted_gratitude_service.dart';

class _FakeTransport implements TrustedGratitudeTransport {
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
  test('gratitude uses callable transport with provider and message', () async {
    final transport = _FakeTransport(
      response: {
        'gratitudeId': 'gratitude-1',
        'idempotent': true,
      },
    );
    final service = TrustedGratitudeService(transport: transport);

    final result = await service.sendGratitude(
      providerId: 'referrer-1',
      message: 'Thank you',
    );

    expect(transport.functionName, 'sendGratitude');
    expect(transport.data, {
      'providerId': 'referrer-1',
      'message': 'Thank you',
    });
    expect(result.gratitudeId, 'gratitude-1');
    expect(result.idempotent, isTrue);
  });

  test('missing gratitude ID is rejected', () async {
    final service = TrustedGratitudeService(
      transport: _FakeTransport(response: {'idempotent': false}),
    );

    expect(
      () => service.sendGratitude(providerId: 'referrer-1', message: 'Thanks'),
      throwsA(
        isA<TrustedGratitudeException>()
            .having((error) => error.code, 'code', 'invalid-response'),
      ),
    );
  });

  test('transport errors preserve trusted gratitude semantics', () async {
    final service = TrustedGratitudeService(
      transport: _FakeTransport(
        error: const TrustedGratitudeException('already-exists', 'Sent'),
      ),
    );

    expect(
      () => service.sendGratitude(providerId: 'referrer-1', message: 'Thanks'),
      throwsA(
        isA<TrustedGratitudeException>()
            .having((error) => error.code, 'code', 'already-exists'),
      ),
    );
  });
}

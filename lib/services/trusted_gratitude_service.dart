// ignore_for_file: one_member_abstracts

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class TrustedGratitudeResult {
  const TrustedGratitudeResult({
    required this.gratitudeId,
    required this.idempotent,
  });

  final String gratitudeId;
  final bool idempotent;
}

class TrustedGratitudeException implements Exception {
  const TrustedGratitudeException(this.code, this.message, [this.details]);

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'TrustedGratitudeException($code): $message';
}

abstract interface class TrustedGratitudeTransport {
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  );
}

class FirebaseTrustedGratitudeTransport implements TrustedGratitudeTransport {
  FirebaseTrustedGratitudeTransport({
    FirebaseFunctions? functions,
    bool useEmulator = const bool.fromEnvironment('USE_FIREBASE_EMULATORS'),
  }) : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1') {
    if (useEmulator && functions == null) {
      _functions.useFunctionsEmulator(kIsWeb ? 'localhost' : '127.0.0.1', 5001);
    }
  }

  final FirebaseFunctions _functions;

  @override
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _functions
          .httpsCallable(functionName)
          .call<Map<Object?, Object?>>(data);
      return Map<String, dynamic>.from(response.data);
    } on FirebaseFunctionsException catch (error) {
      throw TrustedGratitudeException(
        error.code,
        error.message ?? 'Sending gratitude failed.',
        error.details,
      );
    } on Object catch (error) {
      throw TrustedGratitudeException(
        'network',
        'Could not reach the gratitude service.',
        error.toString(),
      );
    }
  }
}

class TrustedGratitudeService {
  TrustedGratitudeService({
    TrustedGratitudeTransport? transport,
  }) : _transport = transport ?? FirebaseTrustedGratitudeTransport();

  final TrustedGratitudeTransport _transport;

  Future<TrustedGratitudeResult> sendGratitude({
    required String providerId,
    required String message,
  }) async {
    final result = await _transport.call('sendGratitude', {
      'providerId': providerId,
      'message': message,
    });
    final gratitudeId = result['gratitudeId']?.toString() ?? '';
    if (gratitudeId.isEmpty) {
      throw const TrustedGratitudeException(
        'invalid-response',
        'The gratitude result is incomplete.',
      );
    }
    return TrustedGratitudeResult(
      gratitudeId: gratitudeId,
      idempotent: result['idempotent'] == true,
    );
  }

  void dispose() {}
}

// ignore_for_file: one_member_abstracts

import 'package:cloud_functions/cloud_functions.dart';
import 'package:refsure/core/enums/enums.dart';

class TrustedApplicationResult {
  const TrustedApplicationResult({
    required this.applicationId,
    required this.status,
    required this.version,
    required this.idempotent,
  });

  final String applicationId;
  final AppStatus status;
  final int version;
  final bool idempotent;
}

String trustedTransitionCommandId({
  required String applicationId,
  required int expectedVersion,
  required AppStatus toStatus,
}) =>
    'transition:$applicationId:$expectedVersion:${toStatus.name}';

class TrustedApplicationException implements Exception {
  const TrustedApplicationException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'TrustedApplicationException($code): $message';
}

abstract interface class TrustedApplicationTransport {
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  );
}

class FirebaseTrustedApplicationTransport
    implements TrustedApplicationTransport {
  FirebaseTrustedApplicationTransport({
    FirebaseFunctions? functions,
    bool useEmulator = const bool.fromEnvironment(
      'USE_FIREBASE_EMULATORS',
    ),
  }) : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1') {
    if (useEmulator && functions == null) {
      _functions.useFunctionsEmulator('127.0.0.1', 5001);
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
      throw TrustedApplicationException(
        code: error.code,
        message: error.message ?? 'Application command failed.',
        details: error.details,
      );
    } on Object catch (error) {
      throw TrustedApplicationException(
        code: 'network',
        message: 'Could not reach the referral service. Please try again.',
        details: error.toString(),
      );
    }
  }
}

class TrustedApplicationService {
  TrustedApplicationService({
    TrustedApplicationTransport? transport,
  }) : _transport = transport ?? FirebaseTrustedApplicationTransport();

  final TrustedApplicationTransport _transport;

  Future<TrustedApplicationResult> submitApplication({
    required String jobId,
  }) =>
      _call('submitApplication', {'jobId': jobId});

  Future<TrustedApplicationResult> transitionApplication({
    required String applicationId,
    required int expectedVersion,
    required AppStatus toStatus,
    String? note,
    String? receiptReference,
    String? commandId,
  }) =>
      _call(
        'transitionApplication',
        {
          'applicationId': applicationId,
          'commandId': commandId ??
              trustedTransitionCommandId(
                applicationId: applicationId,
                expectedVersion: expectedVersion,
                toStatus: toStatus,
              ),
          'expectedVersion': expectedVersion,
          'toStatus': toStatus.name,
          if (note != null) 'note': note,
          if (receiptReference != null) 'receiptReference': receiptReference,
        },
      );

  Future<TrustedApplicationResult> _call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final result = await _transport.call(functionName, data);
    final statusName = result['status']?.toString();
    final status = AppStatus.values
        .where((candidate) => candidate.name == statusName)
        .firstOrNull;
    final applicationId = result['applicationId']?.toString() ?? '';
    final version = result['version'];
    if (status == null ||
        applicationId.isEmpty ||
        version is! int ||
        version < 1) {
      throw const TrustedApplicationException(
        code: 'invalid-response',
        message: 'The trusted command result is incomplete.',
      );
    }
    return TrustedApplicationResult(
      applicationId: applicationId,
      status: status,
      version: version,
      idempotent: result['idempotent'] == true,
    );
  }
}

// ignore_for_file: one_member_abstracts

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:refsure/core/models/safety_report.dart';

class TrustedSafetyException implements Exception {
  const TrustedSafetyException(this.code, this.message, [this.details]);

  final String code;
  final String message;
  final Object? details;
}

abstract interface class TrustedSafetyTransport {
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  );
}

class FirebaseTrustedSafetyTransport implements TrustedSafetyTransport {
  FirebaseTrustedSafetyTransport({
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
      throw TrustedSafetyException(
        error.code,
        error.message ?? 'Could not submit the safety report.',
        error.details,
      );
    } on Object catch (error) {
      throw TrustedSafetyException(
        'network',
        'Could not reach the safety service.',
        error.toString(),
      );
    }
  }
}

class TrustedSafetyService {
  TrustedSafetyService({TrustedSafetyTransport? transport})
      : _transport = transport ?? FirebaseTrustedSafetyTransport();

  final TrustedSafetyTransport _transport;

  Future<String> reportUser({
    required String targetId,
    required String category,
    required String details,
    String? contextId,
  }) async {
    final commandId = 'report:${DateTime.now().microsecondsSinceEpoch}';
    final result = await _transport.call('reportUser', {
      'targetId': targetId,
      'category': category,
      'details': details,
      'commandId': commandId,
      if (contextId != null) 'contextId': contextId,
    });
    final reportId = result['reportId']?.toString() ?? '';
    if (reportId.isEmpty) {
      throw const TrustedSafetyException(
        'invalid-response',
        'The safety report result is incomplete.',
      );
    }
    return reportId;
  }

  Future<List<SafetyReport>> listReports({String status = 'open'}) async {
    final result = await _transport.call('adminListSafetyReports', {
      'status': status,
    });
    final rows = result['reports'];
    if (rows is! List) {
      throw const TrustedSafetyException(
        'invalid-response',
        'The moderation queue response is incomplete.',
      );
    }
    return rows
        .whereType<Map<Object?, Object?>>()
        .map((row) => SafetyReport.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> reviewReport({
    required String reportId,
    required String decision,
    required String note,
  }) async {
    await _transport.call('adminReviewSafetyReport', {
      'reportId': reportId,
      'decision': decision,
      'note': note,
      'commandId': 'moderation:${DateTime.now().microsecondsSinceEpoch}',
    });
  }

  void dispose() {}
}

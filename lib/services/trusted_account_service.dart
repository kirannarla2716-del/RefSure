// ignore_for_file: one_member_abstracts

import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/admin_user.dart';

class TrustedRoleChangeResult {
  const TrustedRoleChangeResult({
    required this.role,
    required this.idempotent,
  });

  final UserRole role;
  final bool idempotent;
}

class TrustedPrivacyRequestResult {
  const TrustedPrivacyRequestResult({
    required this.requestId,
    required this.status,
    required this.idempotent,
  });

  final String requestId;
  final String status;
  final bool idempotent;
}

class TrustedAccountException implements Exception {
  const TrustedAccountException(this.code, this.message, [this.details]);

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => 'TrustedAccountException($code): $message';
}

abstract interface class TrustedAccountTransport {
  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
  );
}

class FirebaseTrustedAccountTransport implements TrustedAccountTransport {
  FirebaseTrustedAccountTransport({
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
      throw TrustedAccountException(
        error.code,
        error.message ?? 'Role change failed.',
        error.details,
      );
    } on Object catch (error) {
      throw TrustedAccountException(
        'network',
        'Could not reach the account service.',
        error.toString(),
      );
    }
  }
}

class TrustedAccountService {
  TrustedAccountService({
    TrustedAccountTransport? transport,
  }) : _transport = transport ?? FirebaseTrustedAccountTransport();

  final TrustedAccountTransport _transport;

  Future<TrustedRoleChangeResult> changeRole(
    UserRole role, {
    String? commandId,
  }) async {
    final result = await _transport.call('changeRole', {
      'role': role.name,
      'commandId': commandId ?? _newCommandId('role-${role.name}'),
    });
    final roleName = result['role']?.toString();
    final confirmedRole = UserRole.values
        .where((candidate) => candidate.name == roleName)
        .firstOrNull;
    if (confirmedRole == null) {
      throw const TrustedAccountException(
        'invalid-response',
        'The role change result is incomplete.',
      );
    }
    return TrustedRoleChangeResult(
      role: confirmedRole,
      idempotent: result['idempotent'] == true,
    );
  }

  Future<List<AdminUser>> listAdminUsers() async {
    final result = await _transport.call('adminListUsers', const {});
    final rows = result['users'];
    if (rows is! List) {
      throw const TrustedAccountException(
        'invalid-response',
        'The admin user list is incomplete.',
      );
    }
    return rows
        .whereType<Map<Object?, Object?>>()
        .map((row) => AdminUser.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<TrustedPrivacyRequestResult> requestPrivacyAction(String type) async {
    final result = await _transport.call('requestPrivacy', {
      'type': type,
      'commandId': _newCommandId('privacy-$type'),
    });
    final requestId = result['requestId']?.toString() ?? '';
    final status = result['status']?.toString() ?? '';
    if (requestId.isEmpty || status.isEmpty) {
      throw const TrustedAccountException(
        'invalid-response',
        'The privacy request result is incomplete.',
      );
    }
    return TrustedPrivacyRequestResult(
      requestId: requestId,
      status: status,
      idempotent: result['idempotent'] == true,
    );
  }

  Future<void> updateAdminUser({
    required String userId,
    required String action,
    List<String> additionalAccess = const [],
    String? exceptionReason,
    DateTime? exceptionUntil,
    String? commandId,
  }) async {
    await _transport.call('adminManageUser', {
      'userId': userId,
      'action': action,
      'additionalAccess': additionalAccess,
      if (exceptionReason != null) 'exceptionReason': exceptionReason,
      if (exceptionUntil != null)
        'exceptionUntil': exceptionUntil.toUtc().toIso8601String(),
      'commandId': commandId ?? _newCommandId('admin-$action'),
    });
  }

  static String _newCommandId(String prefix) {
    final random = Random.secure();
    final entropy = List<int>.generate(16, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$entropy';
  }

  void dispose() {}
}

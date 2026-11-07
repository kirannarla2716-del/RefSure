// ignore_for_file: one_member_abstracts

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Callable-compatible transport. A Firebase Functions implementation can map
/// [call] directly to `FirebaseFunctions.instance.httpsCallable(name).call`.
abstract interface class OrganizationVerificationTransport {
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data,
  );
}

class UnconfiguredOrganizationVerificationTransport
    implements OrganizationVerificationTransport {
  const UnconfiguredOrganizationVerificationTransport();

  @override
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data,
  ) {
    throw StateError('Organization verification backend is not configured.');
  }
}

class FirebaseOrganizationVerificationTransport
    implements OrganizationVerificationTransport {
  FirebaseOrganizationVerificationTransport({
    FirebaseFunctions? functions,
    bool useEmulator = const bool.fromEnvironment(
      'USE_FIREBASE_EMULATORS',
    ),
    this.enableAppCheck = const bool.fromEnvironment(
      'ENABLE_FIREBASE_APP_CHECK',
    ),
  }) : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-central1') {
    if (useEmulator && functions == null) {
      _functions.useFunctionsEmulator(kIsWeb ? 'localhost' : '127.0.0.1', 5001);
    }
  }

  final FirebaseFunctions _functions;
  final bool enableAppCheck;
  static Future<void>? _appCheckInitialization;

  Future<void> _ensureAppCheck() {
    if (!enableAppCheck) {
      return Future<void>.value();
    }
    return _appCheckInitialization ??= FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(
        const String.fromEnvironment('FIREBASE_APP_CHECK_WEB_KEY'),
      ),
      appleProvider: AppleProvider.appAttest,
    );
  }

  @override
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data,
  ) async {
    try {
      await _ensureAppCheck();
      final result = await _functions
          .httpsCallable(name)
          .call<Map<Object?, Object?>>(data);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw OrganizationVerificationTransportException(
        error.code,
        error.message ?? 'Organization verification failed.',
      );
    }
  }
}

class OrganizationVerificationService {
  OrganizationVerificationService({
    OrganizationVerificationTransport? transport,
  }) : _transport = transport ?? FirebaseOrganizationVerificationTransport();

  static OrganizationVerificationService shared =
      OrganizationVerificationService();

  final OrganizationVerificationTransport _transport;

  Future<OrganizationCodeRequestResult> requestCode({
    required String email,
  }) async {
    try {
      final response = await _transport.call(
        'requestOrganizationVerification',
        {'email': email.trim()},
      );
      return OrganizationCodeRequestResult(
        success: response['success'] == true,
        challengeId: response['challengeId'] as String?,
        domain: response['domain'] as String?,
        message: response['success'] == true
            ? response['message'] as String? ??
                'Verification code sent. Check your work inbox.'
            : null,
        error: response['success'] == true
            ? null
            : _safeBackendError(response['error']),
      );
    } catch (error) {
      return OrganizationCodeRequestResult(
        success: false,
        error: _safeError(error),
      );
    }
  }

  Future<OrganizationCodeVerifyResult> verifyCode({
    required String challengeId,
    required String email,
    required String code,
  }) async {
    try {
      final response = await _transport.call(
        'verifyOrganizationVerification',
        {
          'challengeId': challengeId,
          'email': email.trim(),
          'code': code.trim(),
        },
      );
      return OrganizationCodeVerifyResult(
        success: response['success'] == true,
        domain: response['domain'] as String?,
        companyName: response['companyName'] as String?,
        error: response['success'] == true
            ? null
            : _safeBackendError(response['error']),
      );
    } catch (error) {
      return OrganizationCodeVerifyResult(
        success: false,
        error: _safeError(error),
      );
    }
  }

  String _safeError(Object error) {
    if (error is OrganizationVerificationTransportException) {
      return _safeBackendError(error.code);
    }
    return 'Organization verification is temporarily unavailable.';
  }

  String _safeBackendError(Object? value) {
    final code = value?.toString().trim().toLowerCase().replaceAll('_', '-');
    return switch (code) {
      'invalid-argument' =>
        'Enter a valid organization email and verification code.',
      'permission-denied' =>
        'This organization email cannot be verified for your account.',
      'not-found' =>
        'That verification request was not found. Request a new code.',
      'already-exists' => 'This organization email is already verified.',
      'failed-precondition' =>
        'This verification request is no longer valid. Request a new code.',
      'resource-exhausted' =>
        'Too many verification attempts. Please wait before trying again.',
      'unauthenticated' => 'Sign in again to verify your organization email.',
      _ => 'Organization verification is temporarily unavailable.',
    };
  }
}

class OrganizationVerificationTransportException implements Exception {
  const OrganizationVerificationTransportException(this.code, this.message);

  final String code;
  final String message;
}

class OrganizationCodeRequestResult {
  const OrganizationCodeRequestResult({
    required this.success,
    this.challengeId,
    this.domain,
    this.message,
    this.error,
  });

  final bool success;
  final String? challengeId;
  final String? domain;
  final String? message;
  final String? error;
}

class OrganizationCodeVerifyResult {
  const OrganizationCodeVerifyResult({
    required this.success,
    this.domain,
    this.companyName,
    this.error,
  });

  final bool success;
  final String? domain;
  final String? companyName;
  final String? error;
}

class OrganizationEmailValidator {
  const OrganizationEmailValidator._();

  static const _personalDomains = {
    'aol.com',
    'gmail.com',
    'hotmail.com',
    'icloud.com',
    'mail.com',
    'outlook.com',
    'proton.me',
    'protonmail.com',
    'yahoo.com',
  };

  static final _emailPattern = RegExp(
    r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r'(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',
  );

  static bool isOrganizationEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final domain = extractDomain(normalized);
    return normalized.length <= 254 &&
        _emailPattern.hasMatch(normalized) &&
        domain != null &&
        !_personalDomains.contains(domain);
  }

  static String? extractDomain(String email) {
    final normalized = email.trim().toLowerCase();
    final at = normalized.lastIndexOf('@');
    if (at <= 0 || at == normalized.length - 1) {
      return null;
    }
    return normalized.substring(at + 1);
  }

  static String? extractCompanyName(String email) {
    if (!isOrganizationEmail(email)) {
      return null;
    }
    final label = extractDomain(email)!.split('.').first;
    return label
        .split('-')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

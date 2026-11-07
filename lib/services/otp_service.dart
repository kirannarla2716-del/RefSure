import 'package:refsure/services/organization_verification_service.dart';

/// Backward-compatible facade used by the existing provider and UI.
///
/// OTP generation, storage, comparison, and verification now happen only in
/// trusted backend code through [OrganizationVerificationService].
class OtpService {
  OtpService({OrganizationVerificationService? verificationService})
      : _verification =
            verificationService ?? OrganizationVerificationService.shared;

  final OrganizationVerificationService _verification;
  String? _challengeId;

  bool isOrgEmail(String email) =>
      OrganizationEmailValidator.isOrganizationEmail(email);

  String? extractDomain(String email) =>
      OrganizationEmailValidator.extractDomain(email);

  String? extractCompanyName(String email) =>
      OrganizationEmailValidator.extractCompanyName(email);

  Future<OtpSendResult> sendOtp({
    required String userId,
    required String email,
  }) async {
    final result = await _verification.requestCode(email: email);
    if (result.success) {
      _challengeId = result.challengeId;
    }
    return OtpSendResult(
      success: result.success,
      message: result.message,
      error: result.error,
      domain: result.domain,
    );
  }

  Future<OtpVerifyResult> verifyOtp({
    required String userId,
    required String email,
    required String enteredOtp,
  }) async {
    final challengeId = _challengeId;
    if (challengeId == null) {
      return OtpVerifyResult(
        success: false,
        error: 'No pending OTP found. Please request a new one.',
      );
    }
    final result = await _verification.verifyCode(
      challengeId: challengeId,
      email: email,
      code: enteredOtp,
    );
    if (result.success) {
      _challengeId = null;
    }
    return OtpVerifyResult(
      success: result.success,
      error: result.error,
      companyName: result.companyName,
      domain: result.domain,
    );
  }
}

class OtpSendResult {
  OtpSendResult({
    required this.success,
    this.message,
    this.error,
    this.domain,
  });

  final bool success;
  final String? message;
  final String? error;
  final String? domain;
}

class OtpVerifyResult {
  OtpVerifyResult({
    required this.success,
    this.error,
    this.companyName,
    this.domain,
  });

  final bool success;
  final String? error;
  final String? companyName;
  final String? domain;
}

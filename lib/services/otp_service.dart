// lib/services/otp_service.dart
// Organisation email OTP verification.
//
// HOW IT WORKS (production setup):
// 1. User enters their work email (e.g., kiran@google.com)
// 2. We generate a 6-digit OTP and store it in Firestore /otp_verifications
// 3. A Firebase Cloud Function (deploy from /functions/sendOtp.js) reads this
//    doc and sends the OTP via email (SendGrid / Firebase Email Extension)
// 4. User enters the OTP → we verify → mark orgVerified = true
//
// For local testing: OTP is logged to the console (search "OTP_DEBUG").
// Deploy /functions/ to enable actual email sending.

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class OtpService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference get _otps => _db.collection('otp_verifications');

  static const _otpExpiryMinutes = 10;
  static const _freeEmailDomains = [
    'gmail.com','yahoo.com','hotmail.com','outlook.com',
    'icloud.com','aol.com','mail.com','protonmail.com',
  ];

  // ── Validate org email ────────────────────────────────────

  bool isOrgEmail(String email) {
    final domain = email.split('@').last.toLowerCase();
    return !_freeEmailDomains.contains(domain);
  }

  String? extractDomain(String email) {
    final parts = email.split('@');
    return parts.length == 2 ? parts.last.toLowerCase() : null;
  }

  String? extractCompanyName(String email) {
    final domain = extractDomain(email);
    if (domain == null) return null;
    final parts = domain.split('.');
    if (parts.isEmpty) return null;
    final name = parts.first;
    return name[0].toUpperCase() + name.substring(1);
  }

  // ── Generate & store OTP ──────────────────────────────────

  Future<OtpSendResult> sendOtp({
    required String userId,
    required String email,
  }) async {
    if (!isOrgEmail(email)) {
      return OtpSendResult(
        success: false,
        error: 'Please use your work/organisation email (not Gmail, Yahoo, etc.)');
    }

    final otp = _generateOtp();
    final expires = DateTime.now().add(const Duration(minutes: _otpExpiryMinutes));

    // Delete any existing OTPs for this user
    final existing = await _otps.where('userId', isEqualTo: userId).get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }

    // Store new OTP
    final record = OtpRecord(
      id: '', email: email, otp: otp,
      userId: userId, expiresAt: expires, verified: false);

    await _otps.add(record.toFirestore());

    // In production, a Cloud Function triggers on this Firestore write
    // and sends the email. For dev, log to console:
    // ignore: avoid_print
    print('[OTP_DEBUG] OTP for $email: $otp (expires in ${_otpExpiryMinutes}m)');

    return OtpSendResult(
      success: true,
      message: 'OTP sent to $email. Check your work inbox.',
      domain: extractDomain(email));
  }

  // ── Verify OTP ────────────────────────────────────────────

  Future<OtpVerifyResult> verifyOtp({
    required String userId,
    required String email,
    required String enteredOtp,
  }) async {
    final snap = await _otps
        .where('userId', isEqualTo: userId)
        .where('email', isEqualTo: email)
        .where('verified', isEqualTo: false)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return OtpVerifyResult(success: false, error: 'No pending OTP found. Please request a new one.');
    }

    final record = OtpRecord.fromFirestore(snap.docs.first);

    if (record.isExpired) {
      await snap.docs.first.reference.delete();
      return OtpVerifyResult(success: false, error: 'OTP expired. Please request a new one.');
    }

    if (record.otp != enteredOtp.trim()) {
      return OtpVerifyResult(success: false, error: 'Incorrect OTP. Please try again.');
    }

    // Mark as verified in Firestore
    await snap.docs.first.reference.update({'verified': true});

    return OtpVerifyResult(
      success: true,
      companyName: extractCompanyName(email),
      domain: extractDomain(email));
  }

  // ── Private ───────────────────────────────────────────────

  String _generateOtp() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }
}

class OtpSendResult {
  final bool success;
  final String? message;
  final String? error;
  final String? domain;
  OtpSendResult({required this.success, this.message, this.error, this.domain});
}

class OtpVerifyResult {
  final bool success;
  final String? error;
  final String? companyName;
  final String? domain;
  OtpVerifyResult({required this.success, this.error, this.companyName, this.domain});
}

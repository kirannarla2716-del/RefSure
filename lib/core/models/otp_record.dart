// ignore_for_file: argument_type_not_assignable, sort_constructors_first, require_trailing_commas

import 'package:cloud_firestore/cloud_firestore.dart';

class OtpRecord {
  final String id;
  final String email;
  final String otp;
  final String userId;
  final DateTime expiresAt;
  final bool verified;

  OtpRecord({
    required this.id, required this.email, required this.otp,
    required this.userId, required this.expiresAt, this.verified = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toFirestore() => {
    'email': email, 'otp': otp, 'userId': userId,
    'expiresAt': Timestamp.fromDate(expiresAt), 'verified': verified,
  };

  factory OtpRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OtpRecord(
      id: doc.id, email: d['email'] ?? '', otp: d['otp'] ?? '',
      userId: d['userId'] ?? '',
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verified: d['verified'] ?? false,
    );
  }
}

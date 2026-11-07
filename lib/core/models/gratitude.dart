// ignore_for_file: argument_type_not_assignable, sort_constructors_first, require_trailing_commas

import 'package:cloud_firestore/cloud_firestore.dart';

/// A "thank you" sent from a Job Seeker to a Referrer.
///
/// Stored in the `gratitudes` collection. The referrer's `gratitudesReceived`
/// counter is incremented atomically alongside each new gratitude.
class Gratitude {
  final String id;
  final String fromSeekerId;
  final String fromSeekerName;
  final String toReferrerId;
  final String message;
  final DateTime createdAt;

  Gratitude({
    required this.id,
    required this.fromSeekerId,
    required this.fromSeekerName,
    required this.toReferrerId,
    required this.message,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'fromSeekerId':   fromSeekerId,
    'fromSeekerName': fromSeekerName,
    'toReferrerId':   toReferrerId,
    'message':        message,
    'createdAt':      Timestamp.fromDate(createdAt),
  };

  factory Gratitude.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Gratitude(
      id:             doc.id,
      fromSeekerId:   d['fromSeekerId'] ?? '',
      fromSeekerName: d['fromSeekerName'] ?? '',
      toReferrerId:   d['toReferrerId'] ?? '',
      message:        d['message'] ?? '',
      createdAt:      (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

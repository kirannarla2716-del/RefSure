// ignore_for_file: argument_type_not_assignable, sort_constructors_first, require_trailing_commas

import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String text;
  final bool read;
  final DateTime createdAt;
  final String? actionRoute;

  AppNotification({
    required this.id, required this.userId, required this.type,
    required this.text, this.read = false, DateTime? createdAt,
    this.actionRoute,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'userId': userId, 'type': type, 'text': text, 'read': read,
    'createdAt': Timestamp.fromDate(createdAt), 'actionRoute': actionRoute,
  };

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id, userId: d['userId'] ?? '', type: d['type'] ?? 'info',
      text: d['text'] ?? '', read: d['read'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      actionRoute: d['actionRoute'],
    );
  }
}

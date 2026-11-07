// ignore_for_file: argument_type_not_assignable, sort_constructors_first, require_trailing_commas

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final DateTime sentAt;
  final bool read;

  Message({
    required this.id, required this.fromId, required this.toId,
    required this.text, DateTime? sentAt, this.read = false,
  }) : sentAt = sentAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'fromId': fromId, 'toId': toId, 'text': text,
    'sentAt': Timestamp.fromDate(sentAt), 'read': read,
  };

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id, fromId: d['fromId'] ?? '', toId: d['toId'] ?? '',
      text: d['text'] ?? '', sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      read: d['read'] ?? false,
    );
  }
}

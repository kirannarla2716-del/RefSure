// ignore_for_file: require_trailing_commas

import 'package:refsure/core/models/message.dart';
import 'package:refsure/services/firestore_service.dart';

class MessagingRepository {
  MessagingRepository(this._db);
  final FirestoreService _db;

  Stream<List<Message>> watchConversation(String myId, String otherId) =>
      _db.watchConversation(myId, otherId);

  Future<void> sendMessage(Message message) => _db.sendMessage(message);
}

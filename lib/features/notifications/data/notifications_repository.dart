// ignore_for_file: require_trailing_commas

import 'package:refsure/core/models/notification.dart';
import 'package:refsure/services/firestore_service.dart';

class NotificationsRepository {
  NotificationsRepository(this._db);
  final FirestoreService _db;

  Stream<List<AppNotification>> watchNotifications(String uid) =>
      _db.watchNotifications(uid);

  Future<void> markAllRead(String uid) => _db.markAllNotifsRead(uid);

  Future<void> markRead(String id) => _db.markNotifRead(id);
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/core/models/notification.dart';
import 'package:refsure/features/notifications/data/notifications_repository.dart';
import 'package:refsure/features/notifications/presentation/cubit/notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required NotificationsRepository notificationsRepository,
  })  : _repository = notificationsRepository,
        super(const NotificationsInitial());

  final NotificationsRepository _repository;
  StreamSubscription<List<AppNotification>>? _notifsSub;

  void loadNotifications(String uid) {
    _notifsSub?.cancel();
    _notifsSub = _repository.watchNotifications(uid).listen(
      (notifs) {
        final unread = notifs.where((n) => !n.read).length;
        emit(NotificationsLoaded(
          notifications: notifs,
          unreadCount: unread,
        ));
      },
      onError: (Object error) {
        emit(NotificationsError(error.toString()));
      },
    );
  }

  Future<void> markAllRead(String uid) async {
    await _repository.markAllRead(uid);
  }

  Future<void> markRead(String id) async {
    await _repository.markRead(id);
  }

  @override
  Future<void> close() {
    _notifsSub?.cancel();
    return super.close();
  }
}

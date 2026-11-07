import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refsure/core/models/notification.dart';
import 'package:refsure/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:refsure/features/notifications/presentation/cubit/notifications_state.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockNotificationsRepository mockNotificationsRepository;

  setUp(() {
    mockNotificationsRepository = MockNotificationsRepository();
  });

  final readNotification = AppNotification(
    id: 'notif-1',
    userId: 'uid-1',
    type: 'info',
    text: 'Your profile was viewed',
    read: true,
  );

  final unreadNotification = AppNotification(
    id: 'notif-2',
    userId: 'uid-1',
    type: 'application',
    text: 'New application received',
  );

  final unreadNotification2 = AppNotification(
    id: 'notif-3',
    userId: 'uid-1',
    type: 'match',
    text: 'New match found',
  );

  group('Feature: Notifications', () {
    // -- Scenario: Load Notifications --------------------------------------
    group('Scenario: User loads their notifications', () {
      blocTest<NotificationsCubit, NotificationsState>(
        'Given notifications exist with some unread, '
        'When loadNotifications is called, '
        'Then it should emit [NotificationsLoaded] with correct unread count',
        build: () {
          when(() => mockNotificationsRepository.watchNotifications(any()))
              .thenAnswer(
            (_) => Stream.value([
              readNotification,
              unreadNotification,
              unreadNotification2,
            ]),
          );
          return NotificationsCubit(
            notificationsRepository: mockNotificationsRepository,
          );
        },
        act: (cubit) => cubit.loadNotifications('uid-1'),
        expect: () => [
          isA<NotificationsLoaded>()
              .having(
                (s) => s.notifications.length,
                'notifications count',
                3,
              )
              .having(
                (s) => s.unreadCount,
                'unread count',
                2,
              ),
        ],
      );

      blocTest<NotificationsCubit, NotificationsState>(
        'Given no notifications exist, '
        'When loadNotifications is called, '
        'Then it should emit [NotificationsLoaded] with empty list',
        build: () {
          when(() => mockNotificationsRepository.watchNotifications(any()))
              .thenAnswer((_) => Stream.value([]));
          return NotificationsCubit(
            notificationsRepository: mockNotificationsRepository,
          );
        },
        act: (cubit) => cubit.loadNotifications('uid-1'),
        expect: () => [
          isA<NotificationsLoaded>()
              .having(
                (s) => s.notifications.isEmpty,
                'notifications is empty',
                true,
              )
              .having(
                (s) => s.unreadCount,
                'unread count',
                0,
              ),
        ],
      );

      blocTest<NotificationsCubit, NotificationsState>(
        'Given the notifications stream errors, '
        'When loadNotifications is called, '
        'Then it should emit [NotificationsError]',
        build: () {
          when(() => mockNotificationsRepository.watchNotifications(any()))
              .thenAnswer((_) => Stream.error(Exception('Connection lost')));
          return NotificationsCubit(
            notificationsRepository: mockNotificationsRepository,
          );
        },
        act: (cubit) => cubit.loadNotifications('uid-1'),
        expect: () => [
          isA<NotificationsError>().having(
            (s) => s.message,
            'message',
            contains('Connection lost'),
          ),
        ],
      );
    });

    // -- Scenario: Mark All Read -------------------------------------------
    group('Scenario: User marks all notifications as read', () {
      blocTest<NotificationsCubit, NotificationsState>(
        'Given unread notifications exist, '
        'When markAllRead is called, '
        'Then it should call repository.markAllRead',
        build: () {
          when(() => mockNotificationsRepository.markAllRead(any()))
              .thenAnswer((_) async {});
          return NotificationsCubit(
            notificationsRepository: mockNotificationsRepository,
          );
        },
        act: (cubit) => cubit.markAllRead('uid-1'),
        verify: (_) {
          verify(
            () => mockNotificationsRepository.markAllRead('uid-1'),
          ).called(1);
        },
      );
    });

    // -- Scenario: Mark Single Read ----------------------------------------
    group('Scenario: User marks a single notification as read', () {
      blocTest<NotificationsCubit, NotificationsState>(
        'Given an unread notification, '
        'When markRead is called, '
        'Then it should call repository.markRead',
        build: () {
          when(() => mockNotificationsRepository.markRead(any()))
              .thenAnswer((_) async {});
          return NotificationsCubit(
            notificationsRepository: mockNotificationsRepository,
          );
        },
        act: (cubit) => cubit.markRead('notif-2'),
        verify: (_) {
          verify(
            () => mockNotificationsRepository.markRead('notif-2'),
          ).called(1);
        },
      );
    });
  });
}

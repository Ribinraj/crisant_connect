import 'package:crisant_connect/features/notifications/models/notifications_response.dart';
import 'package:crisant_connect/features/notifications/notifications_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepo notificationsRepo;

  NotificationsBloc({required this.notificationsRepo})
    : super(const NotificationsInitial()) {
    on<FetchNotificationsRequested>(_onFetchNotificationsRequested);
    on<FetchUnreadCountRequested>(_onFetchUnreadCountRequested);
    on<MarkNotificationReadRequested>(_onMarkNotificationReadRequested);
  }

  Future<void> _onFetchNotificationsRequested(
    FetchNotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(
      NotificationsLoading(
        notifications: state.notifications,
        unreadCount: state.unreadCount,
        readingNotificationId: state.readingNotificationId,
      ),
    );

    final result = await notificationsRepo.getNotifications();

    if (result.status == 200 && result.data != null) {
      emit(
        NotificationsLoaded(
          message: result.message,
          notifications: result.data!.notifications,
          unreadCount: state.unreadCount,
        ),
      );

      if (event.includeUnreadCount) {
        add(FetchUnreadCountRequested());
      }
      return;
    }

    emit(
      NotificationsFailure(
        message: result.message,
        status: result.status,
        notifications: state.notifications,
        unreadCount: state.unreadCount,
      ),
    );
  }

  Future<void> _onFetchUnreadCountRequested(
    FetchUnreadCountRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await notificationsRepo.getUnreadCount();

    if (result.status == 200 && result.data != null) {
      emit(
        NotificationsUnreadCountLoaded(
          unreadCount: result.data!.unreadCount,
          notifications: state.notifications,
        ),
      );
      return;
    }

    emit(
      NotificationsFailure(
        message: result.message,
        status: result.status,
        notifications: state.notifications,
        unreadCount: state.unreadCount,
      ),
    );
  }

  Future<void> _onMarkNotificationReadRequested(
    MarkNotificationReadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final currentNotifications = state.notifications;
    final target = currentNotifications
        .where((notification) => notification.id == event.notificationId)
        .firstOrNull;

    if (target == null || target.isRead) return;

    emit(
      NotificationReadInProgress(
        notificationId: event.notificationId,
        notifications: currentNotifications,
        unreadCount: state.unreadCount,
      ),
    );

    final result = await notificationsRepo.markAsRead(event.notificationId);

    if (!result.error && result.data?.ok == true) {
      final updatedNotifications = currentNotifications
          .map(
            (notification) => notification.id == event.notificationId
                ? notification.copyWith(isRead: true)
                : notification,
          )
          .toList();
      final nextUnreadCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;

      emit(
        NotificationReadSuccess(
          message: result.message,
          notificationId: event.notificationId,
          notifications: updatedNotifications,
          unreadCount: nextUnreadCount,
        ),
      );
      add(FetchUnreadCountRequested());
      return;
    }

    emit(
      NotificationsFailure(
        message: result.message,
        status: result.status,
        notifications: currentNotifications,
        unreadCount: state.unreadCount,
      ),
    );
  }
}

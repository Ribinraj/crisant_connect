part of 'notifications_bloc.dart';

@immutable
sealed class NotificationsState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final int? readingNotificationId;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.readingNotificationId,
  });
}

final class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading({
    super.notifications,
    super.unreadCount,
    super.readingNotificationId,
  });
}

final class NotificationsLoaded extends NotificationsState {
  final String message;

  const NotificationsLoaded({
    required this.message,
    required super.notifications,
    required super.unreadCount,
  });
}

final class NotificationsUnreadCountLoaded extends NotificationsState {
  const NotificationsUnreadCountLoaded({
    required super.unreadCount,
    super.notifications,
  });
}

final class NotificationReadInProgress extends NotificationsState {
  final int notificationId;

  const NotificationReadInProgress({
    required this.notificationId,
    required super.notifications,
    required super.unreadCount,
  }) : super(readingNotificationId: notificationId);
}

final class NotificationReadSuccess extends NotificationsState {
  final String message;
  final int notificationId;

  const NotificationReadSuccess({
    required this.message,
    required this.notificationId,
    required super.notifications,
    required super.unreadCount,
  });
}

final class NotificationsFailure extends NotificationsState {
  final String message;
  final int status;

  const NotificationsFailure({
    required this.message,
    required this.status,
    super.notifications,
    super.unreadCount,
  });
}

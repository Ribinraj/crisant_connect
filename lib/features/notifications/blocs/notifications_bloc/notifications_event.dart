part of 'notifications_bloc.dart';

@immutable
sealed class NotificationsEvent {}

final class FetchNotificationsRequested extends NotificationsEvent {
  final bool includeUnreadCount;

  FetchNotificationsRequested({this.includeUnreadCount = true});
}

final class FetchUnreadCountRequested extends NotificationsEvent {}

final class MarkNotificationReadRequested extends NotificationsEvent {
  final int notificationId;

  MarkNotificationReadRequested({required this.notificationId});
}

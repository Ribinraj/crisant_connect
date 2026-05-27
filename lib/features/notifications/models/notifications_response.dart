class NotificationsResponse {
  final List<AppNotification> notifications;

  const NotificationsResponse({required this.notifications});

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final rawNotifications = json['notifications'];

    return NotificationsResponse(
      notifications: rawNotifications is List
          ? rawNotifications
                .whereType<Map<String, dynamic>>()
                .map(AppNotification.fromJson)
                .toList()
          : const [],
    );
  }
}

class UnreadCountResponse {
  final int unreadCount;

  const UnreadCountResponse({required this.unreadCount});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(unreadCount: _readInt(json['unreadCount']));
  }
}

class MarkNotificationReadResponse {
  final bool ok;

  const MarkNotificationReadResponse({required this.ok});

  factory MarkNotificationReadResponse.fromJson(Map<String, dynamic> json) {
    return MarkNotificationReadResponse(ok: json['ok'] == true);
  }
}

class AppNotification {
  final int id;
  final int clientId;
  final int userId;
  final String type;
  final String title;
  final String body;
  final int? relatedPostId;
  final bool isRead;
  final DateTime? createdAt;
  final String createdAtText;
  final String clientName;

  const AppNotification({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.relatedPostId,
    required this.isRead,
    required this.createdAt,
    required this.createdAtText,
    required this.clientName,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final createdAtText = json['created_at']?.toString() ?? '';

    return AppNotification(
      id: _readInt(json['id']),
      clientId: _readInt(json['client_id']),
      userId: _readInt(json['user_id']),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      relatedPostId: _readNullableInt(json['related_post_id']),
      isRead: _readInt(json['is_read']) == 1 || json['is_read'] == true,
      createdAt: _parseDateTime(createdAtText),
      createdAtText: createdAtText,
      clientName: json['client_name']?.toString() ?? '',
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      clientId: clientId,
      userId: userId,
      type: type,
      title: title,
      body: body,
      relatedPostId: relatedPostId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      createdAtText: createdAtText,
      clientName: clientName,
    );
  }
}

int _readInt(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _parseDateTime(String value) {
  if (value.isEmpty) return null;
  return DateTime.tryParse(value) ??
      DateTime.tryParse(value.replaceFirst(' ', 'T'));
}

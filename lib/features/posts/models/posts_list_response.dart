import 'dart:convert';

class PostsListResponse {
  final List<PostListItem> posts;

  const PostsListResponse({required this.posts});

  factory PostsListResponse.fromJson(Map<String, dynamic> json) {
    final rawPosts = json['posts'];
    return PostsListResponse(
      posts: rawPosts is List
          ? rawPosts
                .whereType<Map<String, dynamic>>()
                .map(PostListItem.fromJson)
                .toList()
          : const [],
    );
  }
}

class PostListItem {
  final int id;
  final int clientId;
  final String title;
  final String caption;
  final DateTime? scheduledFor;
  final String contentType;
  final String mediaKind;
  final String mediaSource;
  final String mediaUrl;
  final String approvalStatus;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final String clientName;
  final String createdByName;
  final String approvedByName;
  final String effectiveStatus;
  final List<PostTarget> targets;
  final List<PostMediaItem> mediaItems;

  const PostListItem({
    required this.id,
    required this.clientId,
    required this.title,
    required this.caption,
    required this.scheduledFor,
    required this.contentType,
    required this.mediaKind,
    required this.mediaSource,
    required this.mediaUrl,
    required this.approvalStatus,
    required this.publishedAt,
    required this.createdAt,
    required this.clientName,
    required this.createdByName,
    required this.approvedByName,
    required this.effectiveStatus,
    required this.targets,
    required this.mediaItems,
  });

  factory PostListItem.fromJson(Map<String, dynamic> json) {
    return PostListItem(
      id: _readInt(json['id']),
      clientId: _readInt(json['client_id']),
      title: json['title']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      scheduledFor: DateTime.tryParse(json['scheduled_for']?.toString() ?? ''),
      contentType: _readString(json['content_type'] ?? json['contentType']),
      mediaKind: _readString(json['media_kind'] ?? json['mediaKind']),
      mediaSource: _readString(json['media_source'] ?? json['mediaSource']),
      mediaUrl: _readString(json['media_url'] ?? json['mediaUrl']),
      approvalStatus: _readString(
        json['approval_status'] ?? json['approvalStatus'],
      ),
      publishedAt: DateTime.tryParse(
        _readString(json['published_at'] ?? json['publishedAt']),
      ),
      createdAt: DateTime.tryParse(
        _readString(json['created_at'] ?? json['createdAt']),
      ),
      clientName: _readString(json['client_name'] ?? json['clientName']),
      createdByName: _readString(
        json['created_by_name'] ?? json['createdByName'],
      ),
      approvedByName: _readString(
        json['approved_by_name'] ?? json['approvedByName'],
      ),
      effectiveStatus: _readString(
        json['effective_status'] ?? json['effectiveStatus'],
      ),
      targets: _readTargets(json['targets'] ?? json['targets_json']),
      mediaItems: _readMediaItems(json['media_items']),
    );
  }

  String get displayTitle {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) return trimmedTitle;
    final trimmedType = contentType.trim();
    if (trimmedType.isEmpty) return 'Untitled post';
    return trimmedType.substring(0, 1).toUpperCase() + trimmedType.substring(1);
  }

  String get displayStatus {
    final status = effectiveStatus.trim().isNotEmpty
        ? effectiveStatus
        : approvalStatus;
    return status.trim().isEmpty ? 'unknown' : status.trim();
  }

  static List<PostTarget> _readTargets(dynamic value) {
    final decodedValue = _decodeListValue(value);
    return decodedValue
        .whereType<Map<String, dynamic>>()
        .map(PostTarget.fromJson)
        .toList();
  }

  static List<PostMediaItem> _readMediaItems(dynamic value) {
    final decodedValue = _decodeListValue(value);
    return decodedValue
        .whereType<Map<String, dynamic>>()
        .map(PostMediaItem.fromJson)
        .toList();
  }

  static List<dynamic> _decodeListValue(dynamic value) {
    if (value is List) return value;
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded;
      } catch (_) {
        return const [];
      }
    }
    return const [];
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readString(dynamic value) {
    return value?.toString() ?? '';
  }
}

class PostTarget {
  final String status;
  final String platform;
  final int targetId;
  final String profileName;
  final String errorMessage;
  final String platformPostId;
  final int socialAccountId;

  const PostTarget({
    required this.status,
    required this.platform,
    required this.targetId,
    required this.profileName,
    required this.errorMessage,
    required this.platformPostId,
    required this.socialAccountId,
  });

  factory PostTarget.fromJson(Map<String, dynamic> json) {
    return PostTarget(
      status: json['status']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      targetId: _readInt(json['targetId']),
      profileName: json['profileName']?.toString() ?? '',
      errorMessage: json['errorMessage']?.toString() ?? '',
      platformPostId: json['platformPostId']?.toString() ?? '',
      socialAccountId: _readInt(json['socialAccountId']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PostMediaItem {
  final int id;
  final int sortOrder;
  final String mediaKind;
  final String mediaSource;
  final String mediaUrl;
  final String driveFileUrl;
  final String driveFileName;

  const PostMediaItem({
    required this.id,
    required this.sortOrder,
    required this.mediaKind,
    required this.mediaSource,
    required this.mediaUrl,
    required this.driveFileUrl,
    required this.driveFileName,
  });

  factory PostMediaItem.fromJson(Map<String, dynamic> json) {
    return PostMediaItem(
      id: _readInt(json['id']),
      sortOrder: _readInt(json['sortOrder'] ?? json['sort_order']),
      mediaKind: _readString(json['media_kind'] ?? json['mediaKind']),
      mediaSource: _readString(json['media_source'] ?? json['mediaSource']),
      mediaUrl: _readString(json['media_url'] ?? json['mediaUrl']),
      driveFileUrl: _readString(json['drive_file_url'] ?? json['driveFileUrl']),
      driveFileName: _readString(
        json['drive_file_name'] ?? json['driveFileName'],
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _readString(dynamic value) {
    return value?.toString() ?? '';
  }
}

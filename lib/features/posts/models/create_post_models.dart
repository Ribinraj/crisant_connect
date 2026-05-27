class CreatePostRequest {
  final int clientId;
  final String title;
  final String caption;
  final String scheduledFor;
  final String contentType;
  final String mediaKind;
  final String mediaSource;
  final String mediaUrl;
  final String driveFileUrl;
  final String driveFileName;
  final String reelThumbnailMode;
  final String reelThumbnailUrl;
  final int reelThumbnailOffsetMs;
  final List<CreatePostMediaItem> mediaItems;
  final List<int> socialAccountIds;

  const CreatePostRequest({
    required this.clientId,
    required this.title,
    required this.caption,
    required this.scheduledFor,
    required this.contentType,
    required this.mediaKind,
    required this.mediaSource,
    required this.mediaUrl,
    required this.driveFileUrl,
    required this.driveFileName,
    required this.reelThumbnailMode,
    required this.reelThumbnailUrl,
    required this.reelThumbnailOffsetMs,
    required this.mediaItems,
    required this.socialAccountIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'title': title,
      'caption': caption,
      'scheduledFor': scheduledFor,
      'contentType': contentType,
      'mediaKind': mediaKind,
      'mediaSource': mediaSource,
      'mediaUrl': mediaUrl,
      'driveFileUrl': driveFileUrl,
      'driveFileName': driveFileName,
      'reelThumbnailMode': reelThumbnailMode,
      'reelThumbnailUrl': reelThumbnailUrl,
      'reelThumbnailOffsetMs': reelThumbnailOffsetMs,
      'mediaItems': mediaItems.map((item) => item.toJson()).toList(),
      'socialAccountIds': socialAccountIds,
    };
  }
}

class CreatePostMediaItem {
  final String mediaKind;
  final String mediaSource;
  final String mediaUrl;
  final String driveFileUrl;
  final String driveFileName;

  const CreatePostMediaItem({
    required this.mediaKind,
    required this.mediaSource,
    required this.mediaUrl,
    required this.driveFileUrl,
    required this.driveFileName,
  });

  Map<String, dynamic> toJson() {
    return {
      'mediaKind': mediaKind,
      'mediaSource': mediaSource,
      'mediaUrl': mediaUrl,
      'driveFileUrl': driveFileUrl,
      'driveFileName': driveFileName,
    };
  }
}

class CreatePostResponse {
  final int id;
  final Map<String, dynamic> raw;

  const CreatePostResponse({required this.id, required this.raw});

  factory CreatePostResponse.fromJson(Map<String, dynamic> json) {
    final post = json['post'];
    final data = json['data'];

    return CreatePostResponse(
      id:
          _readId(json['id']) ??
          (post is Map<String, dynamic> ? _readId(post['id']) : null) ??
          (data is Map<String, dynamic> ? _readId(data['id']) : null) ??
          0,
      raw: json,
    );
  }

  static int? _readId(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
}

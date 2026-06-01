class UploadsResponse {
  final List<MediaAsset> media;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const UploadsResponse({
    required this.media,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory UploadsResponse.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    final rawPagination = json['pagination'];
    final pagination = rawPagination is Map<String, dynamic>
        ? rawPagination
        : const <String, dynamic>{};
    final page = _readInt(
      json['page'] ?? json['currentPage'] ?? pagination['page'],
      fallback: 1,
    );
    final limit = _readInt(json['limit'] ?? pagination['limit'], fallback: 10);
    final total = _readInt(
      json['total'] ?? json['totalItems'] ?? pagination['total'],
    );
    final totalPages = _readInt(
      json['totalPages'] ?? json['lastPage'] ?? pagination['totalPages'],
    );

    return UploadsResponse(
      media: rawMedia is List
          ? rawMedia
                .whereType<Map<String, dynamic>>()
                .map(MediaAsset.fromJson)
                .toList()
          : const [],
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  bool get hasMore {
    if (totalPages > 0) return page < totalPages;
    if (total > 0) return page * limit < total;
    return media.length >= limit;
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class MediaAsset {
  final int id;
  final String name;
  final String storedName;
  final String url;
  final int size;
  final DateTime? createdAt;
  final String type;
  final String uploadedBy;
  final int linkedPostCount;

  const MediaAsset({
    required this.id,
    required this.name,
    required this.storedName,
    required this.url,
    required this.size,
    required this.createdAt,
    required this.type,
    required this.uploadedBy,
    required this.linkedPostCount,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: _readInt(json['id']),
      name: json['name']?.toString() ?? '',
      storedName: json['storedName']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      size: _readInt(json['size']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      type: json['type']?.toString().toLowerCase() ?? '',
      uploadedBy: json['uploadedBy']?.toString() ?? '',
      linkedPostCount: _readInt(json['linkedPostCount']),
    );
  }

  bool get isImage {
    if (type == 'image' || type.startsWith('image/')) return true;
    final extension = _fileExtension;
    return const {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'heic',
    }.contains(extension);
  }

  bool get isVideo {
    if (type == 'video' || type.startsWith('video/')) return true;
    final extension = _fileExtension;
    return const {
      'mp4',
      'mov',
      'm4v',
      'webm',
      'avi',
      'mkv',
    }.contains(extension);
  }

  String get _fileExtension {
    final source = url.isNotEmpty
        ? url
        : storedName.isNotEmpty
        ? storedName
        : name;
    final path = Uri.tryParse(source)?.path ?? source;
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) return '';
    return path.substring(dotIndex + 1).toLowerCase();
  }

  String resolvedUrl(String baseUrl) {
    final trimmedUrl = url.trim();
    final parsedUrl = Uri.tryParse(trimmedUrl);
    if (parsedUrl == null || trimmedUrl.isEmpty) return trimmedUrl;
    if (parsedUrl.hasScheme) return trimmedUrl;

    final normalizedUrl = trimmedUrl.startsWith('/')
        ? trimmedUrl.substring(1)
        : trimmedUrl;
    final mediaBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';

    return Uri.parse(mediaBaseUrl).resolve(normalizedUrl).toString();
  }

  String get formattedSize {
    if (size <= 0) return '0 KB';
    final kb = size / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

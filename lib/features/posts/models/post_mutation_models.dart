class PostMutationResponse {
  final int id;
  final Map<String, dynamic> raw;

  const PostMutationResponse({required this.id, required this.raw});

  factory PostMutationResponse.fromJson(Map<String, dynamic> json) {
    final post = json['post'];
    final data = json['data'];

    return PostMutationResponse(
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

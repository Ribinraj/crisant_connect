part of 'media_library_bloc.dart';

@immutable
sealed class MediaLibraryState {}

final class MediaLibraryInitial extends MediaLibraryState {}

final class MediaLibraryLoading extends MediaLibraryState {}

final class MediaLibrarySuccess extends MediaLibraryState {
  final String message;
  final List<MediaAsset> media;
  final int page;
  final int limit;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;

  MediaLibrarySuccess({
    required this.message,
    required this.media,
    required this.page,
    required this.limit,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  MediaLibrarySuccess copyWith({
    String? message,
    List<MediaAsset>? media,
    int? page,
    int? limit,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
  }) {
    return MediaLibrarySuccess(
      message: message ?? this.message,
      media: media ?? this.media,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

final class MediaLibraryFailure extends MediaLibraryState {
  final String message;
  final int status;

  MediaLibraryFailure({required this.message, required this.status});
}

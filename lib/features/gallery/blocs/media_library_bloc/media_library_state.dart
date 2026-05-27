part of 'media_library_bloc.dart';

@immutable
sealed class MediaLibraryState {}

final class MediaLibraryInitial extends MediaLibraryState {}

final class MediaLibraryLoading extends MediaLibraryState {}

final class MediaLibrarySuccess extends MediaLibraryState {
  final String message;
  final List<MediaAsset> media;

  MediaLibrarySuccess({required this.message, required this.media});
}

final class MediaLibraryFailure extends MediaLibraryState {
  final String message;
  final int status;

  MediaLibraryFailure({required this.message, required this.status});
}

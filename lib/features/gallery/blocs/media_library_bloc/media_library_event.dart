part of 'media_library_bloc.dart';

@immutable
sealed class MediaLibraryEvent {}

final class FetchMediaLibraryRequested extends MediaLibraryEvent {}

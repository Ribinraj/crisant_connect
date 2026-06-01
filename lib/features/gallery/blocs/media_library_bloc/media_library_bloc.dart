import 'package:crisant_connect/features/gallery/models/uploads_response.dart';
import 'package:crisant_connect/features/posts/post_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'media_library_event.dart';
part 'media_library_state.dart';

class MediaLibraryBloc extends Bloc<MediaLibraryEvent, MediaLibraryState> {
  static const int _pageLimit = 10;
  final PostRepo postRepo;

  MediaLibraryBloc({required this.postRepo}) : super(MediaLibraryInitial()) {
    on<FetchMediaLibraryRequested>(_onFetchMediaLibraryRequested);
    on<FetchMoreMediaLibraryRequested>(_onFetchMoreMediaLibraryRequested);
  }

  Future<void> _onFetchMediaLibraryRequested(
    FetchMediaLibraryRequested event,
    Emitter<MediaLibraryState> emit,
  ) async {
    emit(MediaLibraryLoading());

    final result = await postRepo.getUploads(page: 1, limit: _pageLimit);

    if (result.status == 200 && result.data != null) {
      final data = result.data!;
      emit(
        MediaLibrarySuccess(
          message: result.message,
          media: data.media,
          page: data.page,
          limit: data.limit,
          hasMore: data.hasMore,
        ),
      );
      return;
    }

    emit(MediaLibraryFailure(message: result.message, status: result.status));
  }

  Future<void> _onFetchMoreMediaLibraryRequested(
    FetchMoreMediaLibraryRequested event,
    Emitter<MediaLibraryState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MediaLibrarySuccess ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true, loadMoreError: null));

    final result = await postRepo.getUploads(
      page: currentState.page + 1,
      limit: currentState.limit,
    );

    if (result.status == 200 && result.data != null) {
      final data = result.data!;
      emit(
        currentState.copyWith(
          message: result.message,
          media: [...currentState.media, ...data.media],
          page: data.page,
          limit: data.limit,
          hasMore: data.hasMore,
          isLoadingMore: false,
          loadMoreError: null,
        ),
      );
      return;
    }

    emit(
      currentState.copyWith(
        hasMore: false,
        isLoadingMore: false,
        loadMoreError: result.message,
      ),
    );
  }
}

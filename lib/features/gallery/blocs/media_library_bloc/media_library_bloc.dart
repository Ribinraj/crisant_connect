import 'package:crisant_connect/features/gallery/models/uploads_response.dart';
import 'package:crisant_connect/features/posts/post_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'media_library_event.dart';
part 'media_library_state.dart';

class MediaLibraryBloc extends Bloc<MediaLibraryEvent, MediaLibraryState> {
  final PostRepo postRepo;

  MediaLibraryBloc({required this.postRepo}) : super(MediaLibraryInitial()) {
    on<FetchMediaLibraryRequested>(_onFetchMediaLibraryRequested);
  }

  Future<void> _onFetchMediaLibraryRequested(
    FetchMediaLibraryRequested event,
    Emitter<MediaLibraryState> emit,
  ) async {
    emit(MediaLibraryLoading());

    final result = await postRepo.getUploads();

    if (result.status == 200 && result.data != null) {
      emit(
        MediaLibrarySuccess(message: result.message, media: result.data!.media),
      );
      return;
    }

    emit(MediaLibraryFailure(message: result.message, status: result.status));
  }
}

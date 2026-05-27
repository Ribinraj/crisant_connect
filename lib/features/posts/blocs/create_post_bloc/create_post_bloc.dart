import 'package:crisant_connect/features/posts/models/create_post_models.dart';
import 'package:crisant_connect/features/posts/post_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'create_post_event.dart';
part 'create_post_state.dart';

class CreatePostBloc extends Bloc<CreatePostEvent, CreatePostState> {
  final PostRepo postRepo;

  CreatePostBloc({required this.postRepo}) : super(CreatePostInitial()) {
    on<CreatePostSubmitted>(_onCreatePostSubmitted);
  }

  Future<void> _onCreatePostSubmitted(
    CreatePostSubmitted event,
    Emitter<CreatePostState> emit,
  ) async {
    emit(CreatePostLoading());

    final result = await postRepo.createPost(event.request);

    if (result.status == 201 && result.data != null) {
      emit(
        CreatePostSuccess(
          message: result.message,
          post: result.data!,
          status: result.status,
        ),
      );
      return;
    }

    emit(CreatePostFailure(message: result.message, status: result.status));
  }
}

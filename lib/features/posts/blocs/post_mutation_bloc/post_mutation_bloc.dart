import 'package:crisant_connect/features/posts/models/create_post_models.dart';
import 'package:crisant_connect/features/posts/models/post_mutation_models.dart';
import 'package:crisant_connect/features/posts/post_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'post_mutation_event.dart';
part 'post_mutation_state.dart';

class PostMutationBloc extends Bloc<PostMutationEvent, PostMutationState> {
  final PostRepo postRepo;

  PostMutationBloc({required this.postRepo}) : super(PostMutationInitial()) {
    on<EditPostSubmitted>(_onEditPostSubmitted);
    on<DeletePostRequested>(_onDeletePostRequested);
  }

  Future<void> _onEditPostSubmitted(
    EditPostSubmitted event,
    Emitter<PostMutationState> emit,
  ) async {
    emit(EditPostLoading(postId: event.postId));

    final result = await postRepo.editPost(
      postId: event.postId,
      request: event.request,
    );

    if (!result.error && result.data != null) {
      emit(
        EditPostSuccess(
          message: result.message,
          post: result.data!,
          status: result.status,
        ),
      );
      return;
    }

    emit(
      PostMutationFailure(
        message: result.message,
        status: result.status,
        postId: event.postId,
        action: PostMutationAction.edit,
      ),
    );
  }

  Future<void> _onDeletePostRequested(
    DeletePostRequested event,
    Emitter<PostMutationState> emit,
  ) async {
    emit(DeletePostLoading(postId: event.postId));

    final result = await postRepo.deletePost(postId: event.postId);

    if (!result.error) {
      emit(
        DeletePostSuccess(
          message: result.message,
          postId: event.postId,
          status: result.status,
        ),
      );
      return;
    }

    emit(
      PostMutationFailure(
        message: result.message,
        status: result.status,
        postId: event.postId,
        action: PostMutationAction.delete,
      ),
    );
  }
}

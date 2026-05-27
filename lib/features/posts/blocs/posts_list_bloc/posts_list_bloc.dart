import 'package:crisant_connect/features/posts/models/posts_list_response.dart';
import 'package:crisant_connect/features/posts/post_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'posts_list_event.dart';
part 'posts_list_state.dart';

class PostsListBloc extends Bloc<PostsListEvent, PostsListState> {
  final PostRepo postRepo;

  PostsListBloc({required this.postRepo}) : super(PostsListInitial()) {
    on<FetchPostsListRequested>(_onFetchPostsListRequested);
  }

  Future<void> _onFetchPostsListRequested(
    FetchPostsListRequested event,
    Emitter<PostsListState> emit,
  ) async {
    emit(PostsListLoading(view: event.view));

    final result = await postRepo.getPosts(view: event.view);

    if (result.status == 200 && result.data != null) {
      emit(
        PostsListSuccess(
          message: result.message,
          view: event.view,
          posts: result.data!.posts,
        ),
      );
      return;
    }

    emit(
      PostsListFailure(
        message: result.message,
        status: result.status,
        view: event.view,
      ),
    );
  }
}

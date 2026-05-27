part of 'posts_list_bloc.dart';

@immutable
sealed class PostsListState {
  final String view;

  const PostsListState({required this.view});
}

final class PostsListInitial extends PostsListState {
  const PostsListInitial() : super(view: 'scheduled');
}

final class PostsListLoading extends PostsListState {
  const PostsListLoading({required super.view});
}

final class PostsListSuccess extends PostsListState {
  final String message;
  final List<PostListItem> posts;

  const PostsListSuccess({
    required this.message,
    required super.view,
    required this.posts,
  });
}

final class PostsListFailure extends PostsListState {
  final String message;
  final int status;

  const PostsListFailure({
    required this.message,
    required this.status,
    required super.view,
  });
}

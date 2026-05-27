part of 'posts_list_bloc.dart';

@immutable
sealed class PostsListEvent {}

final class FetchPostsListRequested extends PostsListEvent {
  final String view;

  FetchPostsListRequested({required this.view});
}

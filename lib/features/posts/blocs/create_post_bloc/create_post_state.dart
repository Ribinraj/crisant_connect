part of 'create_post_bloc.dart';

@immutable
sealed class CreatePostState {}

final class CreatePostInitial extends CreatePostState {}

final class CreatePostLoading extends CreatePostState {}

final class CreatePostSuccess extends CreatePostState {
  final String message;
  final CreatePostResponse post;
  final int status;

  CreatePostSuccess({
    required this.message,
    required this.post,
    required this.status,
  });
}

final class CreatePostFailure extends CreatePostState {
  final String message;
  final int status;

  CreatePostFailure({required this.message, required this.status});
}

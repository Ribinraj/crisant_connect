part of 'post_mutation_bloc.dart';

enum PostMutationAction { edit, delete }

@immutable
sealed class PostMutationState {}

final class PostMutationInitial extends PostMutationState {}

final class EditPostLoading extends PostMutationState {
  final int postId;

  EditPostLoading({required this.postId});
}

final class DeletePostLoading extends PostMutationState {
  final int postId;

  DeletePostLoading({required this.postId});
}

final class EditPostSuccess extends PostMutationState {
  final String message;
  final PostMutationResponse post;
  final int status;

  EditPostSuccess({
    required this.message,
    required this.post,
    required this.status,
  });
}

final class DeletePostSuccess extends PostMutationState {
  final String message;
  final int postId;
  final int status;

  DeletePostSuccess({
    required this.message,
    required this.postId,
    required this.status,
  });
}

final class PostMutationFailure extends PostMutationState {
  final String message;
  final int status;
  final int postId;
  final PostMutationAction action;

  PostMutationFailure({
    required this.message,
    required this.status,
    required this.postId,
    required this.action,
  });
}

part of 'post_mutation_bloc.dart';

@immutable
sealed class PostMutationEvent {}

final class EditPostSubmitted extends PostMutationEvent {
  final int postId;
  final CreatePostRequest request;

  EditPostSubmitted({required this.postId, required this.request});
}

final class DeletePostRequested extends PostMutationEvent {
  final int postId;

  DeletePostRequested({required this.postId});
}

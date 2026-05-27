part of 'create_post_bloc.dart';

@immutable
sealed class CreatePostEvent {}

final class CreatePostSubmitted extends CreatePostEvent {
  final CreatePostRequest request;

  CreatePostSubmitted({required this.request});
}

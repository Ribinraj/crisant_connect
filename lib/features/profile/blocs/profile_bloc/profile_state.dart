part of 'profile_bloc.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  final String message;
  final ProfileUser user;

  ProfileLoaded({required this.message, required this.user});
}

final class ProfileUpdating extends ProfileState {
  final ProfileUser user;

  ProfileUpdating({required this.user});
}

final class ProfileUpdateSuccess extends ProfileState {
  final String message;
  final ProfileUser user;
  final int status;

  ProfileUpdateSuccess({
    required this.message,
    required this.user,
    required this.status,
  });
}

final class ProfileFailure extends ProfileState {
  final String message;
  final int status;
  final ProfileUser? user;

  ProfileFailure({required this.message, required this.status, this.user});
}

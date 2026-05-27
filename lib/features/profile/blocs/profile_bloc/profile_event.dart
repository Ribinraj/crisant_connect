part of 'profile_bloc.dart';

@immutable
sealed class ProfileEvent {}

final class FetchProfileRequested extends ProfileEvent {}

final class UpdateProfileSubmitted extends ProfileEvent {
  final String fullName;
  final String mobileNumber;
  final ProfileUser currentUser;

  UpdateProfileSubmitted({
    required this.fullName,
    required this.mobileNumber,
    required this.currentUser,
  });
}

part of 'logout_bloc.dart';

@immutable
sealed class LogoutState {}

final class LogoutInitial extends LogoutState {}

final class LogoutLoading extends LogoutState {}

final class LogoutSuccess extends LogoutState {
  final String message;
  final LogoutResponse response;

  LogoutSuccess({required this.message, required this.response});
}

final class LogoutFailure extends LogoutState {
  final String message;
  final int status;

  LogoutFailure({required this.message, required this.status});
}

part of 'refresh_token_bloc.dart';

@immutable
sealed class RefreshTokenState {}

final class RefreshTokenInitial extends RefreshTokenState {}

final class RefreshTokenLoading extends RefreshTokenState {}

final class RefreshTokenSuccess extends RefreshTokenState {
  final String message;
  final RefreshTokenResponse response;

  RefreshTokenSuccess({required this.message, required this.response});
}

final class RefreshTokenFailure extends RefreshTokenState {
  final String message;
  final int status;

  RefreshTokenFailure({required this.message, required this.status});
}

part of 'refresh_token_bloc.dart';

@immutable
sealed class RefreshTokenEvent {}

final class RefreshTokenRequested extends RefreshTokenEvent {
  final String refreshToken;

  RefreshTokenRequested({required this.refreshToken});
}

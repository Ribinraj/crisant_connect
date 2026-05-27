part of 'logout_bloc.dart';

@immutable
sealed class LogoutEvent {}

final class LogoutRequested extends LogoutEvent {
  final String refreshToken;

  LogoutRequested({required this.refreshToken});
}

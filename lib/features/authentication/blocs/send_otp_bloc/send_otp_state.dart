part of 'send_otp_bloc.dart';

@immutable
sealed class SendOtpState {}

final class SendOtpInitial extends SendOtpState {}

final class SendOtpLoading extends SendOtpState {}

final class SendOtpSuccess extends SendOtpState {
  final String message;
  final SendOtpResponse response;

  SendOtpSuccess({required this.message, required this.response});
}

final class SendOtpFailure extends SendOtpState {
  final String message;
  final int status;

  SendOtpFailure({required this.message, required this.status});
}

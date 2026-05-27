part of 'verify_otp_bloc.dart';

@immutable
sealed class VerifyOtpState {}

final class VerifyOtpInitial extends VerifyOtpState {}

final class VerifyOtpLoading extends VerifyOtpState {}

final class VerifyOtpSuccess extends VerifyOtpState {
  final String message;
  final VerifyOtpResponse response;

  VerifyOtpSuccess({required this.message, required this.response});
}

final class VerifyOtpFailure extends VerifyOtpState {
  final String message;
  final int status;

  VerifyOtpFailure({required this.message, required this.status});
}

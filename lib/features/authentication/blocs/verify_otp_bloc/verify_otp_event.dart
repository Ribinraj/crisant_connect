part of 'verify_otp_bloc.dart';

@immutable
sealed class VerifyOtpEvent {}

final class VerifyOtpRequested extends VerifyOtpEvent {
  final String mobileNumber;
  final String otp;

  VerifyOtpRequested({required this.mobileNumber, required this.otp});
}

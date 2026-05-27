part of 'send_otp_bloc.dart';

@immutable
sealed class SendOtpEvent {}

final class SendOtpRequested extends SendOtpEvent {
  final String mobileNumber;

  SendOtpRequested({required this.mobileNumber});
}

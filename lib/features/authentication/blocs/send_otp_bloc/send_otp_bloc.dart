import 'package:crisant_connect/features/authentication/auth_repo.dart';
import 'package:crisant_connect/features/authentication/models/send_otp_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'send_otp_event.dart';
part 'send_otp_state.dart';

class SendOtpBloc extends Bloc<SendOtpEvent, SendOtpState> {
  final Apprepo apprepo;

  SendOtpBloc({required this.apprepo}) : super(SendOtpInitial()) {
    on<SendOtpRequested>(_onSendOtpRequested);
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<SendOtpState> emit,
  ) async {
    emit(SendOtpLoading());

    final result = await apprepo.requestOtp(mobileNumber: event.mobileNumber);

    if (result.status == 200 && result.data != null) {
      emit(SendOtpSuccess(message: result.message, response: result.data!));
      return;
    }

    emit(SendOtpFailure(message: result.message, status: result.status));
  }
}

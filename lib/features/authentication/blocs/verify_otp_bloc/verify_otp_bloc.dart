import 'package:crisant_connect/features/authentication/auth_repo.dart';
import 'package:crisant_connect/features/authentication/models/verify_otp_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'verify_otp_event.dart';
part 'verify_otp_state.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  final Apprepo apprepo;

  VerifyOtpBloc({required this.apprepo}) : super(VerifyOtpInitial()) {
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
  }

  Future<void> _onVerifyOtpRequested(
    VerifyOtpRequested event,
    Emitter<VerifyOtpState> emit,
  ) async {
    emit(VerifyOtpLoading());

    final result = await apprepo.verifyOtp(
      mobileNumber: event.mobileNumber,
      otp: event.otp,
    );

    if (result.status == 200 && result.data != null) {
      emit(VerifyOtpSuccess(message: result.message, response: result.data!));
      return;
    }

    emit(VerifyOtpFailure(message: result.message, status: result.status));
  }
}

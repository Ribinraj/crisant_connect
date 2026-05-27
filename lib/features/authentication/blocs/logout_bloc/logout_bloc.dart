import 'package:crisant_connect/features/authentication/auth_repo.dart';
import 'package:crisant_connect/features/authentication/models/logout_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'logout_event.dart';
part 'logout_state.dart';

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  final Apprepo apprepo;

  LogoutBloc({required this.apprepo}) : super(LogoutInitial()) {
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<LogoutState> emit,
  ) async {
    emit(LogoutLoading());

    final result = await apprepo.logout(refreshToken: event.refreshToken);

    if (result.status == 200 && result.data != null && result.data!.ok) {
      emit(LogoutSuccess(message: result.message, response: result.data!));
      return;
    }

    emit(LogoutFailure(message: result.message, status: result.status));
  }
}

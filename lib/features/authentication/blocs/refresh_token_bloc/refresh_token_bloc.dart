import 'package:crisant_connect/features/authentication/auth_repo.dart';
import 'package:crisant_connect/features/authentication/models/refresh_token_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'refresh_token_event.dart';
part 'refresh_token_state.dart';

class RefreshTokenBloc extends Bloc<RefreshTokenEvent, RefreshTokenState> {
  final Apprepo apprepo;

  RefreshTokenBloc({required this.apprepo}) : super(RefreshTokenInitial()) {
    on<RefreshTokenRequested>(_onRefreshTokenRequested);
  }

  Future<void> _onRefreshTokenRequested(
    RefreshTokenRequested event,
    Emitter<RefreshTokenState> emit,
  ) async {
    emit(RefreshTokenLoading());

    final result = await apprepo.refreshToken(refreshToken: event.refreshToken);

    if (result.status == 200 && result.data != null) {
      emit(
        RefreshTokenSuccess(message: result.message, response: result.data!),
      );
      return;
    }

    emit(RefreshTokenFailure(message: result.message, status: result.status));
  }
}

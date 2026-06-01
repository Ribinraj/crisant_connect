import 'package:crisant_connect/features/dashboard/dashboard_repo.dart';
import 'package:crisant_connect/features/dashboard/models/dashboard_response.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepo dashboardRepo;

  DashboardBloc({required this.dashboardRepo}) : super(DashboardInitial()) {
    on<FetchDashboardRequested>(_onFetchDashboardRequested);
  }

  Future<void> _onFetchDashboardRequested(
    FetchDashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    final result = await dashboardRepo.getDashboard(month: event.month);

    if (result.status == 200 && result.data != null) {
      emit(DashboardSuccess(message: result.message, dashboard: result.data!));
      return;
    }

    emit(DashboardFailure(message: result.message, status: result.status));
  }
}

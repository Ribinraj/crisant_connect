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
      final dashboard = result.data!;
      emit(
        DashboardSuccess(
          message: result.message,
          dashboard: await _withRollingChartData(dashboard, event.month),
        ),
      );
      return;
    }

    emit(DashboardFailure(message: result.message, status: result.status));
  }

  Future<DashboardResponse> _withRollingChartData(
    DashboardResponse dashboard,
    String month,
  ) async {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final currentItems = _itemsWithMonth(
      dashboard.monthlyPostingOverview,
      dashboard.month.key.isEmpty ? month : dashboard.month.key,
    );

    if (month != currentMonth || now.day >= 5) {
      return _copyWithOverview(dashboard, currentItems);
    }

    final previousMonth = _shiftMonth(month, -1);
    final previousResult = await dashboardRepo.getDashboard(
      month: previousMonth,
    );
    if (previousResult.status != 200 || previousResult.data == null) {
      return _copyWithOverview(dashboard, currentItems);
    }

    return _copyWithOverview(dashboard, [
      ..._itemsWithMonth(
        previousResult.data!.monthlyPostingOverview,
        previousResult.data!.month.key.isEmpty
            ? previousMonth
            : previousResult.data!.month.key,
      ),
      ...currentItems,
    ]);
  }

  DashboardResponse _copyWithOverview(
    DashboardResponse dashboard,
    List<MonthlyPostingOverviewItem> monthlyPostingOverview,
  ) {
    return DashboardResponse(
      stats: dashboard.stats,
      month: dashboard.month,
      monthlyPostingOverview: monthlyPostingOverview,
      postingGapMonitor: dashboard.postingGapMonitor,
      recentPosts: dashboard.recentPosts,
      generatedAt: dashboard.generatedAt,
    );
  }

  List<MonthlyPostingOverviewItem> _itemsWithMonth(
    List<MonthlyPostingOverviewItem> items,
    String month,
  ) {
    final parts = month.split('-');
    final now = DateTime.now();
    final year = parts.isNotEmpty
        ? int.tryParse(parts.first) ?? now.year
        : now.year;
    final monthNumber = parts.length > 1
        ? int.tryParse(parts[1]) ?? now.month
        : now.month;
    final daysInMonth = DateTime(year, monthNumber + 1, 0).day;

    return items.map((item) {
      final itemDate = item.date?.toLocal();
      final day = item.day > 0
          ? item.day.clamp(1, daysInMonth).toInt()
          : itemDate?.day ?? 1;
      final date = itemDate ?? DateTime(year, monthNumber, day);
      return MonthlyPostingOverviewItem(
        date: DateTime(date.year, date.month, date.day),
        day: day,
        instagram: item.instagram,
        facebook: item.facebook,
      );
    }).toList();
  }

  String _shiftMonth(String month, int offset) {
    final parts = month.split('-');
    final now = DateTime.now();
    final year = parts.isNotEmpty
        ? int.tryParse(parts.first) ?? now.year
        : now.year;
    final monthNumber = parts.length > 1
        ? int.tryParse(parts[1]) ?? now.month
        : now.month;
    final shifted = DateTime(year, monthNumber + offset);
    return '${shifted.year}-${shifted.month.toString().padLeft(2, '0')}';
  }
}

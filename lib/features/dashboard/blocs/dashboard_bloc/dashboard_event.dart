part of 'dashboard_bloc.dart';

@immutable
sealed class DashboardEvent {}

final class FetchDashboardRequested extends DashboardEvent {
  final String month;

  FetchDashboardRequested({required this.month});
}

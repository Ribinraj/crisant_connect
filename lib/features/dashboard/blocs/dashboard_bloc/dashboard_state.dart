part of 'dashboard_bloc.dart';

@immutable
sealed class DashboardState {}

final class DashboardInitial extends DashboardState {}

final class DashboardLoading extends DashboardState {}

final class DashboardSuccess extends DashboardState {
  final String message;
  final DashboardResponse dashboard;

  DashboardSuccess({required this.message, required this.dashboard});
}

final class DashboardFailure extends DashboardState {
  final String message;
  final int status;

  DashboardFailure({required this.message, required this.status});
}

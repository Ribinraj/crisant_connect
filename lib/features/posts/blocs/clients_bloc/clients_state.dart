part of 'clients_bloc.dart';

@immutable
sealed class ClientsState {}

final class ClientsInitial extends ClientsState {}

final class ClientsLoading extends ClientsState {}

final class ClientsSuccess extends ClientsState {
  final String message;
  final List<ClientModel> clients;

  ClientsSuccess({required this.message, required this.clients});
}

final class ClientsFailure extends ClientsState {
  final String message;
  final int status;

  ClientsFailure({required this.message, required this.status});
}

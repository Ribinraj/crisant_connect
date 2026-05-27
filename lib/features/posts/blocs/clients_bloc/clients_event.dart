part of 'clients_bloc.dart';

@immutable
sealed class ClientsEvent {}

final class FetchClientsRequested extends ClientsEvent {}

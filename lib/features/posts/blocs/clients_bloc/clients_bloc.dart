import 'package:crisant_connect/features/posts/models/clients_response.dart';
import 'package:crisant_connect/features/posts/post_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'clients_event.dart';
part 'clients_state.dart';

class ClientsBloc extends Bloc<ClientsEvent, ClientsState> {
  final PostRepo postRepo;

  ClientsBloc({required this.postRepo}) : super(ClientsInitial()) {
    on<FetchClientsRequested>(_onFetchClientsRequested);
  }

  Future<void> _onFetchClientsRequested(
    FetchClientsRequested event,
    Emitter<ClientsState> emit,
  ) async {
    emit(ClientsLoading());

    final result = await postRepo.getClients();

    if (result.status == 200 && result.data != null) {
      emit(
        ClientsSuccess(message: result.message, clients: result.data!.clients),
      );
      return;
    }

    emit(ClientsFailure(message: result.message, status: result.status));
  }
}

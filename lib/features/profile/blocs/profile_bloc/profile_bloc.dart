import 'package:crisant_connect/core/local_storage.dart';
import 'package:crisant_connect/features/profile/models/profile_response.dart';
import 'package:crisant_connect/features/profile/profile_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepo profileRepo;

  ProfileBloc({required this.profileRepo}) : super(ProfileInitial()) {
    on<FetchProfileRequested>(_onFetchProfileRequested);
    on<UpdateProfileSubmitted>(_onUpdateProfileSubmitted);
  }

  Future<void> _onFetchProfileRequested(
    FetchProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final result = await profileRepo.getProfile();

    if (result.status == 200 && result.data != null) {
      emit(ProfileLoaded(message: result.message, user: result.data!.user));
      return;
    }

    emit(ProfileFailure(message: result.message, status: result.status));
  }

  Future<void> _onUpdateProfileSubmitted(
    UpdateProfileSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating(user: event.currentUser));

    final result = await profileRepo.updateProfile(
      ProfileUpdateRequest(
        fullName: event.fullName,
        mobileNumber: event.mobileNumber,
      ),
    );

    if (!result.error && result.data != null) {
      final updatedUser = _mergeUpdatedUser(
        currentUser: event.currentUser,
        responseUser: result.data!.user,
        fullName: event.fullName,
        mobileNumber: event.mobileNumber,
      );
      await LocalStorage.saveUserProfile(
        fullName: updatedUser.fullName,
        mobileNumber: updatedUser.mobileNumber,
      );
      emit(
        ProfileUpdateSuccess(
          message: result.message,
          user: updatedUser,
          status: result.status,
        ),
      );
      return;
    }

    emit(
      ProfileFailure(
        message: result.message,
        status: result.status,
        user: event.currentUser,
      ),
    );
  }

  ProfileUser _mergeUpdatedUser({
    required ProfileUser currentUser,
    required ProfileUser responseUser,
    required String fullName,
    required String mobileNumber,
  }) {
    final hasResponseUser =
        responseUser.id != 0 ||
        responseUser.fullName.isNotEmpty ||
        responseUser.mobileNumber.isNotEmpty ||
        responseUser.role.isNotEmpty;

    return currentUser.copyWith(
      id: responseUser.id == 0 ? currentUser.id : responseUser.id,
      fullName: responseUser.fullName.isEmpty
          ? fullName
          : responseUser.fullName,
      mobileNumber: responseUser.mobileNumber.isEmpty
          ? mobileNumber
          : responseUser.mobileNumber,
      role: responseUser.role.isEmpty ? currentUser.role : responseUser.role,
      approverId: responseUser.approverId ?? currentUser.approverId,
      leadsAccess: hasResponseUser
          ? responseUser.leadsAccess
          : currentUser.leadsAccess,
    );
  }
}

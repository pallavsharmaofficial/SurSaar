import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required ProfileRepository repository})
    : _repository = repository,
      super(ProfileState.initial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileSaved>(_onProfileSaved);
    on<ProfilePhotoUpdated>(_onPhotoUpdated);
  }

  final ProfileRepository _repository;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    try {
      final profile = await _repository.getProfile();
      emit(state.copyWith(status: ProfileStatus.ready, profile: profile));
    } catch (error) {
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onProfileSaved(
    ProfileSaved event,
    Emitter<ProfileState> emit,
  ) async {
    final updated = state.profile.copyWith(name: event.name, bio: event.bio);
    await _repository.saveProfile(updated);
    emit(state.copyWith(profile: updated));
  }

  Future<void> _onPhotoUpdated(
    ProfilePhotoUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    final data = await _repository.pickProfilePhoto();
    if (data == null) return;
    final updated = state.profile.copyWith(photoData: data);
    await _repository.saveProfile(updated);
    emit(state.copyWith(profile: updated));
  }
}

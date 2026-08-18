import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/features/profile/data/profile_repository.dart';
import 'package:refsure/features/profile/presentation/cubit/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfileInitial());

  final ProfileRepository _profileRepository;
  StreamSubscription<dynamic>? _userSub;

  void loadProfile(String uid) {
    emit(const ProfileLoading());
    _userSub?.cancel();
    _userSub = _profileRepository.watchUser(uid).listen(
      (user) {
        if (user != null) {
          emit(ProfileLoaded(user));
        }
      },
      onError: (Object error) {
        emit(ProfileError(error.toString()));
      },
    );
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    final current = state;
    if (current is ProfileLoaded) {
      emit(ProfileUpdating(current.user));
    }
    try {
      await _profileRepository.updateProfile(uid, data);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<String?> uploadResume(String uid) async {
    try {
      return await _profileRepository.uploadResume(uid);
    } catch (e) {
      emit(ProfileError(e.toString()));
      return null;
    }
  }

  @override
  Future<void> close() {
    _userSub?.cancel();
    return super.close();
  }
}

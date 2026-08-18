import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/features/profile/data/profile_repository.dart';
import 'package:refsure/features/onboarding/presentation/cubit/onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const OnboardingInitial(role: UserRole.seeker));

  final ProfileRepository _profileRepository;

  void start(UserRole role) {
    final totalSteps = role == UserRole.provider ? 4 : 5;
    emit(OnboardingInProgress(
      step: 0,
      totalSteps: totalSteps,
      data: <String, dynamic>{},
    ));
  }

  void nextStep(Map<String, dynamic> stepData) {
    final current = state;
    if (current is OnboardingInProgress) {
      final merged = {...current.data, ...stepData};
      if (current.step + 1 >= current.totalSteps) {
        _save(merged);
      } else {
        emit(OnboardingInProgress(
          step: current.step + 1,
          totalSteps: current.totalSteps,
          data: merged,
        ));
      }
    }
  }

  void previousStep() {
    final current = state;
    if (current is OnboardingInProgress && current.step > 0) {
      emit(OnboardingInProgress(
        step: current.step - 1,
        totalSteps: current.totalSteps,
        data: current.data,
      ));
    }
  }

  Future<void> _save(Map<String, dynamic> data) async {
    emit(const OnboardingSaving());
    try {
      final uid = data['uid'] as String?;
      if (uid != null) {
        await _profileRepository.updateProfile(uid, data);
      }
      emit(const OnboardingCompleted());
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }
}

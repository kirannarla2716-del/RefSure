import 'package:equatable/equatable.dart';
import 'package:refsure/core/enums/enums.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial({required this.role});

  final UserRole role;

  @override
  List<Object?> get props => [role];
}

class OnboardingInProgress extends OnboardingState {
  const OnboardingInProgress({
    required this.step,
    required this.totalSteps,
    required this.data,
  });

  final int step;
  final int totalSteps;
  final Map<String, dynamic> data;

  @override
  List<Object?> get props => [step, totalSteps, data];
}

class OnboardingSaving extends OnboardingState {
  const OnboardingSaving();
}

class OnboardingCompleted extends OnboardingState {
  const OnboardingCompleted();
}

class OnboardingError extends OnboardingState {
  const OnboardingError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

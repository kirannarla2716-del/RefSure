// lib/features/cv_job_matcher/presentation/cubit/applicants_cubit.dart

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/features/cv_job_matcher/data/cv_matcher_repository.dart';
import 'package:refsure/features/cv_job_matcher/models/job_application.dart';

// ── State ──────────────────────────────────────────────────

sealed class ApplicantsState extends Equatable {
  const ApplicantsState();
  @override List<Object?> get props => [];
}
class ApplicantsInitial extends ApplicantsState { const ApplicantsInitial(); }
class ApplicantsLoading extends ApplicantsState { const ApplicantsLoading(); }
class ApplicantsLoaded  extends ApplicantsState {
  const ApplicantsLoaded({required this.applications});
  final List<JobApplication> applications;
  @override List<Object?> get props => [applications];
}
class ApplicantsError extends ApplicantsState {
  const ApplicantsError(this.message);
  final String message;
  @override List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────

class ApplicantsCubit extends Cubit<ApplicantsState> {
  ApplicantsCubit({required CvMatcherRepository repository})
      : _repository = repository,
        super(const ApplicantsInitial());

  final CvMatcherRepository _repository;
  StreamSubscription<List<JobApplication>>? _sub;

  void watchJob(String postedJobId) {
    emit(const ApplicantsLoading());
    _sub?.cancel();
    _sub = _repository.watchJobApplications(postedJobId).listen(
      (apps) => emit(ApplicantsLoaded(applications: apps)),
      onError: (Object e) => emit(ApplicantsError(e.toString())),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

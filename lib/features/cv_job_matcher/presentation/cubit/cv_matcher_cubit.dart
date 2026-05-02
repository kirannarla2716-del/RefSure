// lib/features/cv_job_matcher/presentation/cubit/cv_matcher_cubit.dart
// REFACTORED — handles requester apply + provider job fetch + provider decisions

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/features/cv_job_matcher/data/cv_matcher_repository.dart';
import 'package:refsure/features/cv_job_matcher/models/job_application.dart';
import 'package:refsure/features/cv_job_matcher/presentation/cubit/cv_matcher_state.dart';

class CvMatcherCubit extends Cubit<CvMatcherState> {
  CvMatcherCubit({required CvMatcherRepository repository})
      : _repository = repository,
        super(const CvMatcherInitial());

  final CvMatcherRepository _repository;

  // ── REQUESTER: Submit CV application ─────────────────────

  /// Called when requester submits their CV.
  /// Matching runs automatically inside — no manual trigger needed.
  Future<void> submitApplication({
    required Job job,
    required String requesterId,
    required String requesterName,
    required String requesterEmail,
    required String resumeText,
    String? resumeFileUrl,
  }) async {
    if (resumeText.trim().length < 50) {
      emit(const CvMatcherError(
        'Please paste more CV text. At least a few paragraphs are needed.'));
      return;
    }

    emit(const CvMatcherLoading());
    try {
      final app = await _repository.submitApplication(
        job: job,
        requesterId: requesterId,
        requesterName: requesterName,
        requesterEmail: requesterEmail,
        resumeText: resumeText,
        resumeFileUrl: resumeFileUrl,
      );
      emit(ApplicationSubmitted(application: app));
    } catch (e) {
      emit(CvMatcherError('Failed to submit application: $e'));
    }
  }

  // ── PROVIDER: Fetch company jobs ──────────────────────────

  Future<void> fetchCompanyJobs({
    required String companyName,
    required String country,
    int lastDays = 30,
    List<String> alreadyPostedIds = const [],
  }) async {
    emit(const CvMatcherLoading());
    try {
      final jobs = await _repository.fetchCompanyJobs(
        companyName: companyName,
        country: country,
        lastDays: lastDays,
        alreadyPostedIds: alreadyPostedIds,
      );
      emit(CompanyJobsLoaded(jobs: jobs));
    } catch (e) {
      emit(CvMatcherError('Failed to load company jobs: $e'));
    }
  }

  // ── PROVIDER: Record decision ─────────────────────────────

  Future<void> updateDecision({
    required String applicationId,
    required ApplicationStatus status,
    String? providerNote,
  }) async {
    try {
      await _repository.updateDecision(
        applicationId: applicationId,
        status: status,
        providerNote: providerNote,
      );
      emit(const DecisionSaved());
    } catch (e) {
      emit(CvMatcherError('Failed to save decision: $e'));
    }
  }

  void reset() => emit(const CvMatcherInitial());
}

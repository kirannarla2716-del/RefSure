// lib/features/cv_job_matcher/presentation/cubit/cv_matcher_state.dart
// REFACTORED — covers both requester apply flow and provider job fetch

import 'package:equatable/equatable.dart';
import 'package:refsure/features/cv_job_matcher/models/job_application.dart';
import 'package:refsure/features/cv_job_matcher/models/job_opening.dart';

sealed class CvMatcherState extends Equatable {
  const CvMatcherState();
  @override
  List<Object?> get props => [];
}

// ── Common states ──────────────────────────────────────────
class CvMatcherInitial extends CvMatcherState { const CvMatcherInitial(); }
class CvMatcherLoading extends CvMatcherState { const CvMatcherLoading(); }
class CvMatcherError   extends CvMatcherState {
  const CvMatcherError(this.message);
  final String message;
  @override List<Object?> get props => [message];
}

// ── Requester: application submitted ──────────────────────
class ApplicationSubmitted extends CvMatcherState {
  const ApplicationSubmitted({required this.application});
  final JobApplication application;
  @override List<Object?> get props => [application];
}

// ── Provider: company jobs fetched ────────────────────────
class CompanyJobsLoaded extends CvMatcherState {
  const CompanyJobsLoaded({required this.jobs});
  final List<JobOpening> jobs;
  @override List<Object?> get props => [jobs];
}

// ── Provider: job posted from company listing ─────────────
class JobPostedSuccess extends CvMatcherState {
  const JobPostedSuccess(this.jobId);
  final String jobId;
  @override List<Object?> get props => [jobId];
}

// ── Provider: decision saved (shortlist/refer/reject) ─────
class DecisionSaved extends CvMatcherState { const DecisionSaved(); }

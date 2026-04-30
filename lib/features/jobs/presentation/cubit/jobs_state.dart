import 'package:equatable/equatable.dart';
import 'package:refsure/core/models/job.dart';

sealed class JobsState extends Equatable {
  const JobsState();

  @override
  List<Object?> get props => [];
}

class JobsInitial extends JobsState {
  const JobsInitial();
}

class JobsLoading extends JobsState {
  const JobsLoading();
}

class JobsLoaded extends JobsState {
  const JobsLoaded({required this.jobs});

  final List<Job> jobs;

  @override
  List<Object?> get props => [jobs];
}

class JobPostSuccess extends JobsState {
  const JobPostSuccess(this.jobId);

  final String jobId;

  @override
  List<Object?> get props => [jobId];
}

class JobsError extends JobsState {
  const JobsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

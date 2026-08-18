import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/features/jobs/data/jobs_repository.dart';
import 'package:refsure/features/jobs/presentation/cubit/jobs_state.dart';
import 'package:refsure/core/models/job.dart';

class JobsCubit extends Cubit<JobsState> {
  JobsCubit({required JobsRepository jobsRepository})
      : _jobsRepository = jobsRepository,
        super(const JobsInitial());

  final JobsRepository _jobsRepository;
  StreamSubscription<List<Job>>? _jobsSub;

  void loadJobs() {
    emit(const JobsLoading());
    _jobsSub?.cancel();
    _jobsSub = _jobsRepository.watchActiveJobs().listen(
      (jobs) {
        emit(JobsLoaded(jobs: jobs));
      },
      onError: (Object error) {
        emit(JobsError(error.toString()));
      },
    );
  }

  Future<void> postJob(Job job) async {
    try {
      final id = await _jobsRepository.postJob(job);
      if (id != null) {
        emit(JobPostSuccess(id));
      } else {
        emit(const JobsError('Failed to post job'));
      }
    } catch (e) {
      emit(JobsError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _jobsSub?.cancel();
    return super.close();
  }
}

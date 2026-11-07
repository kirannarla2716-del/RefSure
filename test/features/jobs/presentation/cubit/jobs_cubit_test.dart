import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/features/jobs/presentation/cubit/jobs_cubit.dart';
import 'package:refsure/features/jobs/presentation/cubit/jobs_state.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockJobsRepository mockJobsRepository;

  setUpAll(() {
    registerFallbackValue(Job(
      id: '',
      providerId: '',
      company: '',
      companyLogo: '',
      title: '',
      department: '',
      location: '',
      workMode: '',
      minExp: 0,
      maxExp: 0,
      skills: [],
      description: '',
      deadline: '',
    ));
  });

  setUp(() {
    mockJobsRepository = MockJobsRepository();
  });

  final testJob = Job(
    id: 'job-1',
    providerId: 'prov-1',
    company: 'Acme Corp',
    companyLogo: 'A',
    title: 'Flutter Developer',
    department: 'Engineering',
    location: 'Bangalore',
    workMode: 'Remote',
    minExp: 2,
    maxExp: 5,
    skills: ['Flutter', 'Dart'],
    description: 'Build great apps',
    deadline: '2026-06-01',
  );

  final testJob2 = Job(
    id: 'job-2',
    providerId: 'prov-1',
    company: 'Acme Corp',
    companyLogo: 'A',
    title: 'Backend Engineer',
    department: 'Engineering',
    location: 'Mumbai',
    workMode: 'Hybrid',
    minExp: 3,
    maxExp: 7,
    skills: ['Go', 'PostgreSQL'],
    description: 'Build scalable services',
    deadline: '2026-07-01',
  );

  group('Feature: Job Listings', () {
    // -- Scenario: Load Jobs ------------------------------------------------
    group('Scenario: User loads active job listings', () {
      blocTest<JobsCubit, JobsState>(
        'Given active jobs exist, '
        'When loadJobs is called, '
        'Then it should emit [JobsLoading, JobsLoaded]',
        build: () {
          when(() => mockJobsRepository.watchActiveJobs())
              .thenAnswer((_) => Stream.value([testJob, testJob2]));
          return JobsCubit(jobsRepository: mockJobsRepository);
        },
        act: (cubit) => cubit.loadJobs(),
        expect: () => [
          const JobsLoading(),
          isA<JobsLoaded>().having(
            (s) => s.jobs.length,
            'jobs count',
            2,
          ),
        ],
      );

      blocTest<JobsCubit, JobsState>(
        'Given no active jobs, '
        'When loadJobs is called, '
        'Then it should emit [JobsLoading, JobsLoaded] with empty list',
        build: () {
          when(() => mockJobsRepository.watchActiveJobs())
              .thenAnswer((_) => Stream.value([]));
          return JobsCubit(jobsRepository: mockJobsRepository);
        },
        act: (cubit) => cubit.loadJobs(),
        expect: () => [
          const JobsLoading(),
          isA<JobsLoaded>().having(
            (s) => s.jobs.isEmpty,
            'jobs is empty',
            true,
          ),
        ],
      );

      blocTest<JobsCubit, JobsState>(
        'Given the jobs stream errors, '
        'When loadJobs is called, '
        'Then it should emit [JobsLoading, JobsError]',
        build: () {
          when(() => mockJobsRepository.watchActiveJobs())
              .thenAnswer((_) => Stream.error(Exception('Network error')));
          return JobsCubit(jobsRepository: mockJobsRepository);
        },
        act: (cubit) => cubit.loadJobs(),
        expect: () => [
          const JobsLoading(),
          isA<JobsError>().having(
            (s) => s.message,
            'message',
            contains('Network error'),
          ),
        ],
      );
    });

    // -- Scenario: Post Job -------------------------------------------------
    group('Scenario: Provider posts a new job', () {
      blocTest<JobsCubit, JobsState>(
        'Given valid job data, '
        'When postJob is called, '
        'Then it should emit [JobPostSuccess]',
        build: () {
          when(() => mockJobsRepository.postJob(any()))
              .thenAnswer((_) async => 'new-job-id');
          return JobsCubit(jobsRepository: mockJobsRepository);
        },
        act: (cubit) => cubit.postJob(testJob),
        expect: () => [const JobPostSuccess('new-job-id')],
        verify: (_) {
          verify(() => mockJobsRepository.postJob(any())).called(1);
        },
      );

      blocTest<JobsCubit, JobsState>(
        'Given the server returns null, '
        'When postJob is called, '
        'Then it should emit [JobsError]',
        build: () {
          when(() => mockJobsRepository.postJob(any()))
              .thenAnswer((_) async => null);
          return JobsCubit(jobsRepository: mockJobsRepository);
        },
        act: (cubit) => cubit.postJob(testJob),
        expect: () => [
          isA<JobsError>().having(
            (s) => s.message,
            'message',
            'Failed to post job',
          ),
        ],
      );
    });
  });
}

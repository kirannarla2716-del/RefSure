import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/external_job.dart';
import 'package:refsure/features/careers_portal/data/careers_portal_repository.dart';
import 'package:refsure/features/careers_portal/presentation/cubit/careers_portal_cubit.dart';
import 'package:refsure/features/careers_portal/presentation/cubit/careers_portal_state.dart';
import 'package:refsure/services/careers_portal_service.dart';

class MockCareersPortalRepository extends Mock
    implements CareersPortalRepository {}

void main() {
  late MockCareersPortalRepository repository;
  final jobs = [
    ExternalJob(
      id: 'flutter',
      title: 'Flutter Engineer',
      company: 'Acme',
      department: 'Engineering',
      location: 'Bengaluru',
      workMode: 'Remote',
      applyUrl: 'https://example.com/flutter',
      postedAt: DateTime(2026, 7, 20),
      source: AtsPlatform.lever,
    ),
    ExternalJob(
      id: 'designer',
      title: 'Product Designer',
      company: 'Acme',
      department: 'Design',
      location: 'Mumbai',
      workMode: 'Hybrid',
      applyUrl: 'https://example.com/designer',
      postedAt: DateTime(2026, 6, 1),
      source: AtsPlatform.lever,
    ),
  ];

  CareersPortalResult result(List<ExternalJob> resultJobs) =>
      CareersPortalResult(
        jobs: resultJobs,
        platform: AtsPlatform.lever,
        companySlug: 'acme',
        totalFetched: jobs.length,
      );

  setUp(() {
    repository = MockCareersPortalRepository();
  });

  CareersPortalLoaded loadedState({
    String query = '',
    String? location,
    String? department,
    String? workMode,
  }) =>
      CareersPortalLoaded(
        jobs: jobs,
        platform: AtsPlatform.lever,
        companyName: 'Acme',
        companySlug: 'acme',
        totalFetched: jobs.length,
        query: query,
        location: location,
        department: department,
        workMode: workMode,
      );

  group('CareersPortalCubit client-side filters', () {
    blocTest<CareersPortalCubit, CareersPortalState>(
      'setters combine query, location, department, and work mode',
      build: () => CareersPortalCubit(repository: repository),
      seed: loadedState,
      act: (cubit) {
        cubit
          ..setQuery('engineer')
          ..setLocation('Bengaluru')
          ..setDepartment('Engineering')
          ..setWorkMode('Remote');
      },
      expect: () => [
        isA<CareersPortalLoaded>()
            .having((state) => state.query, 'query', 'engineer'),
        isA<CareersPortalLoaded>()
            .having((state) => state.location, 'location', 'Bengaluru'),
        isA<CareersPortalLoaded>()
            .having((state) => state.department, 'department', 'Engineering'),
        isA<CareersPortalLoaded>()
            .having((state) => state.workMode, 'work mode', 'Remote')
            .having(
          (state) => state.filteredJobs.map((job) => job.id),
          'filtered jobs',
          ['flutter'],
        ),
      ],
    );

    blocTest<CareersPortalCubit, CareersPortalState>(
      'nullable setters clear their filters and restore matches',
      build: () => CareersPortalCubit(repository: repository),
      seed: () => loadedState(
        location: 'Bengaluru',
        department: 'Engineering',
        workMode: 'Hybrid',
      ),
      act: (cubit) {
        cubit
          ..setLocation(null)
          ..setDepartment(null)
          ..setWorkMode(null);
      },
      expect: () => [
        isA<CareersPortalLoaded>().having(
          (state) => state.location,
          'location',
          isNull,
        ),
        isA<CareersPortalLoaded>().having(
          (state) => state.department,
          'department',
          isNull,
        ),
        isA<CareersPortalLoaded>()
            .having((state) => state.workMode, 'work mode', isNull)
            .having(
              (state) => state.filteredJobs.length,
              'restored jobs',
              jobs.length,
            ),
      ],
    );

    blocTest<CareersPortalCubit, CareersPortalState>(
      'clearFilters clears every client-side filter',
      build: () => CareersPortalCubit(repository: repository),
      seed: () => loadedState(
        query: 'no match',
        location: 'Bengaluru',
        department: 'Engineering',
        workMode: 'Remote',
      ),
      act: (cubit) => cubit.clearFilters(),
      expect: () => [
        isA<CareersPortalLoaded>()
            .having(
                (state) => state.hasActiveFilters, 'active filters', isFalse)
            .having(
              (state) => state.filteredJobs.length,
              'all jobs',
              jobs.length,
            ),
      ],
    );

    blocTest<CareersPortalCubit, CareersPortalState>(
      'query with no matches emits a loaded state with an empty filtered list',
      build: () => CareersPortalCubit(repository: repository),
      seed: loadedState,
      act: (cubit) => cubit.setQuery('quantum physicist'),
      expect: () => [
        isA<CareersPortalLoaded>()
            .having((state) => state.query, 'query', 'quantum physicist')
            .having((state) => state.filteredJobs, 'filtered jobs', isEmpty),
      ],
    );

    blocTest<CareersPortalCubit, CareersPortalState>(
      'filter methods no-op outside loaded state',
      build: () => CareersPortalCubit(repository: repository),
      act: (cubit) {
        cubit
          ..setQuery('engineer')
          ..setLocation('Bengaluru')
          ..setDepartment('Engineering')
          ..setWorkMode('Remote')
          ..clearFilters()
          ..toggleDateFilter();
      },
      expect: () => <CareersPortalState>[],
    );
  });

  group('CareersPortalCubit date filter interactions', () {
    blocTest<CareersPortalCubit, CareersPortalState>(
      'toggleDateFilter re-fetches with the inverse flag and clears '
      'client-side filters in the replacement result',
      setUp: () {
        when(
          () => repository.fetchJobs('Acme', filterLast30Days: true),
        ).thenAnswer((_) async => result([jobs.first]));
        when(
          () => repository.fetchJobs('Acme', filterLast30Days: false),
        ).thenAnswer((_) async => result(jobs));
      },
      build: () => CareersPortalCubit(repository: repository),
      act: (cubit) async {
        await cubit.fetchJobs('Acme');
        cubit
          ..setQuery('flutter')
          ..setLocation('Bengaluru');
        cubit.toggleDateFilter();
      },
      expect: () => [
        const CareersPortalLoading('Acme'),
        isA<CareersPortalLoaded>()
            .having((state) => state.filterLast30Days, '30-day filter', isTrue)
            .having((state) => state.jobs.length, 'jobs', 1),
        isA<CareersPortalLoaded>()
            .having((state) => state.query, 'query', 'flutter'),
        isA<CareersPortalLoaded>()
            .having((state) => state.location, 'location', 'Bengaluru'),
        const CareersPortalLoading('Acme'),
        isA<CareersPortalLoaded>()
            .having(
              (state) => state.filterLast30Days,
              '30-day filter',
              isFalse,
            )
            .having(
                (state) => state.hasActiveFilters, 'active filters', isFalse)
            .having((state) => state.jobs.length, 'jobs', 2),
      ],
      verify: (_) {
        verify(
          () => repository.fetchJobs('Acme', filterLast30Days: false),
        ).called(1);
      },
    );
  });
}

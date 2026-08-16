import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/external_job.dart';
import 'package:refsure/features/careers_portal/data/careers_portal_repository.dart';
import 'package:refsure/features/careers_portal/presentation/cubit/careers_portal_cubit.dart';
import 'package:refsure/features/careers_portal/presentation/cubit/careers_portal_state.dart';
import 'package:refsure/services/careers_portal_service.dart';

class _MockRepository extends Mock implements CareersPortalRepository {}

void main() {
  late _MockRepository repository;

  final job = ExternalJob(
    id: 'job-1',
    title: 'Platform Engineer',
    company: 'Acme',
    department: 'Engineering',
    location: 'Bengaluru',
    workMode: 'Remote',
    applyUrl: 'https://example.com/job-1',
    postedAt: DateTime(2026, 7, 20),
    source: AtsPlatform.greenhouse,
  );

  CareersPortalResult result(String company) => CareersPortalResult(
        jobs: [job],
        platform: AtsPlatform.greenhouse,
        companySlug: company.toLowerCase(),
        totalFetched: 1,
      );

  setUp(() => repository = _MockRepository());

  test('a slower old-company response cannot replace the new company',
      () async {
    final oldRequest = Completer<CareersPortalResult>();
    final newRequest = Completer<CareersPortalResult>();
    when(
      () => repository.fetchJobs('Acme', filterLast30Days: true),
    ).thenAnswer((_) => oldRequest.future);
    when(
      () => repository.fetchJobs('Globex', filterLast30Days: true),
    ).thenAnswer((_) => newRequest.future);
    final cubit = CareersPortalCubit(repository: repository);
    addTearDown(cubit.close);

    final oldFetch = cubit.fetchJobs('Acme');
    final newFetch = cubit.fetchJobs('Globex');
    newRequest.complete(result('Globex'));
    await newFetch;
    oldRequest.complete(result('Acme'));
    await oldFetch;

    expect(
      cubit.state,
      isA<CareersPortalLoaded>()
          .having((state) => state.companyName, 'company', 'Globex'),
    );
  });

  test('refresh retries the latest company after unsupported portal error',
      () async {
    var attempts = 0;
    when(
      () => repository.fetchJobs(
        'Unsupported Co',
        filterLast30Days: true,
      ),
    ).thenAnswer((_) async {
      attempts++;
      if (attempts == 1) {
        throw const CareersPortalException('Unsupported careers portal.');
      }
      return result('Unsupported Co');
    });
    final cubit = CareersPortalCubit(repository: repository);
    addTearDown(cubit.close);

    await cubit.fetchJobs('Unsupported Co');
    expect(
      cubit.state,
      isA<CareersPortalError>()
          .having((state) => state.companyName, 'company', 'Unsupported Co'),
    );

    await cubit.refresh();

    expect(attempts, 2);
    expect(cubit.state, isA<CareersPortalLoaded>());
  });

  test('active filters survive state restoration after importing a job',
      () async {
    when(
      () => repository.fetchJobs('Acme', filterLast30Days: true),
    ).thenAnswer((_) async => result('Acme'));
    when(
      () => repository.importJob(job, 'provider-1'),
    ).thenAnswer((_) async => 'refsure-job-1');
    final cubit = CareersPortalCubit(repository: repository);
    addTearDown(cubit.close);

    await cubit.fetchJobs('Acme');
    cubit.setDepartment('Engineering');
    await cubit.importJob(job, 'provider-1');

    expect(
      cubit.state,
      isA<CareersPortalLoaded>()
          .having(
            (state) => state.department,
            'department',
            'Engineering',
          )
          .having((state) => state.filteredJobs, 'jobs', [job]),
    );
  });
}

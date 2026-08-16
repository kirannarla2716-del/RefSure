import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/external_job.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/features/careers_portal/data/careers_portal_repository.dart';
import 'package:refsure/features/jobs/data/jobs_repository.dart';
import 'package:refsure/services/careers_portal_service.dart';

class _MockCareersService extends Mock implements CareersPortalService {}

class _MockJobsRepository extends Mock implements JobsRepository {}

class _FakeJob extends Fake implements Job {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeJob()));

  test(
      'Given the same external role, when posted twice, then its RefSure ID is stable',
      () async {
    final jobs = _MockJobsRepository();
    when(() => jobs.postJob(any())).thenAnswer((invocation) async {
      return (invocation.positionalArguments.single as Job).id;
    });
    final repository = CareersPortalRepository(_MockCareersService(), jobs);
    final external = ExternalJob(
      id: 'external-role-42',
      title: 'Platform Engineer',
      company: 'Acme',
      applyUrl: 'https://careers.example/42',
      postedAt: DateTime(2026, 8, 11),
      source: AtsPlatform.greenhouse,
      description:
          '&lt;h2&gt;&lt;strong&gt;About the role&lt;/strong&gt;&lt;/h2&gt;&lt;p&gt;Build &amp; operate systems.&lt;/p&gt;',
    );

    final first = await repository.importJob(external, 'provider-1');
    final second = await repository.importJob(external, 'provider-1');

    expect(first, second);
    expect(first, startsWith('career_'));
    final captured =
        verify(() => jobs.postJob(captureAny())).captured.cast<Job>();
    expect(captured.every((job) => job.jobRefId == external.id), isTrue);
    expect(
        captured.first.description, 'About the role Build & operate systems.');
    expect(captured.first.description, isNot(contains('&lt;')));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/external_job.dart';
import 'package:refsure/features/careers_portal/presentation/cubit/careers_portal_state.dart';

void main() {
  final now = DateTime.now();
  final jobs = [
    ExternalJob(
      id: 'flutter-remote',
      title: 'Senior Flutter Engineer',
      company: 'Acme',
      department: 'Engineering',
      location: 'Bengaluru',
      workMode: 'Remote',
      applyUrl: 'https://example.com/flutter',
      postedAt: now.subtract(const Duration(days: 3)),
      source: AtsPlatform.greenhouse,
    ),
    ExternalJob(
      id: 'backend-hybrid',
      title: 'Backend Engineer',
      company: 'Acme',
      department: 'Engineering',
      location: 'Hyderabad',
      workMode: 'Hybrid',
      applyUrl: 'https://example.com/backend',
      postedAt: now.subtract(const Duration(days: 45)),
      source: AtsPlatform.greenhouse,
    ),
    ExternalJob(
      id: 'recruiter-onsite',
      title: 'Technical Recruiter',
      company: 'Acme',
      department: 'People',
      location: 'Bengaluru',
      workMode: 'On-site',
      applyUrl: 'https://example.com/recruiter',
      postedAt: now.subtract(const Duration(days: 10)),
      source: AtsPlatform.greenhouse,
    ),
  ];

  CareersPortalLoaded loaded({
    List<ExternalJob>? sourceJobs,
    bool filterLast30Days = true,
    String query = '',
    String? location,
    String? department,
    String? workMode,
  }) =>
      CareersPortalLoaded(
        jobs: sourceJobs ?? jobs,
        platform: AtsPlatform.greenhouse,
        companyName: 'Acme',
        companySlug: 'acme',
        totalFetched: jobs.length,
        filterLast30Days: filterLast30Days,
        query: query,
        location: location,
        department: department,
        workMode: workMode,
      );

  group('CareersPortalLoaded filtering', () {
    test(
        'query searches title, department, location, and work mode '
        'case-insensitively', () {
      expect(
        loaded(query: '  FLUTTER ').filteredJobs.map((job) => job.id),
        ['flutter-remote'],
      );
      expect(
        loaded(query: 'people').filteredJobs.map((job) => job.id),
        ['recruiter-onsite'],
      );
      expect(
        loaded(query: 'hyderabad').filteredJobs.map((job) => job.id),
        ['backend-hybrid'],
      );
      expect(
        loaded(query: 'on-SITE').filteredJobs.map((job) => job.id),
        ['recruiter-onsite'],
      );
    });

    test('combines query, location, department, and work mode', () {
      final state = loaded(
        query: 'engineer',
        location: 'Bengaluru',
        department: 'Engineering',
        workMode: 'Remote',
      );

      expect(state.filteredJobs.map((job) => job.id), ['flutter-remote']);
      expect(state.hasActiveFilters, isTrue);
    });

    test('returns no matches when any exact-match facet conflicts', () {
      final state = loaded(
        query: 'engineer',
        location: 'Bengaluru',
        department: 'Engineering',
        workMode: 'Hybrid',
      );

      expect(state.filteredJobs, isEmpty);
    });

    test('derives sorted distinct non-empty facet options', () {
      final extraJob = ExternalJob(
        id: 'empty-facets',
        title: 'Generalist',
        company: 'Acme',
        department: ' ',
        location: null,
        workMode: '',
        applyUrl: 'https://example.com/generalist',
        postedAt: now,
        source: AtsPlatform.greenhouse,
      );
      final state = loaded(sourceJobs: [...jobs, extraJob]);

      expect(state.locations, ['Bengaluru', 'Hyderabad']);
      expect(state.departments, ['Engineering', 'People']);
      expect(state.workModes, ['Hybrid', 'On-site', 'Remote']);
    });

    test('date flag does not independently filter already-fetched jobs', () {
      expect(
        loaded(filterLast30Days: true).filteredJobs.map((job) => job.id),
        ['flutter-remote', 'backend-hybrid', 'recruiter-onsite'],
      );
      expect(
        loaded(filterLast30Days: false).filteredJobs.map((job) => job.id),
        ['flutter-remote', 'backend-hybrid', 'recruiter-onsite'],
      );
    });
  });

  group('CareersPortalLoaded copyWith', () {
    test('preserves all values when no arguments are supplied', () {
      final original = loaded(
        query: 'engineer',
        location: 'Bengaluru',
        department: 'Engineering',
        workMode: 'Remote',
      );

      expect(original.copyWith(), original);
    });

    test('updates fields independently without mutating job metadata', () {
      final original = loaded(location: 'Bengaluru');
      final updated = original.copyWith(
        query: 'backend',
        filterLast30Days: false,
      );

      expect(updated.query, 'backend');
      expect(updated.location, 'Bengaluru');
      expect(updated.filterLast30Days, isFalse);
      expect(updated.jobs, same(original.jobs));
      expect(updated.companyName, original.companyName);
      expect(updated.totalFetched, original.totalFetched);
    });

    test('explicit null clears each nullable filter', () {
      final original = loaded(
        location: 'Bengaluru',
        department: 'Engineering',
        workMode: 'Remote',
      );
      final updated = original.copyWith(
        location: null,
        department: null,
        workMode: null,
      );

      expect(updated.location, isNull);
      expect(updated.department, isNull);
      expect(updated.workMode, isNull);
      expect(updated.hasActiveFilters, isFalse);
    });

    test('blank query is not considered an active filter', () {
      expect(loaded(query: '   ').hasActiveFilters, isFalse);
    });
  });
}

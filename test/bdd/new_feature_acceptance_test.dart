import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/feature_readiness.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/core/presentation/role_labels.dart';
import 'package:refsure/core/policies/application_transition_policy.dart';
import 'package:refsure/core/policies/provider_job_policy.dart';
import 'package:refsure/providers/app_provider.dart';

void main() {
  group('Feature: consistent referral mode naming', () {
    test(
        'Given a seeker, when the mode label is rendered, then casing is canonical',
        () {
      expect(RoleLabels.mode(UserRole.seeker), 'Referral-SEEKER Mode');
    });

    test(
        'Given a provider, when the mode label is rendered, then casing is canonical',
        () {
      expect(RoleLabels.mode(UserRole.provider), 'Referral-PROVIDER Mode');
    });
  });

  group('Feature: five-check release gate', () {
    test(
        'Given one missing check, when readiness is evaluated, then feature is unavailable',
        () {
      final readiness = FeatureReadiness(
        featureName: 'Investor experience',
        passed: FeatureCheck.values
            .where((check) => check != FeatureCheck.usability)
            .toSet(),
      );
      expect(readiness.isAvailable, isFalse);
    });

    test(
        'Given all five checks, when readiness is evaluated, then feature is eligible',
        () {
      final readiness = FeatureReadiness(
        featureName: 'Investor experience',
        passed: FeatureCheck.values.toSet(),
      );
      expect(readiness.isAvailable, isTrue);
    });
  });

  test(
      'Given today\'s demo jobs, when counted, then the notification has an exact total',
      () {
    final today = DateTime(2026, 8, 11, 9);
    final jobs = buildDemoJobs('provider-1', postedAt: today);
    expect(jobs.where((job) => job.postedAt == today), hasLength(3));
  });

  group('Feature: provider-specific jobs workspace', () {
    test(
        'Given mixed jobs, when provider jobs load, then only owned positions appear',
        () {
      final own = buildDemoJobs('provider-1');
      final other = buildDemoJobs('provider-2')
          .map((job) => Job(
                id: 'other-${job.id}',
                providerId: job.providerId,
                company: job.company,
                companyLogo: job.companyLogo,
                title: job.title,
                department: job.department,
                location: job.location,
                workMode: job.workMode,
                minExp: job.minExp,
                maxExp: job.maxExp,
                skills: job.skills,
                description: job.description,
                deadline: job.deadline,
              ))
          .toList();

      final visible =
          ProviderJobPolicy.ownedJobs([...own, ...other], 'provider-1');

      expect(visible, hasLength(3));
      expect(visible.every((job) => job.providerId == 'provider-1'), isTrue);
    });

    test(
        'Given another provider\'s job, when opened, then management is denied',
        () {
      final job = buildDemoJobs('provider-2').first;
      expect(ProviderJobPolicy.canManage(job, 'provider-1'), isFalse);
    });

    test(
        'Given seeded positions, when provider mode opens, then candidates are grouped by job',
        () {
      final applications = buildDemoProviderApplications('provider-1');
      expect(applications.where((app) => app.jobId == 'seed_job_001'),
          hasLength(2));
      expect(applications.where((app) => app.jobId == 'seed_job_002'),
          hasLength(1));
    });

    test(
        'Given a referred candidate, when actions render, then invalid earlier actions are hidden',
        () {
      expect(
          ApplicationTransitionPolicy.allows(
              AppStatus.referred, AppStatus.underReview),
          isFalse);
      expect(
          ApplicationTransitionPolicy.allows(
              AppStatus.referred, AppStatus.shortlisted),
          isFalse);
      expect(
          ApplicationTransitionPolicy.allows(
              AppStatus.referred, AppStatus.notSelected),
          isTrue);
    });

    test(
        'Given a pending request, seeker withdrawal and provider response are explicit',
        () {
      expect(
          ApplicationTransitionPolicy.allows(
              AppStatus.pending, AppStatus.accepted),
          isTrue);
      expect(
          ApplicationTransitionPolicy.allows(
              AppStatus.pending, AppStatus.declined),
          isTrue);
      expect(
          ApplicationTransitionPolicy.allows(
              AppStatus.pending, AppStatus.withdrawn),
          isTrue);
      expect(
          ApplicationTransitionPolicy.allows(
              AppStatus.withdrawn, AppStatus.underReview),
          isFalse);
    });
  });

  group('Feature: complete local demo data', () {
    test('Given debug demo mode, every seeker data module is populated', () {
      final providers = buildDemoProviders();
      final applications = buildDemoSeekerApplications('seeker-1');
      final notifications = buildDemoNotifications('seeker-1');

      expect(buildDemoJobs('seeker-1'), hasLength(3));
      expect(providers, hasLength(6));
      expect(applications, hasLength(8));
      expect(notifications, hasLength(5));
      expect(
        applications.every(
          (application) => providers.any(
            (provider) => provider.id == application.providerId,
          ),
        ),
        isTrue,
      );
      expect(notifications.where((notification) => !notification.read),
          hasLength(3));
      expect(buildDemoProfile('seeker-1').resumeUrl, isNotEmpty);
      expect(
          buildDemoConversation('seeker-1', providers.first.id), hasLength(3));
    });

    test('Given provider mode, owned jobs and candidates are populated', () {
      const providerId = 'provider-1';
      final jobs = buildDemoJobs(providerId);
      final candidates = buildDemoCandidates();
      final applications = buildDemoProviderApplications(providerId);

      expect(jobs.every((job) => job.providerId == providerId), isTrue);
      expect(candidates, hasLength(3));
      expect(applications, hasLength(3));
      expect(
        applications.every(
          (application) => candidates.any(
            (candidate) => candidate.id == application.seekerId,
          ),
        ),
        isTrue,
      );
    });
  });
}

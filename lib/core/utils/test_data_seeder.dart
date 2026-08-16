// ignore_for_file: require_trailing_commas
// lib/core/utils/test_data_seeder.dart
//
// Writes realistic QA seed data into Firestore so every screen in RefSure
// can be exercised without manual data entry.
//
// ─── GUARD ─────────────────────────────────────────────────────────────────
//   Checks _meta/seed_status version. Bump _kVersion to force a re-seed.
// ───────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Controls startup-only demo behavior.
///
/// Debug builds remain ready for local testing. A non-debug demo build must
/// opt in explicitly with `--dart-define=REFSURE_DEMO_MODE=true`.
class DemoModePolicy {
  const DemoModePolicy._();

  static const bool _explicitDemoMode = bool.fromEnvironment(
    'REFSURE_DEMO_MODE',
  );

  static bool get isEnabled => evaluate(
        isDebugBuild: kDebugMode,
        explicitDemoMode: _explicitDemoMode,
      );

  @visibleForTesting
  static bool evaluate({
    required bool isDebugBuild,
    required bool explicitDemoMode,
  }) =>
      isDebugBuild || explicitDemoMode;
}

class TestDataSeeder {
  TestDataSeeder._();

  static const _metaCollection = '_meta';
  static const _guardDocId     = 'seed_status';
  static const _kVersion       = 7; // bump to re-seed

  // Deterministic IDs so re-seeding is idempotent
  static const _jobIds = [
    'seed_job_001', 'seed_job_002', 'seed_job_003', 'seed_job_004', 'seed_job_005',
    'seed_job_006', 'seed_job_007', 'seed_job_008', 'seed_job_009', 'seed_job_010',
    'seed_job_011', 'seed_job_012', 'seed_job_013', 'seed_job_014', 'seed_job_015',
  ];

  static const _providerIds = [
    'seed_provider_001', 'seed_provider_002', 'seed_provider_003',
    'seed_provider_004', 'seed_provider_005', 'seed_provider_006',
  ];

  static const _appIds = [
    'seed_app_001', 'seed_app_002', 'seed_app_003', 'seed_app_004',
    'seed_app_005', 'seed_app_006', 'seed_app_007', 'seed_app_008',
  ];

  static const _msgIds = [
    'seed_msg_001', 'seed_msg_002', 'seed_msg_003', 'seed_msg_004',
    'seed_msg_005', 'seed_msg_006', 'seed_msg_007', 'seed_msg_008',
    'seed_msg_009', 'seed_msg_010',
  ];

  static const _notifIds = [
    'seed_notif_001', 'seed_notif_002', 'seed_notif_003',
    'seed_notif_004', 'seed_notif_005',
  ];

  /// Seeds the full QA dataset only when startup demo behavior is enabled.
  static Future<bool> seedAutomatically(
    FirebaseFirestore db, {
    String? currentUserId,
  }) async {
    if (!DemoModePolicy.isEnabled) return false;
    await seed(db, currentUserId: currentUserId);
    return true;
  }

  // ── Public entry point ───────────────────────────────────────────────────
  static Future<void> seed(FirebaseFirestore db, {String? currentUserId}) async {
    final guard = await db.collection(_metaCollection).doc(_guardDocId).get();
    if (guard.exists && (guard.data()?['version'] as int? ?? 0) >= _kVersion) return;

    final now = Timestamp.now();
    final uid = currentUserId ?? 'seed_user';

    // Batch 1: Create/upsert current user profile (set+merge works even if doc missing)
    if (currentUserId != null) {
      final b = db.batch();
      b.set(db.collection('users').doc(currentUserId), {
        'id': currentUserId,
        'name': 'Kiran Narla',
        'email': 'demo@refsure.app',
        'headline': 'Senior Flutter Developer · Open to referrals',
        'title': 'Senior Flutter Developer',
        'location': 'Bangalore',
        'experience': 5,
        'skills': ['Flutter', 'Dart', 'Firebase', 'Product Management', 'Figma'],
        'preferredRoles': ['Flutter Developer', 'Product Manager', 'Mobile Lead'],
        'bio': 'Senior Flutter developer with 5 years building consumer apps at scale. '
            'Open to referrals at top-tier product companies.',
        'activelyLooking': true,
        'profileComplete': 90,
        'role': 'seeker',
        'noticePeriod': '30 days',
        'expectedSalary': '35',
        'photoUrl': null,
        'resumeUrl': 'https://www.w3.org/WAI/WCAG21/Techniques/pdf/pdf-sample.pdf',
        'linkedinUrl': 'https://linkedin.com/in/kirannarla',
        'verified': false,
        'orgVerified': false,
        'orgEmail': null,
        'referralsReceived': 8,
        'referralsMade': 0,
        'successfulReferrals': 0,
        'totalJobsPosted': 0,
        'successRate': 0,
        'responseRate': null,
        'trustScore': 0.0,
        'gratitudesReceived': 3,
        'onboardingSource': 'email',
        'createdAt': now,
        'updatedAt': now,
        'lastActiveAt': now,
      }, SetOptions(merge: true));
      await b.commit();
    }

    // Batch 1b: Referral providers (so the Referrers tab + leaderboard populate).
    // Rules allow any authenticated user to CREATE user docs, so this is permitted.
    final bp = db.batch();
    final providers = _buildProviders(now);
    for (var i = 0; i < providers.length && i < _providerIds.length; i++) {
      bp.set(db.collection('users').doc(_providerIds[i]),
          {...providers[i], 'id': _providerIds[i]}, SetOptions(merge: true));
    }
    await bp.commit();

    // Batch 2: 15 Jobs (all providerId = uid to satisfy live Firestore rules)
    final jobs = _buildJobs(now, providerId: uid);
    // Firestore batch limit is 500 ops; split into two batches just to be safe
    final b2a = db.batch();
    for (var i = 0; i < 8 && i < jobs.length; i++) {
      b2a.set(db.collection('jobs').doc(_jobIds[i]),
          {...jobs[i], 'id': _jobIds[i]}, SetOptions(merge: false));
    }
    await b2a.commit();

    final b2b = db.batch();
    for (var i = 8; i < jobs.length; i++) {
      b2b.set(db.collection('jobs').doc(_jobIds[i]),
          {...jobs[i], 'id': _jobIds[i]}, SetOptions(merge: false));
    }
    await b2b.commit();

    // Batch 3: 8 Applications (seekerId = uid)
    final b3 = db.batch();
    final apps = _buildApplications(uid, now);
    for (var i = 0; i < apps.length; i++) {
      b3.set(db.collection('applications').doc(_appIds[i]),
          {...apps[i], 'id': _appIds[i]}, SetOptions(merge: false));
    }
    await b3.commit();

    // Batch 4: Messages (fromId or toId = uid)
    final b4 = db.batch();
    final msgs = _buildMessages(uid, now);
    for (var i = 0; i < msgs.length; i++) {
      b4.set(db.collection('messages').doc(_msgIds[i]),
          msgs[i], SetOptions(merge: false));
    }
    await b4.commit();

    // Batch 5: Notifications (userId = uid)
    final b5 = db.batch();
    final notifs = _buildNotifications(uid, now);
    for (var i = 0; i < notifs.length; i++) {
      b5.set(db.collection('notifications').doc(_notifIds[i]),
          notifs[i], SetOptions(merge: false));
    }
    await b5.commit();

    // Guard doc — write last
    final b6 = db.batch();
    b6.set(db.collection(_metaCollection).doc(_guardDocId), {
      'seededAt': now,
      'version': _kVersion,
      'collections': ['users', 'jobs', 'applications', 'messages', 'notifications'],
    });
    await b6.commit();
  }

  // ── Referral providers ────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _buildProviders(Timestamp now) {
    Map<String, dynamic> p({
      required String name,
      required String company,
      required String title,
      required String location,
      required List<String> skills,
      required int experience,
      required int referralsMade,
      required int successfulReferrals,
      required int gratitudesReceived,
      required bool verified,
      required bool orgVerified,
      required double responseRate,
      required int avgResponseHours,
      String? headline,
    }) => {
          'role': 'provider',
          'name': name,
          'company': company,
          'currentCompany': company,
          'title': title,
          'headline': headline ?? '$title at $company · Happy to refer',
          'location': location,
          'experience': experience,
          'skills': skills,
          'preferredRoles': const <String>[],
          'bio': 'I refer strong candidates at $company. '
              'Send a tailored note and your resume and I will take a look.',
          'photoUrl': null,
          'email': '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
          'orgEmail': orgVerified
              ? '${name.toLowerCase().split(' ').first}@${company.toLowerCase().replaceAll(' ', '')}.com'
              : null,
          'linkedinUrl': 'https://linkedin.com/in/${name.toLowerCase().replaceAll(' ', '')}',
          'resumeUrl': null,
          'verified': verified,
          'orgVerified': orgVerified,
          'activelyLooking': false,
          'profileComplete': 95,
          'referralsReceived': 0,
          'referralsMade': referralsMade,
          'successfulReferrals': successfulReferrals,
          'totalJobsPosted': 2 + (referralsMade ~/ 5),
          'successRate': successfulReferrals == 0
              ? 0
              : ((successfulReferrals / referralsMade) * 100).round(),
          'responseTime': avgResponseHours <= 12 ? '< 12h' : '< 48h',
          'avgResponseHours': avgResponseHours,
          'responseRate': responseRate,
          // trustScore is recomputed by toFirestore() in the app, but seed an
          // explicit value here so watchProviders() can sort immediately.
          'trustScore': (orgVerified ? 30 : 0) +
              (verified ? 20 : 0) +
              15 +
              (responseRate >= 0.8 ? 10 : 0) +
              (referralsMade >= 5 ? 5 : 0) +
              (referralsMade >= 10 ? 5 : 0) +
              (referralsMade >= 20 ? 5 : 0) +
              (referralsMade >= 30 ? 5 : 0),
          'gratitudesReceived': gratitudesReceived,
          'onboardingSource': 'email',
          'createdAt': now,
          'updatedAt': now,
          'lastActiveAt': now,
        };

    return [
      p(name: 'Aarav Mehta', company: 'Google India', title: 'Staff Software Engineer',
        location: 'Bangalore', skills: ['Flutter', 'Dart', 'Go', 'Kubernetes'],
        experience: 9, referralsMade: 34, successfulReferrals: 21, gratitudesReceived: 27,
        verified: true, orgVerified: true, responseRate: 0.95, avgResponseHours: 8),
      p(name: 'Priya Sharma', company: 'Swiggy', title: 'Group Product Manager',
        location: 'Bangalore', skills: ['Product Management', 'Analytics', 'A/B Testing'],
        experience: 8, referralsMade: 22, successfulReferrals: 12, gratitudesReceived: 18,
        verified: true, orgVerified: true, responseRate: 0.9, avgResponseHours: 10),
      p(name: 'Rohan Verma', company: 'Amazon', title: 'SDE-III',
        location: 'Hyderabad', skills: ['React', 'TypeScript', 'GraphQL', 'AWS'],
        experience: 7, referralsMade: 15, successfulReferrals: 8, gratitudesReceived: 11,
        verified: true, orgVerified: false, responseRate: 0.82, avgResponseHours: 24),
      p(name: 'Ananya Iyer', company: 'Flipkart', title: 'Senior Data Engineer',
        location: 'Bangalore', skills: ['Python', 'Spark', 'Kafka', 'Airflow'],
        experience: 6, referralsMade: 11, successfulReferrals: 5, gratitudesReceived: 9,
        verified: false, orgVerified: true, responseRate: 0.88, avgResponseHours: 18),
      p(name: 'Karthik Nair', company: 'Microsoft', title: 'Principal Engineer',
        location: 'Hyderabad', skills: ['C#', '.NET', 'Azure', 'Distributed Systems'],
        experience: 12, referralsMade: 28, successfulReferrals: 17, gratitudesReceived: 22,
        verified: true, orgVerified: true, responseRate: 0.93, avgResponseHours: 12),
      p(name: 'Sneha Reddy', company: 'Razorpay', title: 'Engineering Manager',
        location: 'Bangalore', skills: ['Java', 'Spring', 'Microservices', 'System Design'],
        experience: 10, referralsMade: 6, successfulReferrals: 3, gratitudesReceived: 5,
        verified: true, orgVerified: false, responseRate: 0.8, avgResponseHours: 36),
    ];
  }

  // ── Jobs ─────────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _buildJobs(Timestamp now, {required String providerId}) {
    return [
      // 001 — Google Flutter
      {
        'providerId': providerId, 'company': 'Google India', 'companyLogo': 'G',
        'title': 'Senior Flutter Developer', 'department': 'Mobile Platform',
        'location': 'Bangalore', 'workMode': 'Remote',
        'minExp': 4, 'maxExp': 8, 'salaryMin': 40, 'salaryMax': 60,
        'skills': ['Flutter', 'Dart', 'Firebase'],
        'preferredSkills': ['Go', 'gRPC', 'Kubernetes'],
        'tags': ['mobile', 'flutter', 'remote'],
        'description': 'Join Google India\'s Mobile Platform team to build next-generation Flutter '
            'apps used by hundreds of millions of users worldwide. You will own critical '
            'features end-to-end, work with world-class engineers, and ship code that '
            'reaches users across Android and iOS. Strong Flutter and Dart skills required.',
        'providerNote': 'Hiring bar is high — open-source Flutter contributions help.',
        'status': 'active', 'applicants': 23, 'viewCount': 145,
        'deadline': '2026-08-31', 'postedAt': now, 'jobRefId': 'GGL-FLT-2026',
        'isHot': true, 'source': 'manual', 'externalUrl': null,
      },
      // 002 — Swiggy PM
      {
        'providerId': providerId, 'company': 'Swiggy', 'companyLogo': 'S',
        'title': 'Product Manager – Consumer Growth', 'department': 'Consumer',
        'location': 'Bangalore', 'workMode': 'Hybrid',
        'minExp': 3, 'maxExp': 6, 'salaryMin': 25, 'salaryMax': 35,
        'skills': ['Product Management', 'Analytics', 'Figma'],
        'preferredSkills': ['SQL', 'A/B Testing'],
        'tags': ['product', 'growth'],
        'description': 'Drive growth for Swiggy\'s core consumer experience. Define the '
            'product roadmap for acquisition and retention features, run A/B experiments, '
            'and collaborate with design, data, and engineering to ship impactful features.',
        'providerNote': null,
        'status': 'active', 'applicants': 18, 'viewCount': 112,
        'deadline': '2026-08-15', 'postedAt': now, 'jobRefId': 'SWG-PM-2026',
        'isHot': false, 'source': 'manual', 'externalUrl': null,
      },
      // 003 — Amazon SDE-II Frontend
      {
        'providerId': providerId, 'company': 'Amazon', 'companyLogo': 'A',
        'title': 'SDE-II Frontend', 'department': 'Prime Video',
        'location': 'Hyderabad', 'workMode': 'Hybrid',
        'minExp': 3, 'maxExp': 6, 'salaryMin': 28, 'salaryMax': 40,
        'skills': ['React', 'JavaScript', 'TypeScript'],
        'preferredSkills': ['GraphQL', 'Redux'],
        'tags': ['frontend', 'react'],
        'description': 'Build the Prime Video web experience serving 200M+ subscribers. '
            'Own critical player UI components, streaming quality dashboards, '
            'and the recommendation carousel. Strong React and TypeScript fundamentals required.',
        'providerNote': 'Focus on Leadership Principles in the interview.',
        'status': 'active', 'applicants': 41, 'viewCount': 230,
        'deadline': '2026-09-01', 'postedAt': now, 'jobRefId': 'AMZ-SDE2-2026',
        'isHot': false, 'source': 'manual', 'externalUrl': null,
      },
      // 004 — Flipkart Data Engineer
      {
        'providerId': providerId, 'company': 'Flipkart', 'companyLogo': 'F',
        'title': 'Data Engineer', 'department': 'Data Platform',
        'location': 'Bangalore', 'workMode': 'Hybrid',
        'minExp': 2, 'maxExp': 5, 'salaryMin': 18, 'salaryMax': 28,
        'skills': ['Python', 'Spark', 'SQL'],
        'preferredSkills': ['Kafka', 'dbt', 'Airflow'],
        'tags': ['data', 'backend', 'python'],
        'description': 'Join Flipkart\'s Data Platform team to build scalable ETL pipelines '
            'processing petabytes of e-commerce data daily. Own pipeline reliability, '
            'design data models, and enable analytics across business units.',
        'providerNote': null,
        'status': 'active', 'applicants': 29, 'viewCount': 175,
        'deadline': '2026-08-20', 'postedAt': now, 'jobRefId': 'FLK-DE-2026',
        'isHot': false, 'source': 'manual', 'externalUrl': null,
      },
      // 005 — Zepto Growth Manager
      {
        'providerId': providerId, 'company': 'Zepto', 'companyLogo': 'Z',
        'title': 'Growth Manager', 'department': 'Marketing',
        'location': 'Mumbai', 'workMode': 'On-site',
        'minExp': 2, 'maxExp': 5, 'salaryMin': 15, 'salaryMax': 22,
        'skills': ['Growth', 'Analytics', 'SQL'],
        'preferredSkills': ['Firebase Analytics', 'Clevertap', 'Meta Ads'],
        'tags': ['growth', 'marketing', 'startup'],
        'description': 'Drive user acquisition and retention for Zepto\'s 10-minute grocery '
            'delivery across 25 cities. Own paid performance channels, referral programmes, '
            'and reactivation campaigns.',
        'providerNote': null,
        'status': 'active', 'applicants': 12, 'viewCount': 89,
        'deadline': '2026-07-31', 'postedAt': now, 'jobRefId': 'ZPT-GM-2026',
        'isHot': true, 'source': 'manual', 'externalUrl': null,
      },
      // 006 — Razorpay UX Designer
      {
        'providerId': providerId, 'company': 'Razorpay', 'companyLogo': 'R',
        'title': 'Senior UX Designer', 'department': 'Design',
        'location': 'Bangalore', 'workMode': 'Hybrid',
        'minExp': 3, 'maxExp': 6, 'salaryMin': 18, 'salaryMax': 28,
        'skills': ['Figma', 'UX Research', 'Prototyping'],
        'preferredSkills': ['Framer', 'Design Systems'],
        'tags': ['design', 'ux', 'fintech'],
        'description': 'Shape Razorpay\'s merchant and consumer products used by 8M+ businesses. '
            'Conduct user research, create high-fidelity prototypes, and maintain the design system.',
        'providerNote': null,
        'status': 'active', 'applicants': 8, 'viewCount': 64,
        'deadline': '2026-08-10', 'postedAt': now, 'jobRefId': 'RPY-UX-2026',
        'isHot': false, 'source': 'manual', 'externalUrl': null,
      },
      // 007 — CRED Android Engineer
      {
        'providerId': providerId, 'company': 'CRED', 'companyLogo': 'C',
        'title': 'Android Engineer – Platform', 'department': 'Mobile Platform',
        'location': 'Bangalore', 'workMode': 'Hybrid',
        'minExp': 3, 'maxExp': 7, 'salaryMin': 30, 'salaryMax': 45,
        'skills': ['Kotlin', 'Android SDK', 'Jetpack Compose'],
        'preferredSkills': ['GraphQL', 'Coroutines', 'Dagger'],
        'tags': ['android', 'mobile', 'fintech'],
        'description': 'Build CRED\'s Android platform powering 10M+ premium users. '
            'Own the performance infrastructure, build reusable UI components, '
            'and drive adoption of Jetpack Compose across the codebase.',
        'providerNote': 'Strong Kotlin fundamentals and Compose experience are a must.',
        'status': 'active', 'applicants': 19, 'viewCount': 138,
        'deadline': '2026-08-25', 'postedAt': now, 'jobRefId': 'CRD-AND-2026',
        'isHot': true, 'source': 'manual', 'externalUrl': null,
      },
      // 008 — Meesho Backend SDE-III
      {
        'providerId': providerId, 'company': 'Meesho', 'companyLogo': 'M',
        'title': 'Backend SDE-III', 'department': 'Seller Platform',
        'location': 'Bangalore', 'workMode': 'Hybrid',
        'minExp': 5, 'maxExp': 9, 'salaryMin': 35, 'salaryMax': 55,
        'skills': ['Java', 'Spring Boot', 'MySQL', 'Kafka'],
        'preferredSkills': ['Redis', 'Microservices', 'AWS'],
        'tags': ['backend', 'java', 'ecommerce'],
        'description': 'Drive seller-side scalability for Meesho\'s 1M+ seller base. '
            'Design and build high-throughput backend services, own reliability SLOs, '
            'and mentor junior engineers on the team.',
        'providerNote': null,
        'status': 'active', 'applicants': 34, 'viewCount': 210,
        'deadline': '2026-09-05', 'postedAt': now, 'jobRefId': 'MSH-SDE3-2026',
        'isHot': false, 'source': 'manual', 'externalUrl': null,
      },
      // 009 — PhonePe ML Engineer
      {
        'providerId': providerId, 'company': 'PhonePe', 'companyLogo': 'P',
        'title': 'ML Engineer – Fraud Detection', 'department': 'Risk',
        'location': 'Bangalore', 'workMode': 'On-site',
        'minExp': 3, 'maxExp': 7, 'salaryMin': 32, 'salaryMax': 50,
        'skills': ['Python', 'TensorFlow', 'SQL', 'Feature Engineering'],
        'preferredSkills': ['PySpark', 'Kafka', 'Kubernetes'],
        'tags': ['ml', 'ai', 'fintech'],
        'description': 'Build real-time fraud detection models for PhonePe\'s 500M+ '
            'transaction platform. Own the full ML lifecycle: feature engineering, '
            'model training, A/B testing, and production monitoring.',
        'providerNote': 'Experience with streaming data (Kafka / Flink) is a strong differentiator.',
        'status': 'active', 'applicants': 27, 'viewCount': 189,
        'deadline': '2026-08-28', 'postedAt': now, 'jobRefId': 'PPE-MLE-2026',
        'isHot': true, 'source': 'manual', 'externalUrl': null,
      },
      // 010 — Ola SDE-II iOS
      {
        'providerId': providerId, 'company': 'Ola', 'companyLogo': 'O',
        'title': 'SDE-II iOS', 'department': 'Consumer App',
        'location': 'Bangalore', 'workMode': 'Hybrid',
        'minExp': 2, 'maxExp': 5, 'salaryMin': 22, 'salaryMax': 35,
        'skills': ['Swift', 'UIKit', 'Xcode'],
        'preferredSkills': ['SwiftUI', 'Combine', 'Core Data'],
        'tags': ['ios', 'mobile', 'consumer'],
        'description': 'Build the Ola rider app used by 150M+ users across India and international markets. '
            'Own ride booking, maps integration, and payments flows on iOS.',
        'providerNote': null,
        'status': 'active', 'applicants': 15, 'viewCount': 95,
        'deadline': '2026-08-18', 'postedAt': now, 'jobRefId': 'OLA-IOS-2026',
        'isHot': false, 'source': 'manual', 'externalUrl': null,
      },
      // 011 — Zomato SRE
      {
        'providerId': providerId, 'company': 'Zomato', 'companyLogo': 'Z',
        'title': 'Site Reliability Engineer', 'department': 'Infrastructure',
        'location': 'Gurgaon', 'workMode': 'Hybrid',
        'minExp': 4, 'maxExp': 8, 'salaryMin': 30, 'salaryMax': 48,
        'skills': ['Kubernetes', 'Terraform', 'Go', 'Prometheus'],
        'preferredSkills': ['Istio', 'Helm', 'ClickHouse'],
        'tags': ['devops', 'sre', 'infra'],
        'description': 'Keep Zomato\'s food delivery infrastructure running at 99.99% uptime '
            'across 1000+ cities. Own on-call rotations, lead incident response, '
            'and drive reliability improvements across microservices.',
        'providerNote': null,
        'status': 'active', 'applicants': 11, 'viewCount': 74,
        'deadline': '2026-09-10', 'postedAt': now, 'jobRefId': 'ZMT-SRE-2026',
        'isHot': false, 'source': 'manual', 'externalUrl': null,
      },
      // 012 — Paytm Backend Lead
      {
        'providerId': providerId, 'company': 'Paytm', 'companyLogo': 'P',
        'title': 'Backend Lead – Payments', 'department': 'Payments',
        'location': 'Noida', 'workMode': 'Hybrid',
        'minExp': 7, 'maxExp': 12, 'salaryMin': 45, 'salaryMax': 70,
        'skills': ['Java', 'Go', 'Kafka', 'System Design'],
        'preferredSkills': ['gRPC', 'Redis', 'PostgreSQL'],
        'tags': ['backend', 'payments', 'lead'],
        'description': 'Lead a team of 6 engineers building Paytm\'s core payment processing engine '
            'handling 1B+ transactions per month. Define architecture, own reliability, '
            'and mentor senior engineers.',
        'providerNote': 'Leadership and system design depth are key hiring criteria.',
        'status': 'active', 'applicants': 7, 'viewCount': 58,
        'deadline': '2026-09-15', 'postedAt': now, 'jobRefId': 'PTM-BL-2026',
        'isHot': false, 'source': 'manual', 'externalUrl': null,
      },
      // 013 — Nykaa Frontend SDE-II
      {
        'providerId': providerId, 'company': 'Nykaa', 'companyLogo': 'N',
        'title': 'Frontend SDE-II', 'department': 'Beauty Commerce',
        'location': 'Mumbai', 'workMode': 'On-site',
        'minExp': 2, 'maxExp': 5, 'salaryMin': 18, 'salaryMax': 28,
        'skills': ['React', 'Next.js', 'TypeScript'],
        'preferredSkills': ['Storybook', 'Performance Optimization', 'A/B Testing'],
        'tags': ['frontend', 'react', 'ecommerce'],
        'description': 'Build Nykaa\'s beauty e-commerce web experience reaching 7M+ active users. '
            'Own product listing pages, checkout flow, and personalisation widgets.',
        'providerNote': null,
        'status': 'active', 'applicants': 22, 'viewCount': 143,
        'deadline': '2026-08-22', 'postedAt': now, 'jobRefId': 'NYK-FE-2026',
        'isHot': false, 'source': 'manual', 'externalUrl': null,
      },
      // 014 — BrowserStack QA Engineer
      {
        'providerId': providerId, 'company': 'BrowserStack', 'companyLogo': 'B',
        'title': 'Senior QA Engineer', 'department': 'Platform QA',
        'location': 'Mumbai', 'workMode': 'Remote',
        'minExp': 3, 'maxExp': 6, 'salaryMin': 20, 'salaryMax': 32,
        'skills': ['Selenium', 'Cypress', 'JavaScript'],
        'preferredSkills': ['Playwright', 'Appium', 'CI/CD'],
        'tags': ['qa', 'testing', 'remote'],
        'description': 'Ensure quality for BrowserStack\'s testing infrastructure used by '
            '50,000+ businesses. Build and maintain end-to-end test suites, '
            'drive shift-left testing culture, and own the CI quality gates.',
        'providerNote': null,
        'status': 'active', 'applicants': 9, 'viewCount': 67,
        'deadline': '2026-08-30', 'postedAt': now, 'jobRefId': 'BSK-QA-2026',
        'isHot': false, 'source': 'manual', 'externalUrl': null,
      },
      // 015 — Dunzo Technical PM
      {
        'providerId': providerId, 'company': 'Dunzo', 'companyLogo': 'D',
        'title': 'Technical Product Manager', 'department': 'Platform',
        'location': 'Bangalore', 'workMode': 'Hybrid',
        'minExp': 4, 'maxExp': 8, 'salaryMin': 28, 'salaryMax': 42,
        'skills': ['Product Management', 'SQL', 'API Design'],
        'preferredSkills': ['Figma', 'Agile', 'Python'],
        'tags': ['product', 'technical', 'quickcommerce'],
        'description': 'Define and ship the platform product roadmap for Dunzo\'s dark-store '
            'and delivery orchestration systems. Bridge business and engineering, '
            'write detailed specs, and drive execution with engineering teams.',
        'providerNote': 'Engineering background preferred — you\'ll be reviewing PRDs with CTOs.',
        'status': 'active', 'applicants': 14, 'viewCount': 102,
        'deadline': '2026-09-08', 'postedAt': now, 'jobRefId': 'DZO-TPM-2026',
        'isHot': true, 'source': 'manual', 'externalUrl': null,
      },
    ];
  }

  // ── Applications ─────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _buildApplications(String seekerId, Timestamp now) {
    final d = (int days) => Timestamp.fromDate(DateTime.now().subtract(Duration(days: days)));
    return [
      // 001 — Google Flutter — underReview (strong match)
      {
        'jobId': _jobIds[0], 'seekerId': seekerId, 'providerId': seekerId,
        'status': 'underReview', 'matchScore': 87,
        'matchReport': {
          'score': 87, 'band': 'excellentMatch', 'bandLabel': 'Excellent Match',
          'recommendation': 'Kiran is an excellent fit. Flutter, Dart, and Firebase are strong matches. '
              '5 years experience meets the 4-year threshold.',
          'matchedSkills': ['Flutter', 'Dart', 'Firebase'],
          'missingSkills': ['Go', 'gRPC'],
          'strengths': ['All 3 required skills matched', 'Bangalore location match', 'Experience in range'],
          'gaps': ['Go/gRPC preferred but not required'],
          'skillScore': 90, 'experienceScore': 85, 'locationScore': 100, 'contextScore': 80,
          'computedAt': now,
        },
        'appliedAt': d(3), 'updatedAt': d(1), 'viewedAt': d(1),
        'providerNote': 'Profile looks strong. Will review CV and follow up this week.',
        'strongMatchFlag': true,
      },
      // 002 — Swiggy PM — underReview
      {
        'jobId': _jobIds[1], 'seekerId': seekerId, 'providerId': seekerId,
        'status': 'underReview', 'matchScore': 79,
        'matchReport': {
          'score': 79, 'band': 'goodToGo', 'bandLabel': 'Good to Go',
          'recommendation': 'Product Management and Figma are direct matches. '
              'Analytics experience is partial — transferable from Firebase usage.',
          'matchedSkills': ['Product Management', 'Figma'],
          'missingSkills': ['SQL', 'A/B Testing'],
          'strengths': ['PM and Figma are direct matches', 'Bangalore location'],
          'gaps': ['SQL listed as required — not in profile'],
          'skillScore': 75, 'experienceScore': 80, 'locationScore': 100, 'contextScore': 70,
          'computedAt': now,
        },
        'appliedAt': d(5), 'updatedAt': d(3), 'viewedAt': d(3),
        'providerNote': null, 'strongMatchFlag': false,
      },
      // 003 — Zepto Growth — pending
      {
        'jobId': _jobIds[4], 'seekerId': seekerId, 'providerId': seekerId,
        'status': 'pending', 'matchScore': 62,
        'matchReport': {
          'score': 62, 'band': 'needsReview', 'bandLabel': 'Needs Review',
          'recommendation': 'Transferable PM skills present. Growth marketing and SQL not in profile.',
          'matchedSkills': ['Analytics'],
          'missingSkills': ['Growth', 'SQL'],
          'strengths': ['Product mindset transferable to growth'],
          'gaps': ['Growth marketing and SQL required — not in profile'],
          'skillScore': 55, 'experienceScore': 70, 'locationScore': 60, 'contextScore': 65,
          'computedAt': now,
        },
        'appliedAt': d(5), 'updatedAt': d(5), 'viewedAt': null,
        'providerNote': null, 'strongMatchFlag': false,
      },
      // 004 — Flipkart Data — hired
      {
        'jobId': _jobIds[3], 'seekerId': seekerId, 'providerId': seekerId,
        'status': 'hired', 'matchScore': 55,
        'matchReport': {
          'score': 55, 'band': 'needsReview', 'bandLabel': 'Needs Review',
          'recommendation': 'Firebase overlaps with data concepts. Python and Spark not core skills. '
              'Referred based on strong cultural fit.',
          'matchedSkills': ['Firebase'],
          'missingSkills': ['Python', 'Spark', 'SQL'],
          'strengths': ['Firebase familiarity'],
          'gaps': ['Python, Spark, SQL all required'],
          'skillScore': 45, 'experienceScore': 65, 'locationScore': 100, 'contextScore': 60,
          'computedAt': now,
        },
        'appliedAt': d(14), 'updatedAt': d(2), 'viewedAt': d(10),
        'providerNote': 'Referred internally — strong cultural fit noted by HM.',
        'strongMatchFlag': false,
      },
      // 005 — CRED Android — rejected
      {
        'jobId': _jobIds[6], 'seekerId': seekerId, 'providerId': seekerId,
        'status': 'rejected', 'matchScore': 38,
        'matchReport': {
          'score': 38, 'band': 'lowMatch', 'bandLabel': 'Low Match',
          'recommendation': 'Kotlin/Android not in profile. Flutter experience is similar '
              'but Android native and Kotlin are required.',
          'matchedSkills': [],
          'missingSkills': ['Kotlin', 'Android SDK', 'Jetpack Compose'],
          'strengths': ['Mobile development experience (Flutter)'],
          'gaps': ['Native Android skills not demonstrated'],
          'skillScore': 30, 'experienceScore': 60, 'locationScore': 100, 'contextScore': 40,
          'computedAt': now,
        },
        'appliedAt': d(10), 'updatedAt': d(6), 'viewedAt': d(7),
        'providerNote': 'Looking for native Android background. Flutter-only not sufficient.',
        'strongMatchFlag': false,
      },
      // 006 — PhonePe ML — pending (just applied)
      {
        'jobId': _jobIds[8], 'seekerId': seekerId, 'providerId': seekerId,
        'status': 'pending', 'matchScore': 45,
        'matchReport': {
          'score': 45, 'band': 'needsReview', 'bandLabel': 'Needs Review',
          'recommendation': 'Firebase gives some data familiarity. Python and TensorFlow '
              'not in profile. Worth a shot given referral pathway.',
          'matchedSkills': [],
          'missingSkills': ['TensorFlow', 'PySpark', 'Feature Engineering'],
          'strengths': ['Firebase familiarity with data streams'],
          'gaps': ['ML-specific skills not demonstrated'],
          'skillScore': 35, 'experienceScore': 60, 'locationScore': 100, 'contextScore': 50,
          'computedAt': now,
        },
        'appliedAt': d(1), 'updatedAt': d(1), 'viewedAt': null,
        'providerNote': null, 'strongMatchFlag': false,
      },
      // 007 — Razorpay UX — underReview (Figma match)
      {
        'jobId': _jobIds[5], 'seekerId': seekerId, 'providerId': seekerId,
        'status': 'underReview', 'matchScore': 72,
        'matchReport': {
          'score': 72, 'band': 'goodToGo', 'bandLabel': 'Good to Go',
          'recommendation': 'Figma is a direct match. UX Research not in profile but '
              'PM experience provides user empathy. Portfolio quality will be key.',
          'matchedSkills': ['Figma'],
          'missingSkills': ['UX Research', 'Prototyping'],
          'strengths': ['Figma proficiency confirmed', 'Product sense from PM background'],
          'gaps': ['Formal UX Research not demonstrated'],
          'skillScore': 65, 'experienceScore': 75, 'locationScore': 100, 'contextScore': 70,
          'computedAt': now,
        },
        'appliedAt': d(7), 'updatedAt': d(4), 'viewedAt': d(5),
        'providerNote': 'Interesting crossover profile. Requesting portfolio link.',
        'strongMatchFlag': false,
      },
      // 008 — Dunzo TPM — pending (applied today)
      {
        'jobId': _jobIds[14], 'seekerId': seekerId, 'providerId': seekerId,
        'status': 'pending', 'matchScore': 83,
        'matchReport': {
          'score': 83, 'band': 'excellentMatch', 'bandLabel': 'Excellent Match',
          'recommendation': 'Product Management is a direct match. Engineering background '
              'with Flutter gives the technical credibility this TPM role requires.',
          'matchedSkills': ['Product Management', 'Figma'],
          'missingSkills': ['SQL', 'API Design'],
          'strengths': ['PM background direct match', 'Technical engineering credibility'],
          'gaps': ['SQL and API Design preferred'],
          'skillScore': 82, 'experienceScore': 85, 'locationScore': 100, 'contextScore': 80,
          'computedAt': now,
        },
        'appliedAt': now, 'updatedAt': now, 'viewedAt': null,
        'providerNote': null, 'strongMatchFlag': true,
      },
    ];
  }

  // ── Messages ─────────────────────────────────────────────────────────────
  // NOTE: Firestore rule requires create.fromId == auth.uid, so we can only
  // write messages sent BY the current user. "Received" messages are skipped.
  static List<Map<String, dynamic>> _buildMessages(String uid, Timestamp now) {
    const otherA = 'seed_referrer_arjun';
    const otherB = 'seed_referrer_priya';
    final d = (int mins) => Timestamp.fromDate(
        DateTime.now().subtract(Duration(minutes: mins)));

    return [
      // Conversation A — messages sent by user TO Arjun (Google referral)
      {
        'fromId': uid, 'toId': otherA,
        'text': 'Hi Arjun! I applied for the Senior Flutter Developer role at Google. '
            "Would really appreciate a referral if you think I'm a good fit.",
        'sentAt': d(120), 'read': true,
      },
      {
        'fromId': uid, 'toId': otherA,
        'text': "That's amazing, thank you so much! I'll keep you posted on the interview progress.",
        'sentAt': d(85), 'read': true,
      },
      {
        'fromId': uid, 'toId': otherA,
        "text": "Got it. I'll prep my open-source contributions as well. Thanks again!",
        'sentAt': d(75), 'read': false,
      },
      // Conversation B — messages sent by user TO Priya (Swiggy PM)
      {
        'fromId': uid, 'toId': otherB,
        "text": "Hi Priya, I saw your Swiggy PM role — I've applied. Would love to hear your thoughts on the team culture.",
        'sentAt': d(48 * 60), 'read': true,
      },
      {
        'fromId': uid, 'toId': otherB,
        "text": "Yes — I've run experiments on onboarding flows with 200K+ users in my current role. Happy to share details.",
        'sentAt': d(46 * 60), 'read': true,
      },
      {
        'fromId': uid, 'toId': otherB,
        "text": "Perfect. Really appreciate the support, Priya!",
        'sentAt': d(44 * 60), 'read': false,
      },
      // Conversation C — user reaching out about Dunzo TPM
      {
        'fromId': uid, 'toId': 'seed_referrer_rahul',
        "text": "Hi Rahul! Noticed you work at Dunzo. I applied for the Technical PM role — would really value your insights on the hiring process.",
        'sentAt': d(30), 'read': false,
      },
      {
        'fromId': uid, 'toId': 'seed_referrer_nisha',
        "text": "Hi Nisha! I see you're at PhonePe. I applied for the ML Engineer role and wondering if you could share a referral. My profile: strong Flutter + Firebase background.",
        'sentAt': d(10), 'read': false,
      },
    ];
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _buildNotifications(String uid, Timestamp now) {
    final d = (int hours) => Timestamp.fromDate(
        DateTime.now().subtract(Duration(hours: hours)));
    return [
      {
        'userId': uid,
        'title': 'Application viewed!',
        'body': 'Arjun Mehta from Google viewed your application for Senior Flutter Developer.',
        'type': 'applicationViewed',
        'referenceId': _appIds[0],
        'read': false,
        'createdAt': d(2),
      },
      {
        'userId': uid,
        'title': 'Referral confirmed 🎉',
        'body': 'Priya Sharma confirmed your referral for the Swiggy PM role. '
            'Expect a recruiter call within 3 days.',
        'type': 'referralConfirmed',
        'referenceId': _appIds[1],
        'read': false,
        'createdAt': d(5),
      },
      {
        'userId': uid,
        'title': 'Congrats — Hired! 🥳',
        'body': 'You were marked as hired for the Flipkart Data Engineer role. '
            'What a journey!',
        'type': 'hired',
        'referenceId': _appIds[3],
        'read': true,
        'createdAt': d(48),
      },
      {
        'userId': uid,
        'title': 'New job match',
        'body': 'A new Senior Flutter Developer role at Dunzo matches 83% of your profile.',
        'type': 'jobMatch',
        'referenceId': _jobIds[14],
        'read': true,
        'createdAt': d(72),
      },
      {
        'userId': uid,
        'title': 'Application update',
        'body': 'Razorpay has reviewed your application for Senior UX Designer '
            'and is requesting your portfolio.',
        'type': 'applicationUpdate',
        'referenceId': _appIds[6],
        'read': true,
        'createdAt': d(96),
      },
    ];
  }
}

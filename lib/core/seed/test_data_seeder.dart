// lib/core/seed/test_data_seeder.dart
//
// One-tap test data seeder.
// Populates Firestore with:
//   - 2 provider users
//   - 4 seeker users
//   - 6 jobs (across different roles and companies)
//   - 12 applications with full intelligent match results
//
// HOW TO USE:
//   Call TestDataSeeder.seed(context) from the DevSeedScreen.
//   Safe to call multiple times — checks if data exists first.
//   Clear all data with TestDataSeeder.clear().

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:refsure/features/cv_job_matcher/models/job_application.dart';
import 'package:refsure/features/cv_job_matcher/services/cv_matching_engine.dart';

class TestDataSeeder {
  static final _db = FirebaseFirestore.instance;

  // ── Entry point ──────────────────────────────────────────

  static Future<SeedResult> seed() async {
    try {
      // Check if already seeded
      final existing = await _db.collection('jobs')
          .where('jobRefId', isEqualTo: 'SEED_JOB')
          .limit(1).get();
      if (existing.docs.isNotEmpty) {
        return SeedResult(success: false, message: 'Test data already exists. Clear first.');
      }

      final batch1 = _db.batch();
      final batch2 = _db.batch();

      // 1 — Seed jobs
      final jobs = _seedJobs(batch1);

      // 2 — Seed provider users
      _seedProviders(batch1);

      // 3 — Seed seeker users
      _seedSeekers(batch1);

      await batch1.commit();

      // 4 — Seed applications (needs job IDs, uses separate batch)
      await _seedApplications(jobs, batch2);
      await batch2.commit();

      return SeedResult(
        success: true,
        message: 'Seeded: ${jobs.length} jobs, 4 seekers, 2 providers, 12 applications ✅',
      );
    } catch (e) {
      return SeedResult(success: false, message: 'Seed failed: $e');
    }
  }

  // ── Clear all seed data ───────────────────────────────────

  static Future<SeedResult> clear() async {
    try {
      // Delete seeded jobs
      final jobs = await _db.collection('jobs')
          .where('jobRefId', isEqualTo: 'SEED_JOB').get();
      for (final d in jobs.docs) await d.reference.delete();

      // Delete seeded users
      final users = await _db.collection('users')
          .where('bio', isEqualTo: 'SEED_USER').get();
      for (final d in users.docs) await d.reference.delete();

      // Delete seeded applications
      final apps = await _db.collection('referral_applications')
          .where('requesterEmail', whereIn: _seekerEmails).get();
      for (final d in apps.docs) await d.reference.delete();

      return SeedResult(success: true, message: '🗑️ All test data cleared.');
    } catch (e) {
      return SeedResult(success: false, message: 'Clear failed: $e');
    }
  }

  // ── Seed Jobs ─────────────────────────────────────────────

  static List<_SeedJob> _seedJobs(WriteBatch batch) {
    final now = DateTime.now();
    final jobs = <_SeedJob>[
      _SeedJob(
        id: _db.collection('jobs').doc().id,
        data: {
          'providerId':     'seed_provider_001',
          'company':        'Microsoft',
          'companyLogo':    'M',
          'title':          'Senior DevOps Engineer',
          'department':     'Platform Engineering',
          'location':       'Hyderabad',
          'workMode':       'Hybrid',
          'minExp':         4, 'maxExp': 8,
          'salaryMin':      25, 'salaryMax': 45,
          'skills':         ['Kubernetes', 'Terraform', 'AWS', 'Docker', 'CI/CD', 'Jenkins'],
          'preferredSkills':['Helm', 'Ansible', 'Python'],
          'tags':           ['devops', 'cloud', 'platform'],
          'description':    'Build and maintain cloud-native infrastructure for Microsoft Azure services. '
              'Own end-to-end deployment pipelines, Kubernetes clusters, and infrastructure-as-code. '
              'Collaborate with engineering teams to improve reliability and deployment velocity. '
              'Required: Kubernetes, Terraform, AWS or Azure, CI/CD pipelines, Docker. '
              'You will implement observability, manage secrets, and drive cost optimisation.',
          'providerNote':   null,
          'status':         'active',
          'applicants':     0,
          'viewCount':      14,
          'deadline':       '2026-08-31',
          'postedAt':       Timestamp.fromDate(now.subtract(const Duration(days: 2))),
          'jobRefId':       'SEED_JOB',
          'isHot':          true,
          'source':         'manual',
          'externalUrl':    'https://careers.microsoft.com/devops',
        },
      ),
      _SeedJob(
        id: _db.collection('jobs').doc().id,
        data: {
          'providerId':     'seed_provider_001',
          'company':        'Microsoft',
          'companyLogo':    'M',
          'title':          'QA Automation Engineer',
          'department':     'Quality Engineering',
          'location':       'Hyderabad',
          'workMode':       'Hybrid',
          'minExp':         2, 'maxExp': 6,
          'salaryMin':      12, 'salaryMax': 22,
          'skills':         ['Selenium', 'Java', 'TestNG', 'JIRA', 'API Testing', 'CI/CD'],
          'preferredSkills':['Cypress', 'Appium', 'BDD'],
          'tags':           ['qa', 'automation', 'testing'],
          'description':    'Join our Quality Engineering team to build robust test automation frameworks. '
              'Own test strategy for critical product flows across web and mobile. '
              'Integrate tests into CI/CD pipelines using Jenkins and GitHub Actions. '
              'Work with manual testing, regression suites, bug tracking in JIRA. '
              'Experience with Selenium WebDriver, Java, TestNG mandatory. API testing with Postman required.',
          'providerNote':   null,
          'status':         'active',
          'applicants':     0,
          'viewCount':      8,
          'deadline':       '2026-07-31',
          'postedAt':       Timestamp.fromDate(now.subtract(const Duration(days: 5))),
          'jobRefId':       'SEED_JOB',
          'isHot':          false,
          'source':         'manual',
          'externalUrl':    null,
        },
      ),
      _SeedJob(
        id: _db.collection('jobs').doc().id,
        data: {
          'providerId':     'seed_provider_002',
          'company':        'Google',
          'companyLogo':    'G',
          'title':          'Senior Software Engineer',
          'department':     'Infrastructure',
          'location':       'Bangalore',
          'workMode':       'Hybrid',
          'minExp':         4, 'maxExp': 9,
          'salaryMin':      40, 'salaryMax': 80,
          'skills':         ['Python', 'Go', 'Distributed Systems', 'Kubernetes', 'gRPC', 'SQL'],
          'preferredSkills':['Machine Learning', 'Spanner', 'Bigtable'],
          'tags':           ['backend', 'infra', 'senior'],
          'description':    'Join Google Infrastructure to build distributed systems used by billions. '
              'Design and implement scalable backend services with high availability requirements. '
              'Strong system design, distributed systems, and software engineering fundamentals required. '
              'Experience with Python or Go mandatory. Kubernetes and gRPC knowledge required. '
              'You will mentor junior engineers and lead technical design discussions.',
          'providerNote':   null,
          'status':         'active',
          'applicants':     0,
          'viewCount':      22,
          'deadline':       '2026-08-15',
          'postedAt':       Timestamp.fromDate(now.subtract(const Duration(days: 1))),
          'jobRefId':       'SEED_JOB',
          'isHot':          true,
          'source':         'manual',
          'externalUrl':    'https://careers.google.com/swe',
        },
      ),
      _SeedJob(
        id: _db.collection('jobs').doc().id,
        data: {
          'providerId':     'seed_provider_002',
          'company':        'Google',
          'companyLogo':    'G',
          'title':          'Business Analyst — Payments',
          'department':     'Product & Payments',
          'location':       'Bangalore',
          'workMode':       'Hybrid',
          'minExp':         3, 'maxExp': 8,
          'salaryMin':      18, 'salaryMax': 32,
          'skills':         ['Requirements Gathering', 'SQL', 'JIRA', 'Stakeholder Management', 'Data Analysis'],
          'preferredSkills':['Power BI', 'Tableau', 'Agile', 'Payments domain'],
          'tags':           ['business-analyst', 'payments', 'product'],
          'description':    'Drive product requirements for Google Pay and payments infrastructure. '
              'Work with engineering and product teams to define business requirements and user stories. '
              'Conduct gap analysis, process mapping, and stakeholder workshops. '
              'Write BRDs, FRDs, and user stories in JIRA. Payments or fintech domain preferred. '
              'SQL for data analysis and reporting. Strong communication with business stakeholders.',
          'providerNote':   null,
          'status':         'active',
          'applicants':     0,
          'viewCount':      11,
          'deadline':       '2026-07-15',
          'postedAt':       Timestamp.fromDate(now.subtract(const Duration(days: 8))),
          'jobRefId':       'SEED_JOB',
          'isHot':          false,
          'source':         'manual',
          'externalUrl':    null,
        },
      ),
      _SeedJob(
        id: _db.collection('jobs').doc().id,
        data: {
          'providerId':     'seed_provider_001',
          'company':        'Microsoft',
          'companyLogo':    'M',
          'title':          'Data Engineer',
          'department':     'Data Platform',
          'location':       'Hyderabad',
          'workMode':       'Remote',
          'minExp':         2, 'maxExp': 6,
          'salaryMin':      16, 'salaryMax': 30,
          'skills':         ['Python', 'Apache Spark', 'Airflow', 'SQL', 'Azure'],
          'preferredSkills':['Kafka', 'dbt', 'Synapse', 'Delta Lake'],
          'tags':           ['data', 'remote', 'azure'],
          'description':    'Build and maintain scalable data pipelines for Microsoft analytics platform. '
              'Design ETL workflows using Apache Spark and Airflow DAGs. '
              'Maintain data warehouse schemas and transformation logic in Azure Synapse. '
              'Implement data quality checks and monitoring. '
              'Python and SQL mandatory. Apache Spark and Airflow experience required. Azure preferred.',
          'providerNote':   null,
          'status':         'active',
          'applicants':     0,
          'viewCount':      6,
          'deadline':       '2026-09-01',
          'postedAt':       Timestamp.fromDate(now.subtract(const Duration(days: 4))),
          'jobRefId':       'SEED_JOB',
          'isHot':          false,
          'source':         'manual',
          'externalUrl':    null,
        },
      ),
      _SeedJob(
        id: _db.collection('jobs').doc().id,
        data: {
          'providerId':     'seed_provider_002',
          'company':        'Google',
          'companyLogo':    'G',
          'title':          'Frontend Engineer — React',
          'department':     'Consumer Products',
          'location':       'Bangalore',
          'workMode':       'On-site',
          'minExp':         2, 'maxExp': 6,
          'salaryMin':      18, 'salaryMax': 35,
          'skills':         ['React', 'TypeScript', 'JavaScript', 'CSS', 'GraphQL'],
          'preferredSkills':['Next.js', 'Testing Library', 'Webpack', 'Performance optimisation'],
          'tags':           ['frontend', 'react', 'consumer'],
          'description':    'Build consumer-facing features for Google Search and Maps. '
              'Design and implement responsive UI components in React and TypeScript. '
              'Collaborate with UX designers to deliver pixel-perfect interfaces. '
              'React, TypeScript, and modern JavaScript mandatory. CSS and GraphQL required. '
              'Experience with performance optimisation, web vitals, and accessibility preferred.',
          'providerNote':   null,
          'status':         'active',
          'applicants':     0,
          'viewCount':      17,
          'deadline':       '2026-08-01',
          'postedAt':       Timestamp.fromDate(now.subtract(const Duration(days: 3))),
          'jobRefId':       'SEED_JOB',
          'isHot':          true,
          'source':         'manual',
          'externalUrl':    null,
        },
      ),
    ];

    for (final job in jobs) {
      batch.set(_db.collection('jobs').doc(job.id), job.data);
    }
    return jobs;
  }

  // ── Seed Providers ────────────────────────────────────────

  static void _seedProviders(WriteBatch batch) {
    final now = Timestamp.now();
    batch.set(_db.collection('users').doc('seed_provider_001'), {
      'id': 'seed_provider_001', 'role': 'provider',
      'name': 'Ananya Sharma', 'headline': 'Senior Engineer at Microsoft · 7 yrs exp',
      'company': 'Microsoft', 'verified': true, 'orgVerified': true,
      'title': 'Senior Software Engineer', 'location': 'Hyderabad',
      'experience': 7, 'email': 'ananya@microsoft.com', 'orgEmail': 'ananya@microsoft.com',
      'skills': ['Java', 'Kubernetes', 'AWS', 'System Design', 'Python'],
      'bio': 'SEED_USER',
      'photoUrl': null, 'linkedinUrl': null, 'resumeUrl': null,
      'createdAt': now, 'lastActiveAt': now, 'onboardingSource': 'manual',
      'profileComplete': 85, 'referralsReceived': 0,
      'referralsMade': 12, 'successfulReferrals': 9, 'totalJobsPosted': 3,
      'successRate': 75, 'responseTime': '< 24h', 'avgResponseHours': 18,
      'responseRate': 0.92, 'trustScore': 88.0,
      'activelyLooking': false,
    });

    batch.set(_db.collection('users').doc('seed_provider_002'), {
      'id': 'seed_provider_002', 'role': 'provider',
      'name': 'Rohit Menon', 'headline': 'Staff Engineer at Google · 9 yrs exp',
      'company': 'Google', 'verified': true, 'orgVerified': true,
      'title': 'Staff Engineer', 'location': 'Bangalore',
      'experience': 9, 'email': 'rohit@google.com', 'orgEmail': 'rohit@google.com',
      'skills': ['Go', 'Distributed Systems', 'gRPC', 'Python', 'Kubernetes'],
      'bio': 'SEED_USER',
      'photoUrl': null, 'linkedinUrl': null, 'resumeUrl': null,
      'createdAt': now, 'lastActiveAt': now, 'onboardingSource': 'manual',
      'profileComplete': 90, 'referralsReceived': 0,
      'referralsMade': 24, 'successfulReferrals': 19, 'totalJobsPosted': 6,
      'successRate': 79, 'responseTime': '< 48h', 'avgResponseHours': 36,
      'responseRate': 0.88, 'trustScore': 94.0,
      'activelyLooking': false,
    });
  }

  // ── Seed Seekers ──────────────────────────────────────────

  static void _seedSeekers(WriteBatch batch) {
    final now = Timestamp.now();

    final seekers = [
      {
        'id': 'seed_seeker_001', 'role': 'seeker',
        'name': 'Karan Verma', 'headline': 'DevOps Engineer · 5 yrs exp',
        'company': 'TCS', 'verified': false, 'orgVerified': false,
        'title': 'DevOps Engineer', 'location': 'Hyderabad',
        'experience': 5, 'email': 'karan.verma@test.com',
        'skills': ['Kubernetes', 'Terraform', 'AWS', 'Docker', 'Jenkins', 'Python', 'CI/CD'],
        'bio': 'SEED_USER', 'photoUrl': null,
        'createdAt': now, 'lastActiveAt': now, 'onboardingSource': 'manual',
        'profileComplete': 78, 'activelyLooking': true,
        'noticePeriod': '30 days', 'expectedSalary': '30-40',
        'referralsMade': 0, 'referralsReceived': 2,
      },
      {
        'id': 'seed_seeker_002', 'role': 'seeker',
        'name': 'Priya Nair', 'headline': 'QA Engineer · 3 yrs exp',
        'company': 'Wipro', 'verified': false, 'orgVerified': false,
        'title': 'QA Engineer', 'location': 'Pune',
        'experience': 3, 'email': 'priya.nair@test.com',
        'skills': ['Selenium', 'Java', 'TestNG', 'JIRA', 'API Testing', 'Postman'],
        'bio': 'SEED_USER', 'photoUrl': null,
        'createdAt': now, 'lastActiveAt': now, 'onboardingSource': 'manual',
        'profileComplete': 72, 'activelyLooking': true,
        'noticePeriod': '45 days', 'expectedSalary': '15-20',
        'referralsMade': 0, 'referralsReceived': 0,
      },
      {
        'id': 'seed_seeker_003', 'role': 'seeker',
        'name': 'Arjun Pillai', 'headline': 'Full Stack Developer · 4 yrs exp',
        'company': 'Infosys', 'verified': false, 'orgVerified': false,
        'title': 'Full Stack Developer', 'location': 'Bangalore',
        'experience': 4, 'email': 'arjun.pillai@test.com',
        'skills': ['React', 'TypeScript', 'Node.js', 'Python', 'SQL', 'Docker', 'GraphQL'],
        'bio': 'SEED_USER', 'photoUrl': null,
        'createdAt': now, 'lastActiveAt': now, 'onboardingSource': 'manual',
        'profileComplete': 80, 'activelyLooking': true,
        'noticePeriod': '30 days', 'expectedSalary': '20-30',
        'referralsMade': 0, 'referralsReceived': 1,
      },
      {
        'id': 'seed_seeker_004', 'role': 'seeker',
        'name': 'Sneha Reddy', 'headline': 'Business Analyst · 5 yrs exp',
        'company': 'Accenture', 'verified': false, 'orgVerified': false,
        'title': 'Business Analyst', 'location': 'Hyderabad',
        'experience': 5, 'email': 'sneha.reddy@test.com',
        'skills': ['Requirements Gathering', 'SQL', 'JIRA', 'Stakeholder Management',
                   'Data Analysis', 'Agile', 'Power BI'],
        'bio': 'SEED_USER', 'photoUrl': null,
        'createdAt': now, 'lastActiveAt': now, 'onboardingSource': 'manual',
        'profileComplete': 75, 'activelyLooking': true,
        'noticePeriod': '60 days', 'expectedSalary': '18-25',
        'referralsMade': 0, 'referralsReceived': 0,
      },
    ];

    for (final s in seekers) {
      batch.set(_db.collection('users').doc(s['id'] as String), s);
    }
  }

  // ── Seed Applications with auto-match ─────────────────────

  static Future<void> _seedApplications(
      List<_SeedJob> jobs, WriteBatch batch) async {

    final now = DateTime.now();

    // Map job titles to job IDs for easy lookup
    final jobMap = <String, _SeedJob>{};
    for (final j in jobs) {
      jobMap[j.data['title'] as String] = j;
    }

    final applications = <Map<String, dynamic>>[

      // ── Karan (DevOps) → Microsoft DevOps job (STRONG match) ──
      _buildApp(
        id: 'seed_app_001',
        jobId: jobMap['Senior DevOps Engineer']!.id,
        jobData: jobMap['Senior DevOps Engineer']!.data,
        seekerId: 'seed_seeker_001', seekerName: 'Karan Verma',
        seekerEmail: 'karan.verma@test.com',
        providerId: 'seed_provider_001',
        resumeText: '''Karan Verma — DevOps Engineer
5 years of experience in cloud infrastructure and CI/CD

Skills: Kubernetes, Terraform, AWS, Docker, Jenkins, Python, GitHub Actions,
Helm, Linux, Bash, Grafana, Prometheus, CI/CD pipelines

Experience:
Senior DevOps Engineer at TCS (2021–2025)
- Maintained 15 Kubernetes clusters on AWS EKS across 4 regions
- Built CI/CD pipelines with Jenkins and GitHub Actions reducing deployment time by 65%
- Infrastructure-as-code using Terraform modules, managed 200+ resources
- Monitoring with Grafana, Prometheus, CloudWatch, PagerDuty alerting
- Managed secrets with Vault, IAM policies, security baselines
- Cost optimisation: reduced AWS spend by 30% through right-sizing

Cloud Engineer at StartupXYZ (2019–2021)
- Managed EC2, S3, RDS, Lambda, API Gateway on AWS
- Implemented auto-scaling and load balancing for traffic spikes
- Container migration from VMs to Docker + Kubernetes

Education: B.Tech Computer Science, 2019
Certifications: AWS Solutions Architect, CKA (Certified Kubernetes Administrator)''',
        appliedAt: now.subtract(const Duration(hours: 3)),
        status: ApplicationStatus.shortlisted,
      ),

      // ── Karan (DevOps) → Microsoft QA job (LOW match - wrong role) ──
      _buildApp(
        id: 'seed_app_002',
        jobId: jobMap['QA Automation Engineer']!.id,
        jobData: jobMap['QA Automation Engineer']!.data,
        seekerId: 'seed_seeker_001', seekerName: 'Karan Verma',
        seekerEmail: 'karan.verma@test.com',
        providerId: 'seed_provider_001',
        resumeText: '''Karan Verma — DevOps Engineer
5 years of experience in cloud infrastructure and CI/CD

Skills: Kubernetes, Terraform, AWS, Docker, Jenkins, Python, CI/CD

Experience:
Senior DevOps Engineer at TCS (2021–2025)
- Maintained Kubernetes clusters and CI/CD pipelines
- Infrastructure automation using Terraform
- AWS infrastructure management

Education: B.Tech Computer Science, 2019
Certifications: AWS Solutions Architect, CKA''',
        appliedAt: now.subtract(const Duration(hours: 6)),
        status: ApplicationStatus.applied,
      ),

      // ── Priya (QA) → Microsoft QA job (STRONG match) ──
      _buildApp(
        id: 'seed_app_003',
        jobId: jobMap['QA Automation Engineer']!.id,
        jobData: jobMap['QA Automation Engineer']!.data,
        seekerId: 'seed_seeker_002', seekerName: 'Priya Nair',
        seekerEmail: 'priya.nair@test.com',
        providerId: 'seed_provider_001',
        resumeText: '''Priya Nair — QA Automation Engineer
3 years of experience in software testing and automation

Skills: Selenium, Java, TestNG, JIRA, Manual Testing, API Testing,
Postman, REST Assured, BDD, Cucumber, JUnit, Maven, Git

Experience:
QA Engineer at Wipro (2022–2025)
- Designed and maintained Selenium automation framework in Java (800+ test cases)
- Performed manual and regression testing for payment workflows
- API testing with Postman and REST Assured for 15+ microservices
- Integrated tests into Jenkins CI/CD pipeline reducing regression time by 60%
- Tracked and managed 200+ defects in JIRA with detailed bug reports
- Participated in Agile sprints, daily standups, sprint retrospectives

Test Analyst at ABC Corp (2021–2022)
- Manual functional and regression testing
- Test plan and test case writing

Education: B.Tech IT, 2021
Certifications: ISTQB Foundation Level''',
        appliedAt: now.subtract(const Duration(hours: 1)),
        status: ApplicationStatus.applied,
      ),

      // ── Priya (QA) → Google SWE job (LOW match - wrong role) ──
      _buildApp(
        id: 'seed_app_004',
        jobId: jobMap['Senior Software Engineer']!.id,
        jobData: jobMap['Senior Software Engineer']!.data,
        seekerId: 'seed_seeker_002', seekerName: 'Priya Nair',
        seekerEmail: 'priya.nair@test.com',
        providerId: 'seed_provider_002',
        resumeText: '''Priya Nair — QA Automation Engineer
3 years of experience in software testing

Skills: Selenium, Java, TestNG, JIRA, Manual Testing, API Testing

Experience:
QA Engineer at Wipro (2022–2025)
- Selenium automation framework in Java
- API testing and regression testing

Education: B.Tech IT, 2021
Certifications: ISTQB Foundation''',
        appliedAt: now.subtract(const Duration(hours: 8)),
        status: ApplicationStatus.applied,
      ),

      // ── Arjun (Full Stack) → Google Frontend job (GOOD match) ──
      _buildApp(
        id: 'seed_app_005',
        jobId: jobMap['Frontend Engineer — React']!.id,
        jobData: jobMap['Frontend Engineer — React']!.data,
        seekerId: 'seed_seeker_003', seekerName: 'Arjun Pillai',
        seekerEmail: 'arjun.pillai@test.com',
        providerId: 'seed_provider_002',
        resumeText: '''Arjun Pillai — Full Stack Developer
4 years of experience in web development

Skills: React, TypeScript, JavaScript, Node.js, Python, SQL, Docker,
GraphQL, CSS, HTML5, REST APIs, Git, Redux, Next.js

Experience:
Full Stack Developer at Infosys (2021–2025)
- Built responsive React + TypeScript applications for 50,000 daily active users
- Implemented GraphQL API layer reducing over-fetching by 40%
- Performance optimisation: improved Lighthouse score from 62 to 94
- CSS-in-JS with Styled Components, Tailwind CSS
- Collaborated with UX designers on accessibility (WCAG 2.1 compliance)
- Backend: Node.js REST APIs with PostgreSQL

Junior Developer at WebStudio (2020–2021)
- HTML, CSS, JavaScript, React basics
- WordPress development

Education: B.Tech CSE, 2020''',
        appliedAt: now.subtract(const Duration(hours: 2)),
        status: ApplicationStatus.applied,
      ),

      // ── Arjun (Full Stack) → Google SWE job (BORDERLINE match) ──
      _buildApp(
        id: 'seed_app_006',
        jobId: jobMap['Senior Software Engineer']!.id,
        jobData: jobMap['Senior Software Engineer']!.data,
        seekerId: 'seed_seeker_003', seekerName: 'Arjun Pillai',
        seekerEmail: 'arjun.pillai@test.com',
        providerId: 'seed_provider_002',
        resumeText: '''Arjun Pillai — Full Stack Developer
4 years of experience in web and backend development

Skills: React, TypeScript, Node.js, Python, SQL, Docker, GraphQL, REST APIs

Experience:
Full Stack Developer at Infosys (2021–2025)
- Backend services with Node.js and Python
- SQL and NoSQL database design
- Docker containerisation and basic Kubernetes
- System design for mid-scale web applications

Education: B.Tech CSE, 2020''',
        appliedAt: now.subtract(const Duration(hours: 5)),
        status: ApplicationStatus.applied,
      ),

      // ── Sneha (BA) → Google BA Payments job (STRONG match) ──
      _buildApp(
        id: 'seed_app_007',
        jobId: jobMap['Business Analyst — Payments']!.id,
        jobData: jobMap['Business Analyst — Payments']!.data,
        seekerId: 'seed_seeker_004', seekerName: 'Sneha Reddy',
        seekerEmail: 'sneha.reddy@test.com',
        providerId: 'seed_provider_002',
        resumeText: '''Sneha Reddy — Senior Business Analyst
5 years of experience in business analysis and product requirements

Skills: Requirements Gathering, SQL, JIRA, Stakeholder Management, Data Analysis,
Agile, Power BI, Tableau, BRD Writing, Process Mapping, User Stories, Scrum

Experience:
Senior Business Analyst at Accenture (2020–2025)
- Elicited and documented business requirements for digital payments platform
- Wrote 150+ user stories, BRDs and FRDs for payment gateway integrations
- Conducted gap analysis and process mapping for UPI and NEFT workflows
- Stakeholder workshops with business heads and technology leads
- Created Power BI dashboards tracking payment success rates and SLA compliance
- SQL queries for data analysis and ad-hoc reporting
- Supported UAT cycles and sign-off activities

BA Analyst at HCL (2019–2020)
- Functional requirements documentation
- JIRA project tracking and sprint planning

Education: MBA Finance, 2019 | B.Com, 2017
Certifications: Certified Business Analysis Professional (CBAP)''',
        appliedAt: now.subtract(const Duration(minutes: 45)),
        status: ApplicationStatus.referred,
      ),

      // ── Sneha (BA) → Microsoft DevOps job (LOW match) ──
      _buildApp(
        id: 'seed_app_008',
        jobId: jobMap['Senior DevOps Engineer']!.id,
        jobData: jobMap['Senior DevOps Engineer']!.data,
        seekerId: 'seed_seeker_004', seekerName: 'Sneha Reddy',
        seekerEmail: 'sneha.reddy@test.com',
        providerId: 'seed_provider_001',
        resumeText: '''Sneha Reddy — Business Analyst
5 years of experience in business analysis

Skills: Requirements Gathering, SQL, JIRA, Stakeholder Management, Agile

Experience:
Senior Business Analyst at Accenture (2020–2025)
- Business requirements documentation
- Stakeholder management and process analysis

Education: MBA Finance, 2019''',
        appliedAt: now.subtract(const Duration(hours: 10)),
        status: ApplicationStatus.rejected,
      ),

      // ── Karan (DevOps) → Google SWE job (MODERATE match) ──
      _buildApp(
        id: 'seed_app_009',
        jobId: jobMap['Senior Software Engineer']!.id,
        jobData: jobMap['Senior Software Engineer']!.data,
        seekerId: 'seed_seeker_001', seekerName: 'Karan Verma',
        seekerEmail: 'karan.verma@test.com',
        providerId: 'seed_provider_002',
        resumeText: '''Karan Verma — DevOps / Platform Engineer
5 years of experience in cloud and infrastructure

Skills: Kubernetes, Terraform, AWS, Docker, Python, Go (basic), Jenkins, SQL

Experience:
Senior DevOps Engineer at TCS (2021–2025)
- Python scripting for automation and tooling
- Go microservices for internal platform tools
- System design for distributed infrastructure
- Kubernetes and distributed systems management

Education: B.Tech CSE, 2019''',
        appliedAt: now.subtract(const Duration(hours: 4)),
        status: ApplicationStatus.underReview,
      ),

      // ── Arjun → Microsoft Data Engineer job (MODERATE match) ──
      _buildApp(
        id: 'seed_app_010',
        jobId: jobMap['Data Engineer']!.id,
        jobData: jobMap['Data Engineer']!.data,
        seekerId: 'seed_seeker_003', seekerName: 'Arjun Pillai',
        seekerEmail: 'arjun.pillai@test.com',
        providerId: 'seed_provider_001',
        resumeText: '''Arjun Pillai — Full Stack Developer
4 years of experience

Skills: Python, SQL, Node.js, React, Docker, Azure (basic)

Experience:
Full Stack Developer at Infosys (2021–2025)
- Python backend services and SQL database work
- Basic Azure deployment and storage
- Data processing scripts in Python

Education: B.Tech CSE, 2020''',
        appliedAt: now.subtract(const Duration(hours: 7)),
        status: ApplicationStatus.applied,
      ),

      // ── Priya → Google Frontend job (LOW match - QA vs Frontend) ──
      _buildApp(
        id: 'seed_app_011',
        jobId: jobMap['Frontend Engineer — React']!.id,
        jobData: jobMap['Frontend Engineer — React']!.data,
        seekerId: 'seed_seeker_002', seekerName: 'Priya Nair',
        seekerEmail: 'priya.nair@test.com',
        providerId: 'seed_provider_002',
        resumeText: '''Priya Nair — QA Engineer
3 years of experience in testing

Skills: Selenium, Java, TestNG, JIRA, Manual Testing, HTML (basic), CSS (basic)

Experience:
QA Engineer at Wipro (2022–2025)
- Web UI testing with Selenium
- Basic HTML/CSS understanding for test locators

Education: B.Tech IT, 2021''',
        appliedAt: now.subtract(const Duration(hours: 9)),
        status: ApplicationStatus.rejected,
      ),

      // ── Sneha → Microsoft Data Engineer (LOW match) ──
      _buildApp(
        id: 'seed_app_012',
        jobId: jobMap['Data Engineer']!.id,
        jobData: jobMap['Data Engineer']!.data,
        seekerId: 'seed_seeker_004', seekerName: 'Sneha Reddy',
        seekerEmail: 'sneha.reddy@test.com',
        providerId: 'seed_provider_001',
        resumeText: '''Sneha Reddy — Business Analyst
5 years of experience in business analysis and data reporting

Skills: SQL, Power BI, Tableau, JIRA, Data Analysis, Excel, Agile

Experience:
Senior Business Analyst at Accenture (2020–2025)
- SQL queries for data analysis and reporting
- Power BI dashboards and data visualisation

Education: MBA Finance, 2019''',
        appliedAt: now.subtract(const Duration(hours: 11)),
        status: ApplicationStatus.applied,
      ),
    ];

    for (final app in applications) {
      final ref = _db.collection('referral_applications').doc(app['id'] as String);
      batch.set(ref, app);
      // Update job applicant count
      final jobRef = _db.collection('jobs').doc(app['postedJobId'] as String);
      batch.update(jobRef, {'applicants': FieldValue.increment(1)});
    }
  }

  // ── Build application with auto-computed match ─────────────

  static Map<String, dynamic> _buildApp({
    required String id,
    required String jobId,
    required Map<String, dynamic> jobData,
    required String seekerId,
    required String seekerName,
    required String seekerEmail,
    required String providerId,
    required String resumeText,
    required DateTime appliedAt,
    required ApplicationStatus status,
  }) {
    // Run the intelligent matching engine
    final match = CvMatchingEngine.compute(
      cvText:   resumeText,
      jdText:   jobData['description'] as String,
      jdTitle:  jobData['title'] as String,
      jdSkills: List<String>.from(jobData['skills'] as List),
      jdMinExp: jobData['minExp'] as int,
      jdMaxExp: jobData['maxExp'] as int,
    );

    return {
      'id':             id,
      'postedJobId':    jobId,
      'requesterId':    seekerId,
      'requesterName':  seekerName,
      'requesterEmail': seekerEmail,
      'providerId':     providerId,
      'resumeText':     resumeText,
      'resumeFileUrl':  null,
      'appliedAt':      Timestamp.fromDate(appliedAt),
      'status':         status.name,
      'providerNote':   null,
      'decidedAt':      null,
      'matchResult': {
        'overallScore':             match.overallScore,
        'detectedRole':             match.detectedRole.name,
        'roleLabel':                match.roleLabel,
        'recommendation':           match.recommendation.name,
        'matchedSkills':            match.matchedSkills,
        'missingSkills':            match.missingSkills,
        'matchedTools':             match.matchedTools,
        'missingTools':             match.missingTools,
        'matchedDomains':           match.matchedDomains,
        'strongAreas':              match.strongAreas,
        'weakAreas':                match.weakAreas,
        'candidateSuggestions':     match.candidateSuggestions,
        'providerSummary':          match.providerSummary,
        'roleUnderstandingSummary': match.roleUnderstandingSummary,
        'coreSkillScore':           match.coreSkillScore,
        'roleResponsibilityScore':  match.roleResponsibilityScore,
        'experienceScore':          match.experienceScore,
        'domainScore':              match.domainScore,
        'toolsScore':               match.toolsScore,
        'educationScore':           match.educationScore,
        'profileQualityScore':      match.profileQualityScore,
        'experienceMatch':          match.experienceMatch,
        'domainMatch':              match.domainMatch,
        'toolsMatch':               match.toolsMatch,
      },
    };
  }

  static const _seekerEmails = [
    'karan.verma@test.com', 'priya.nair@test.com',
    'arjun.pillai@test.com', 'sneha.reddy@test.com',
  ];
}

// ── Helper classes ──────────────────────────────────────────

class _SeedJob {
  const _SeedJob({required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;
}

class SeedResult {
  const SeedResult({required this.success, required this.message});
  final bool success;
  final String message;
}

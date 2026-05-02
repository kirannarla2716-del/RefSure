// lib/features/cv_job_matcher/services/job_fetch_service.dart
//
// Abstraction layer for fetching company job openings.
//
// Currently uses rich mock data.
// To connect real APIs, implement the same interface:
//   - Company career pages (via scraping Cloud Function)
//   - LinkedIn Jobs API
//   - Greenhouse API (greenhouse.io)
//   - Lever API (lever.co)
//   - Workday API
//   - Naukri partner API
//   - Custom backend endpoint
//
// The UI and matching engine never need to change.

import 'package:refsure/features/cv_job_matcher/models/job_opening.dart';

class JobFetchService {
  /// Fetch open positions for [companyName] in [country].
  /// Returns jobs posted in the last [lastDays] days.
  ///
  /// AI integration point: replace the mock return with an HTTP call.
  Future<List<JobOpening>> fetchCompanyJobs({
    required String companyName,
    required String country,
    int lastDays = 30,
  }) async {
    // Simulate API latency
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // ── Mock data — replace with real API call ────────────────
    final now = DateTime.now();
    final company = companyName.trim().isEmpty ? 'Your Company' : companyName;
    final location = country.trim().isEmpty ? 'India' : country;

    return _mockJobs(company, location, now, lastDays);
  }

  /// Future: resolve API base URL from company name.
  /// e.g. 'Microsoft' → 'careers.microsoft.com'
  String? resolveCareerPageUrl(String companyName) {
    const known = <String, String>{
      'microsoft': 'https://careers.microsoft.com',
      'google':    'https://careers.google.com',
      'amazon':    'https://amazon.jobs',
      'infosys':   'https://career.infosys.com',
      'tcs':       'https://ibegin.tcs.com',
      'wipro':     'https://careers.wipro.com',
      'accenture': 'https://www.accenture.com/careers',
      'ibm':       'https://www.ibm.com/employment',
    };
    return known[companyName.toLowerCase()];
  }

  // ── Mock job generator ────────────────────────────────────

  static List<JobOpening> _mockJobs(
    String company, String location, DateTime now, int lastDays) {
    return [
      JobOpening(
        id: 'mock_001',
        companyName: company,
        title: 'Senior Software Engineer',
        location: '$location',
        country: location,
        department: 'Engineering',
        workMode: 'Hybrid',
        experienceMin: 4,
        experienceMax: 8,
        requiredSkills: ['Java', 'Spring Boot', 'Microservices', 'AWS', 'SQL'],
        preferredSkills: ['Kubernetes', 'Docker', 'Kafka'],
        description:
            'We are looking for a Senior Software Engineer to join our '
            'core platform team. You will design and build high-throughput '
            'distributed services used by millions of users. '
            'Strong system design and backend engineering skills are essential. '
            'You will collaborate with product, design, and DevOps teams.',
        responsibilities: [
          'Design and implement scalable microservices',
          'Conduct code reviews and mentor junior engineers',
          'Collaborate on system architecture decisions',
          'Participate in on-call rotations',
          'Contribute to CI/CD pipeline improvements',
        ],
        postedDate: now.subtract(Duration(days: 3)),
        sourceUrl: '${_mockCareerUrl(company)}/senior-swe',
        sourcePlatform: 'careers',
        salaryRange: '₹25–45 LPA',
      ),
      JobOpening(
        id: 'mock_002',
        companyName: company,
        title: 'QA Automation Engineer',
        location: '$location',
        country: location,
        department: 'Quality Engineering',
        workMode: 'Hybrid',
        experienceMin: 2,
        experienceMax: 6,
        requiredSkills: ['Selenium', 'Java', 'TestNG', 'JIRA', 'API Testing'],
        preferredSkills: ['Cypress', 'Appium', 'Jenkins', 'CI/CD'],
        description:
            'Join our Quality Engineering team to build robust automation '
            'frameworks that ensure product reliability at scale. '
            'You will own test strategy for critical product flows, '
            'integrate tests into CI/CD pipelines, and work closely with '
            'developers to shift quality left. Experience with BDD and '
            'behaviour-driven automation is a plus.',
        responsibilities: [
          'Design and maintain end-to-end automation frameworks',
          'Write test plans, test cases, and test scripts',
          'Integrate automation into Jenkins/GitHub Actions pipelines',
          'Identify and report bugs with clear reproduction steps',
          'Collaborate with developers in sprint ceremonies',
        ],
        postedDate: now.subtract(Duration(days: 7)),
        sourceUrl: '${_mockCareerUrl(company)}/qa-engineer',
        sourcePlatform: 'careers',
        salaryRange: '₹12–22 LPA',
      ),
      JobOpening(
        id: 'mock_003',
        companyName: company,
        title: 'DevOps Engineer',
        location: '$location',
        country: location,
        department: 'Platform Engineering',
        workMode: 'Remote',
        experienceMin: 3,
        experienceMax: 7,
        requiredSkills: ['Kubernetes', 'Terraform', 'AWS', 'Docker', 'CI/CD'],
        preferredSkills: ['Helm', 'Ansible', 'Python', 'Grafana'],
        description:
            'We are building next-generation cloud infrastructure for our '
            'global product suite. As a DevOps Engineer you will own the '
            'end-to-end deployment lifecycle, design and maintain Kubernetes '
            'clusters, implement infrastructure-as-code, and drive reliability '
            'improvements across production systems.',
        responsibilities: [
          'Design and maintain Kubernetes clusters on AWS EKS',
          'Write Terraform modules for infrastructure provisioning',
          'Build and optimise CI/CD pipelines in GitHub Actions and Jenkins',
          'Implement observability stack with Prometheus and Grafana',
          'Manage secrets, IAM policies, and security baselines',
        ],
        postedDate: now.subtract(Duration(days: 1)),
        sourceUrl: '${_mockCareerUrl(company)}/devops',
        sourcePlatform: 'careers',
        salaryRange: '₹18–35 LPA',
      ),
      JobOpening(
        id: 'mock_004',
        companyName: company,
        title: 'Business Analyst',
        location: '$location',
        country: location,
        department: 'Product',
        workMode: 'Hybrid',
        experienceMin: 3,
        experienceMax: 8,
        requiredSkills: ['Requirements Gathering', 'SQL', 'JIRA', 'Stakeholder Management'],
        preferredSkills: ['Power BI', 'Tableau', 'Agile', 'BRD Writing'],
        description:
            'We are looking for a Business Analyst to bridge the gap between '
            'business requirements and technical delivery. You will work with '
            'product, engineering, and leadership to define clear, measurable '
            'requirements and drive delivery of high-impact features. '
            'Capital markets or fintech domain experience preferred.',
        responsibilities: [
          'Elicit and document business requirements via workshops and interviews',
          'Write BRDs, FRDs, and user stories in JIRA',
          'Conduct gap analysis and process mapping',
          'Support UAT and sign-off activities',
          'Create dashboards and reports for business stakeholders',
        ],
        postedDate: now.subtract(Duration(days: 12)),
        sourceUrl: '${_mockCareerUrl(company)}/ba',
        sourcePlatform: 'naukri',
        salaryRange: '₹14–28 LPA',
      ),
      JobOpening(
        id: 'mock_005',
        companyName: company,
        title: 'Data Engineer',
        location: '$location',
        country: location,
        department: 'Data Platform',
        workMode: 'Hybrid',
        experienceMin: 2,
        experienceMax: 6,
        requiredSkills: ['Python', 'Apache Spark', 'Airflow', 'SQL', 'AWS'],
        preferredSkills: ['Kafka', 'dbt', 'Redshift', 'Snowflake'],
        description:
            'Join the Data Platform team to build and maintain scalable '
            'data pipelines that power analytics and ML initiatives. '
            'You will work with large datasets, design ETL workflows, '
            'and ensure data quality and availability for downstream consumers.',
        responsibilities: [
          'Design and build batch and streaming data pipelines',
          'Develop Airflow DAGs for pipeline orchestration',
          'Maintain data warehouse schemas and transformation logic',
          'Implement data quality checks and monitoring alerts',
          'Collaborate with data scientists and analysts on data needs',
        ],
        postedDate: now.subtract(Duration(days: 5)),
        sourceUrl: '${_mockCareerUrl(company)}/data-engineer',
        sourcePlatform: 'linkedin',
        salaryRange: '₹16–30 LPA',
      ),
      JobOpening(
        id: 'mock_006',
        companyName: company,
        title: 'Product Manager',
        location: '$location',
        country: location,
        department: 'Product',
        workMode: 'On-site',
        experienceMin: 4,
        experienceMax: 10,
        requiredSkills: ['Product Strategy', 'Roadmap', 'Agile', 'Data Analysis', 'Stakeholder Management'],
        preferredSkills: ['SQL', 'A/B Testing', 'OKRs', 'Go-to-market'],
        description:
            'Drive product strategy and execution for our consumer platform. '
            'You will define the vision, prioritise features, and work across '
            'engineering, design, data, and marketing to deliver outcomes '
            'that delight users and move business metrics. '
            'SaaS or B2C product experience strongly preferred.',
        responsibilities: [
          'Own product roadmap and quarterly planning',
          'Define and prioritise user stories and acceptance criteria',
          'Conduct user research, interviews, and A/B test analysis',
          'Collaborate with design and engineering in Agile sprints',
          'Track product KPIs and report to senior leadership',
        ],
        postedDate: now.subtract(Duration(days: 9)),
        sourceUrl: '${_mockCareerUrl(company)}/pm',
        sourcePlatform: 'linkedin',
        salaryRange: '₹22–40 LPA',
      ),
    ].where((j) {
      final age = now.difference(j.postedDate!).inDays;
      return age <= lastDays;
    }).toList();
  }

  static String _mockCareerUrl(String company) =>
      'https://careers.${company.toLowerCase().replaceAll(' ', '')}.com/jobs';
}

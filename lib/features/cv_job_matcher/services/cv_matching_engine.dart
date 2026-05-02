// lib/features/cv_job_matcher/services/cv_matching_engine.dart
//
// Intelligent CV-to-JD matching engine.
//
// Design principles:
// 1. Role-first: classify the JD role before scoring.
//    A "testing" keyword in a DevOps JD means CI/CD testing, not QA.
// 2. Weighted scoring: 7 dimensions with defined weights.
// 3. Transferable skills: maps adjacent skills / synonyms.
// 4. AI-ready: every scoring method is a pure function — swap rule-based
//    logic for an LLM call without touching the rest of the feature.
//
// Scoring weights (must sum to 100):
//   Core skills match       : 30
//   Role responsibility     : 25
//   Experience relevance    : 15
//   Domain relevance        : 10
//   Tools / technology      : 10
//   Education / certs       :  5
//   Profile quality/context :  5

import 'package:refsure/features/cv_job_matcher/models/cv_match_result.dart';
import 'package:refsure/features/cv_job_matcher/models/extracted_profile.dart';

// ─────────────────────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────────────────────

class CvMatchingEngine {
  /// Entry point — call this from the repository / cubit.
  ///
  /// [cvText]  : raw text pasted or extracted from CV/resume.
  /// [jdText]  : raw text of the job description.
  /// [jdTitle] : job title string (e.g. "Senior QA Engineer").
  /// [jdSkills]: structured skill list from the Job model (can be empty).
  /// [jdMinExp]: minimum experience required (years).
  /// [jdMaxExp]: maximum experience required (years).
  static CvMatchResult compute({
    required String cvText,
    required String jdText,
    String jdTitle = '',
    List<String> jdSkills = const [],
    int jdMinExp = 0,
    int jdMaxExp = 99,
  }) {
    final cvLower = cvText.toLowerCase();
    final jdLower = jdText.toLowerCase();
    final fullJdLower = '$jdTitle $jdText'.toLowerCase();

    // Step 1 — Parse CV
    final profile = _parseProfile(cvText, cvLower);

    // Step 2 — Classify JD role
    final role = _classifyRole(fullJdLower, jdTitle.toLowerCase());
    final roleLabel = _roleLabelMap[role] ?? 'Professional';

    // Step 3 — Extract JD requirements
    final jdExtracted = _extractJdRequirements(jdLower, jdSkills);

    // Step 4 — Score each dimension
    final coreSkill   = _scoreCoreSkills(profile, jdExtracted);
    final roleResp    = _scoreRoleResponsibility(profile, role, jdLower);
    final experience  = _scoreExperience(profile, jdMinExp, jdMaxExp);
    final domain      = _scoreDomain(profile, jdExtracted.domains, jdLower);
    final tools       = _scoreTools(profile, jdExtracted.tools);
    final education   = _scoreEducation(profile, jdExtracted.preferredCerts);
    final quality     = _scoreProfileQuality(profile);

    // Step 5 — Weighted total
    final overall = _weightedTotal(
      coreSkill: coreSkill.score,
      roleResp: roleResp,
      experience: experience.score,
      domain: domain.score,
      tools: tools.score,
      education: education,
      quality: quality,
    );

    // Step 6 — Recommendation
    final rec = _deriveRecommendation(overall, coreSkill.score);

    // Step 7 — Narrative
    final strongAreas = _buildStrongAreas(
      profile: profile,
      coreSkill: coreSkill,
      roleResp: roleResp,
      experience: experience,
      domain: domain,
    );
    final weakAreas = _buildWeakAreas(
      coreSkill: coreSkill,
      experience: experience,
      domain: domain,
      tools: tools,
    );
    final suggestions = _buildSuggestions(
      missingSkills: coreSkill.missing,
      missingTools: tools.missing,
      weakAreas: weakAreas,
    );
    final providerSummary = _buildProviderSummary(
      overall: overall,
      role: roleLabel,
      matched: coreSkill.matched,
      missing: coreSkill.missing,
      rec: rec,
    );
    final roleUnderstanding = _buildRoleUnderstanding(role, roleLabel, jdTitle);

    return CvMatchResult(
      overallScore: overall,
      detectedRole: role,
      roleLabel: roleLabel,
      recommendation: rec,
      matchedSkills: coreSkill.matched,
      missingSkills: coreSkill.missing,
      matchedTools: tools.matched,
      missingTools: tools.missing,
      matchedDomains: domain.matched,
      strongAreas: strongAreas,
      weakAreas: weakAreas,
      candidateSuggestions: suggestions,
      providerSummary: providerSummary,
      roleUnderstandingSummary: roleUnderstanding,
      coreSkillScore: coreSkill.score,
      roleResponsibilityScore: roleResp,
      experienceScore: experience.score,
      domainScore: domain.score,
      toolsScore: tools.score,
      educationScore: education,
      profileQualityScore: quality,
      experienceMatch: experience.isMatch,
      domainMatch: domain.score >= 60,
      toolsMatch: tools.score >= 60,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 1 — CV PARSER
  // ─────────────────────────────────────────────────────────────

  static ExtractedProfile _parseProfile(String raw, String lower) {
    return ExtractedProfile(
      rawText: raw,
      currentTitle:    _extractTitle(lower),
      experienceYears: _extractExperienceYears(lower),
      skills:          _extractSkills(lower),
      tools:           _extractTools(lower),
      domains:         _extractDomains(lower),
      education:       _extractEducation(lower),
      certifications:  _extractCertifications(lower),
      jobTitlesHeld:   _extractJobTitles(lower),
      responsibilities:_extractResponsibilities(lower),
      industries:      _extractIndustries(lower),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 2 — ROLE CLASSIFIER
  // ─────────────────────────────────────────────────────────────

  static DetectedRole _classifyRole(String jdLower, String titleLower) {
    // Priority: title keywords first, then body signals
    for (final entry in _roleSignals.entries) {
      if (entry.value.any((kw) => titleLower.contains(kw))) return entry.key;
    }
    // Body-based classification with signal counting
    final scores = <DetectedRole, int>{};
    for (final entry in _roleBodySignals.entries) {
      scores[entry.key] =
          entry.value.where((kw) => jdLower.contains(kw)).length;
    }
    if (scores.isEmpty) return DetectedRole.unknown;
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.value > 0 ? sorted.first.key : DetectedRole.unknown;
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 3 — JD REQUIREMENTS EXTRACTOR
  // ─────────────────────────────────────────────────────────────

  static _JdRequirements _extractJdRequirements(
      String jdLower, List<String> structuredSkills) {
    final skills = <String>{
      ...structuredSkills.map((s) => s.toLowerCase()),
      ..._knownSkills.where((s) => jdLower.contains(s)),
    }.toList();
    final tools   = _knownTools.where((t) => jdLower.contains(t)).toList();
    final domains  = _knownDomains.where((d) => jdLower.contains(d)).toList();
    final certs    = _knownCerts.where((c) => jdLower.contains(c)).toList();
    return _JdRequirements(
        skills: skills, tools: tools, domains: domains, preferredCerts: certs);
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 4 — DIMENSION SCORERS
  // ─────────────────────────────────────────────────────────────

  /// Core skills: 30 pts weight
  static _SkillResult _scoreCoreSkills(
      ExtractedProfile profile, _JdRequirements jd) {
    if (jd.skills.isEmpty) return _SkillResult(score: 50, matched: [], missing: []);

    final matched = <String>[];
    final missing = <String>[];

    for (final skill in jd.skills) {
      if (_skillMatch(skill, profile.skills) ||
          _skillMatch(skill, profile.rawText.toLowerCase().split(RegExp(r'\W+')))) {
        matched.add(skill);
      } else {
        missing.add(skill);
      }
    }

    final ratio = matched.length / jd.skills.length;
    return _SkillResult(
      score: (ratio * 100).round().clamp(0, 100),
      matched: matched,
      missing: missing,
    );
  }

  /// Role responsibility match: 25 pts weight
  static int _scoreRoleResponsibility(
      ExtractedProfile profile, DetectedRole role, String jdLower) {
    final expectedKws = _roleResponsibilityKeywords[role] ?? [];
    if (expectedKws.isEmpty) return 40;

    final cvLower = profile.rawText.toLowerCase();
    final hits = expectedKws.where((kw) => cvLower.contains(kw)).length;
    final ratio = hits / expectedKws.length;

    // Bonus if current title matches role
    final titleBonus = _titleMatchesRole(profile.currentTitle ?? '', role) ? 15 : 0;
    return ((ratio * 85) + titleBonus).round().clamp(0, 100);
  }

  /// Experience: 15 pts weight
  static _ExpResult _scoreExperience(
      ExtractedProfile profile, int minExp, int maxExp) {
    final exp = profile.experienceYears;
    if (exp == null) return _ExpResult(score: 40, isMatch: false);

    if (exp >= minExp && exp <= maxExp) {
      return _ExpResult(score: 100, isMatch: true);
    }
    if (exp > maxExp) {
      // Overqualified — partial score
      return _ExpResult(score: 65, isMatch: false);
    }
    final gap = minExp - exp;
    final s = gap <= 1 ? 70 : gap <= 2 ? 50 : gap <= 3 ? 30 : 10;
    return _ExpResult(score: s, isMatch: false);
  }

  /// Domain match: 10 pts weight
  static _DomainResult _scoreDomain(
      ExtractedProfile profile, List<String> jdDomains, String jdLower) {
    final cvLower = profile.rawText.toLowerCase();
    if (jdDomains.isEmpty) {
      // Fall back to industry keywords
      final industryHits = profile.industries
          .where((i) => jdLower.contains(i))
          .toList();
      return _DomainResult(
          score: industryHits.isNotEmpty ? 70 : 40, matched: industryHits);
    }
    final matched =
        jdDomains.where((d) => cvLower.contains(d)).toList();
    final ratio = matched.length / jdDomains.length;
    return _DomainResult(
        score: (ratio * 100).round().clamp(0, 100), matched: matched);
  }

  /// Tools / technology: 10 pts weight
  static _ToolResult _scoreTools(
      ExtractedProfile profile, List<String> jdTools) {
    if (jdTools.isEmpty) return _ToolResult(score: 50, matched: [], missing: []);
    final cvLower = profile.rawText.toLowerCase();
    final matched =
        jdTools.where((t) => cvLower.contains(t)).toList();
    final missing =
        jdTools.where((t) => !cvLower.contains(t)).toList();
    final ratio = matched.length / jdTools.length;
    return _ToolResult(
      score: (ratio * 100).round().clamp(0, 100),
      matched: matched,
      missing: missing,
    );
  }

  /// Education / certs: 5 pts weight
  static int _scoreEducation(
      ExtractedProfile profile, List<String> preferredCerts) {
    int score = 30; // base
    // Degree present
    if (profile.education.isNotEmpty) score += 30;
    // Cert match
    final cvLower = profile.rawText.toLowerCase();
    final certHits = preferredCerts.where((c) => cvLower.contains(c)).length;
    score += (certHits * 20).clamp(0, 40);
    return score.clamp(0, 100);
  }

  /// Profile quality: 5 pts weight
  static int _scoreProfileQuality(ExtractedProfile profile) {
    int score = 0;
    if (profile.skills.length >= 5)          score += 25;
    if (profile.tools.isNotEmpty)             score += 20;
    if (profile.jobTitlesHeld.isNotEmpty)     score += 20;
    if (profile.responsibilities.isNotEmpty)  score += 20;
    if (profile.education.isNotEmpty)         score += 15;
    return score.clamp(0, 100);
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 5 — WEIGHTED TOTAL
  // ─────────────────────────────────────────────────────────────

  static int _weightedTotal({
    required int coreSkill,
    required int roleResp,
    required int experience,
    required int domain,
    required int tools,
    required int education,
    required int quality,
  }) {
    final total = (coreSkill * 0.30) +
        (roleResp * 0.25) +
        (experience * 0.15) +
        (domain * 0.10) +
        (tools * 0.10) +
        (education * 0.05) +
        (quality * 0.05);
    return total.round().clamp(0, 100);
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 6 — RECOMMENDATION
  // ─────────────────────────────────────────────────────────────

  static ReferralRecommendation _deriveRecommendation(
      int overall, int coreSkill) {
    // Core skill must be solid even if overall is high
    if (overall >= 82 && coreSkill >= 70) {
      return ReferralRecommendation.stronglyRecommend;
    }
    if (overall >= 68) return ReferralRecommendation.recommend;
    if (overall >= 50) return ReferralRecommendation.maybe;
    return ReferralRecommendation.notRecommended;
  }

  // ─────────────────────────────────────────────────────────────
  // STEP 7 — NARRATIVE BUILDERS
  // ─────────────────────────────────────────────────────────────

  static List<String> _buildStrongAreas({
    required ExtractedProfile profile,
    required _SkillResult coreSkill,
    required int roleResp,
    required _ExpResult experience,
    required _DomainResult domain,
  }) {
    final areas = <String>[];
    if (coreSkill.matched.isNotEmpty) {
      areas.add(
          'Covers ${coreSkill.matched.length} required skills: ${coreSkill.matched.take(3).join(", ")}');
    }
    if (experience.isMatch) {
      areas.add(
          'Experience level (${profile.experienceYears} yrs) is within required range');
    }
    if (roleResp >= 70) {
      areas.add('Strong alignment with role responsibilities and work style');
    }
    if (domain.matched.isNotEmpty) {
      areas.add('Domain expertise in ${domain.matched.take(2).join(", ")}');
    }
    if (profile.certifications.isNotEmpty) {
      areas.add('Holds relevant certifications: ${profile.certifications.take(2).join(", ")}');
    }
    return areas.take(5).toList();
  }

  static List<String> _buildWeakAreas({
    required _SkillResult coreSkill,
    required _ExpResult experience,
    required _DomainResult domain,
    required _ToolResult tools,
  }) {
    final areas = <String>[];
    if (coreSkill.missing.isNotEmpty) {
      areas.add(
          'Missing ${coreSkill.missing.length} required skills: ${coreSkill.missing.take(2).join(", ")}');
    }
    if (!experience.isMatch) {
      areas.add('Experience does not perfectly match the required range');
    }
    if (domain.score < 50) {
      areas.add('Limited domain-specific experience visible in CV');
    }
    if (tools.missing.isNotEmpty) {
      areas.add('Tool gaps: ${tools.missing.take(2).join(", ")}');
    }
    return areas.take(4).toList();
  }

  static List<String> _buildSuggestions({
    required List<String> missingSkills,
    required List<String> missingTools,
    required List<String> weakAreas,
  }) {
    final sug = <String>[];
    for (final skill in missingSkills.take(3)) {
      sug.add('Add $skill to your skill set or highlight relevant experience');
    }
    for (final tool in missingTools.take(2)) {
      sug.add('Gain hands-on experience with $tool');
    }
    if (weakAreas.any((a) => a.contains('domain'))) {
      sug.add('Highlight any domain-specific projects, certifications, or clients');
    }
    sug.add('Quantify achievements with metrics (e.g. "reduced defects by 30%")');
    return sug.take(6).toList();
  }

  static String _buildProviderSummary({
    required int overall,
    required String role,
    required List<String> matched,
    required List<String> missing,
    required ReferralRecommendation rec,
  }) {
    final recLabel = switch (rec) {
      ReferralRecommendation.stronglyRecommend => 'Strongly recommend referring.',
      ReferralRecommendation.recommend         => 'Worth referring.',
      ReferralRecommendation.maybe             => 'Borderline — review carefully.',
      ReferralRecommendation.notRecommended    => 'Not recommended at this time.',
    };
    final matchedStr = matched.isEmpty ? 'few required skills' : matched.take(3).join(', ');
    final missingStr = missing.isEmpty ? 'none' : missing.take(2).join(', ');
    return '$overall% match for $role role. '
        'Covers: $matchedStr. Missing: $missingStr. $recLabel';
  }

  static String _buildRoleUnderstanding(
      DetectedRole role, String roleLabel, String jdTitle) {
    final context = _roleContextMap[role] ??
        'a cross-functional professional role requiring broad technical skills.';
    return 'The JD "${jdTitle.isEmpty ? "this role" : jdTitle}" has been classified as '
        '$roleLabel. This role typically requires $context '
        'The CV has been scored against these specific expectations.';
  }

  // ─────────────────────────────────────────────────────────────
  // CV PARSING HELPERS
  // ─────────────────────────────────────────────────────────────

  static String? _extractTitle(String lower) {
    for (final title in _knownTitles) {
      if (lower.contains(title)) return title;
    }
    return null;
  }

  static int? _extractExperienceYears(String lower) {
    final patterns = [
      RegExp(r'(\d+)\+?\s*years?\s+of\s+experience'),
      RegExp(r'(\d+)\+?\s*years?\s+experience'),
      RegExp(r'experience\s+of\s+(\d+)\+?\s*years?'),
      RegExp(r'(\d+)\+?\s*yrs?\s+(?:of\s+)?experience'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(lower);
      if (m != null) return int.tryParse(m.group(1) ?? '');
    }
    return null;
  }

  static List<String> _extractSkills(String lower) =>
      _knownSkills.where((s) => lower.contains(s)).toList();

  static List<String> _extractTools(String lower) =>
      _knownTools.where((t) => lower.contains(t)).toList();

  static List<String> _extractDomains(String lower) =>
      _knownDomains.where((d) => lower.contains(d)).toList();

  static List<String> _extractEducation(String lower) {
    const degrees = ['bachelor', 'master', 'mba', 'phd', 'b.tech', 'm.tech',
      'b.e', 'm.e', 'bsc', 'msc', 'degree'];
    return degrees.where((d) => lower.contains(d)).toList();
  }

  static List<String> _extractCertifications(String lower) =>
      _knownCerts.where((c) => lower.contains(c)).toList();

  static List<String> _extractJobTitles(String lower) =>
      _knownTitles.where((t) => lower.contains(t)).toList();

  static List<String> _extractResponsibilities(String lower) {
    const verbs = ['developed', 'designed', 'built', 'implemented', 'managed',
      'led', 'architected', 'delivered', 'deployed', 'automated', 'tested',
      'analysed', 'collaborated', 'maintained', 'optimised'];
    return verbs.where((v) => lower.contains(v)).toList();
  }

  static List<String> _extractIndustries(String lower) =>
      _knownIndustries.where((i) => lower.contains(i)).toList();

  // ─────────────────────────────────────────────────────────────
  // SKILL MATCHING
  // ─────────────────────────────────────────────────────────────

  static bool _skillMatch(String skill, Iterable<String> source) {
    final n = skill.toLowerCase().trim();
    if (source.contains(n)) return true;
    // Alias check
    for (final group in _skillAliases) {
      if (group.contains(n) && group.any((a) => source.contains(a))) return true;
    }
    return false;
  }

  static bool _titleMatchesRole(String title, DetectedRole role) {
    final kws = _roleSignals[role] ?? [];
    return kws.any((kw) => title.contains(kw));
  }

  // ─────────────────────────────────────────────────────────────
  // KNOWLEDGE BASES
  // ─────────────────────────────────────────────────────────────

  static const _roleSignals = <DetectedRole, List<String>>{
    DetectedRole.qaEngineer:       ['qa', 'quality assurance', 'test engineer', 'sdet', 'quality engineer'],
    DetectedRole.devOpsEngineer:   ['devops', 'site reliability', 'sre', 'platform engineer'],
    DetectedRole.dataScientist:    ['data scientist', 'machine learning engineer', 'ml engineer'],
    DetectedRole.dataEngineer:     ['data engineer', 'etl', 'pipeline engineer'],
    DetectedRole.dataAnalyst:      ['data analyst', 'business intelligence', 'bi analyst'],
    DetectedRole.businessAnalyst:  ['business analyst', 'ba ', 'product analyst', 'functional analyst'],
    DetectedRole.productManager:   ['product manager', 'product owner', 'pm '],
    DetectedRole.cloudEngineer:    ['cloud engineer', 'aws engineer', 'azure engineer', 'gcp engineer'],
    DetectedRole.frontendDeveloper:['frontend', 'front-end', 'ui developer', 'react developer'],
    DetectedRole.backendDeveloper: ['backend', 'back-end', 'api developer', 'java developer', 'python developer'],
    DetectedRole.fullStackDeveloper:['full stack', 'full-stack', 'fullstack'],
    DetectedRole.mobileDeveloper:  ['mobile developer', 'android developer', 'ios developer', 'flutter developer'],
    DetectedRole.uiUxDesigner:     ['ui/ux', 'ux designer', 'ui designer', 'product designer'],
    DetectedRole.securityEngineer: ['security engineer', 'cybersecurity', 'infosec'],
    DetectedRole.functionalConsultant: ['functional consultant', 'sap consultant', 'oracle consultant'],
    DetectedRole.supportEngineer:  ['support engineer', 'l1', 'l2', 'l3 support', 'technical support'],
    DetectedRole.projectManager:   ['project manager', 'scrum master', 'delivery manager'],
    DetectedRole.mlEngineer:       ['ml engineer', 'deep learning', 'ai engineer'],
  };

  static const _roleBodySignals = <DetectedRole, List<String>>{
    DetectedRole.qaEngineer:       ['test cases', 'bug report', 'regression', 'selenium', 'test plan', 'defect'],
    DetectedRole.devOpsEngineer:   ['ci/cd', 'kubernetes', 'docker', 'jenkins', 'terraform', 'infrastructure'],
    DetectedRole.dataScientist:    ['model training', 'jupyter', 'scikit-learn', 'neural network', 'deep learning'],
    DetectedRole.dataEngineer:     ['spark', 'airflow', 'kafka', 'data pipeline', 'etl', 'redshift'],
    DetectedRole.dataAnalyst:      ['sql', 'tableau', 'power bi', 'dashboard', 'reporting', 'excel'],
    DetectedRole.businessAnalyst:  ['requirements', 'brd', 'frd', 'user story', 'stakeholder', 'gap analysis'],
    DetectedRole.productManager:   ['roadmap', 'product backlog', 'okr', 'go-to-market', 'sprint planning'],
    DetectedRole.cloudEngineer:    ['aws', 'azure', 'gcp', 'cloud formation', 'serverless', 'lambda'],
    DetectedRole.frontendDeveloper:['react', 'vue', 'angular', 'css', 'html', 'javascript', 'typescript'],
    DetectedRole.backendDeveloper: ['api', 'rest', 'microservices', 'database', 'spring boot', 'django'],
    DetectedRole.mobileDeveloper:  ['android', 'ios', 'swift', 'kotlin', 'flutter', 'react native'],
    DetectedRole.softwareEngineer: ['software development', 'coding', 'system design', 'algorithms'],
  };

  static const _roleResponsibilityKeywords = <DetectedRole, List<String>>{
    DetectedRole.qaEngineer:      ['testing', 'test', 'quality', 'bug', 'defect', 'automation', 'regression', 'manual'],
    DetectedRole.devOpsEngineer:  ['deployment', 'pipeline', 'infrastructure', 'monitoring', 'ci/cd', 'container'],
    DetectedRole.dataScientist:   ['model', 'algorithm', 'prediction', 'analysis', 'feature', 'training'],
    DetectedRole.dataAnalyst:     ['analysis', 'report', 'dashboard', 'insight', 'sql', 'visualization'],
    DetectedRole.businessAnalyst: ['requirement', 'analysis', 'stakeholder', 'process', 'documentation', 'workflow'],
    DetectedRole.productManager:  ['product', 'roadmap', 'feature', 'user', 'strategy', 'sprint'],
    DetectedRole.frontendDeveloper:['ui', 'interface', 'component', 'responsive', 'user experience'],
    DetectedRole.backendDeveloper: ['api', 'database', 'service', 'performance', 'scalability'],
    DetectedRole.cloudEngineer:   ['cloud', 'infrastructure', 'scalability', 'availability', 'security'],
    DetectedRole.softwareEngineer:['develop', 'design', 'implement', 'collaborate', 'deliver'],
  };

  static const _roleContextMap = <DetectedRole, String>{
    DetectedRole.qaEngineer:      'manual + automation testing, defect tracking, and quality processes.',
    DetectedRole.devOpsEngineer:  'CI/CD pipelines, infrastructure-as-code, and site reliability.',
    DetectedRole.dataScientist:   'statistical modelling, ML frameworks, and data experimentation.',
    DetectedRole.dataEngineer:    'data pipelines, ETL, warehousing, and streaming platforms.',
    DetectedRole.dataAnalyst:     'SQL, BI tools, dashboarding, and data storytelling.',
    DetectedRole.businessAnalyst: 'requirements gathering, stakeholder management, and process analysis.',
    DetectedRole.productManager:  'product strategy, roadmap, OKRs, and cross-functional delivery.',
    DetectedRole.frontendDeveloper:'UI frameworks, responsive design, and browser performance.',
    DetectedRole.backendDeveloper: 'APIs, databases, microservices, and backend architecture.',
    DetectedRole.cloudEngineer:   'cloud platforms, IaC, security, and cost optimisation.',
    DetectedRole.softwareEngineer:'software design, coding, system design, and agile delivery.',
  };

  static const _roleLabelMap = <DetectedRole, String>{
    DetectedRole.softwareEngineer:    'Software Engineer',
    DetectedRole.frontendDeveloper:   'Frontend Developer',
    DetectedRole.backendDeveloper:    'Backend Developer',
    DetectedRole.fullStackDeveloper:  'Full Stack Developer',
    DetectedRole.devOpsEngineer:      'DevOps Engineer',
    DetectedRole.dataEngineer:        'Data Engineer',
    DetectedRole.dataScientist:       'Data Scientist',
    DetectedRole.mlEngineer:          'ML Engineer',
    DetectedRole.qaEngineer:          'QA Engineer',
    DetectedRole.businessAnalyst:     'Business Analyst',
    DetectedRole.productManager:      'Product Manager',
    DetectedRole.projectManager:      'Project Manager',
    DetectedRole.cloudEngineer:       'Cloud Engineer',
    DetectedRole.securityEngineer:    'Security Engineer',
    DetectedRole.mobileDeveloper:     'Mobile Developer',
    DetectedRole.uiUxDesigner:        'UI/UX Designer',
    DetectedRole.dataAnalyst:         'Data Analyst',
    DetectedRole.functionalConsultant:'Functional Consultant',
    DetectedRole.supportEngineer:     'Support Engineer',
    DetectedRole.unknown:             'Professional',
  };

  // ── Skill alias groups ─────────────────────────────────────
  static const _skillAliases = [
    ['javascript', 'js', 'es6', 'ecmascript'],
    ['typescript', 'ts'],
    ['react', 'reactjs', 'react.js'],
    ['node', 'nodejs', 'node.js'],
    ['python', 'python3', 'py'],
    ['java', 'core java', 'java8', 'java11'],
    ['kubernetes', 'k8s'],
    ['aws', 'amazon web services'],
    ['gcp', 'google cloud'],
    ['azure', 'microsoft azure'],
    ['sql', 'mysql', 'postgresql', 'postgres'],
    ['mongodb', 'mongo'],
    ['machine learning', 'ml'],
    ['ci/cd', 'cicd', 'continuous integration'],
    ['rest', 'restful', 'rest api'],
    ['react native', 'rn'],
  ];

  // ── Known vocabulary lists ─────────────────────────────────
  static const _knownSkills = [
    'java', 'python', 'javascript', 'typescript', 'go', 'rust', 'c++', 'c#',
    'kotlin', 'swift', 'dart', 'scala', 'ruby', 'php',
    'react', 'angular', 'vue', 'node', 'spring boot', 'django', 'flask',
    'sql', 'nosql', 'graphql', 'rest', 'grpc',
    'machine learning', 'deep learning', 'nlp', 'computer vision',
    'data analysis', 'statistics', 'spark', 'hadoop',
    'kubernetes', 'docker', 'terraform', 'ansible', 'jenkins', 'ci/cd',
    'aws', 'azure', 'gcp',
    'agile', 'scrum', 'kanban', 'jira',
    'selenium', 'cypress', 'junit', 'pytest',
    'system design', 'microservices', 'distributed systems',
    'product management', 'product strategy', 'roadmap',
    'business analysis', 'requirements gathering', 'stakeholder management',
    'data visualization', 'tableau', 'power bi',
    'communication', 'leadership', 'problem solving',
  ];

  static const _knownTools = [
    'jira', 'confluence', 'github', 'gitlab', 'bitbucket',
    'jenkins', 'circleci', 'travis', 'github actions',
    'docker', 'kubernetes', 'helm', 'terraform', 'ansible',
    'aws', 'azure', 'gcp', 'lambda', 'ec2', 's3', 'rds',
    'mysql', 'postgresql', 'mongodb', 'redis', 'elasticsearch',
    'kafka', 'rabbitmq', 'airflow',
    'tableau', 'power bi', 'looker', 'grafana', 'kibana',
    'selenium', 'cypress', 'appium', 'postman',
    'figma', 'sketch', 'invision',
    'slack', 'teams', 'zoom',
  ];

  static const _knownDomains = [
    'fintech', 'banking', 'capital markets', 'insurance', 'trading',
    'healthcare', 'health tech', 'pharma', 'clinical',
    'e-commerce', 'retail', 'supply chain', 'logistics',
    'edtech', 'saas', 'b2b', 'b2c',
    'telecom', 'media', 'advertising',
    'manufacturing', 'iot', 'embedded',
    'cybersecurity', 'networking',
  ];

  static const _knownCerts = [
    'aws certified', 'azure certified', 'google cloud certified',
    'pmp', 'prince2', 'csm', 'safe', 'agile',
    'istqb', 'cisa', 'cissp', 'ceh',
    'cfa', 'frm', 'ca ', 'cpa',
    'tableau certified', 'salesforce certified',
  ];

  static const _knownTitles = [
    'software engineer', 'senior software engineer', 'lead engineer',
    'frontend developer', 'backend developer', 'full stack developer',
    'devops engineer', 'site reliability engineer', 'sre',
    'data engineer', 'data scientist', 'ml engineer',
    'data analyst', 'business analyst',
    'product manager', 'product owner',
    'qa engineer', 'test engineer', 'sdet',
    'cloud engineer', 'solutions architect',
    'project manager', 'delivery manager',
    'mobile developer', 'android developer', 'ios developer',
    'ui/ux designer', 'ux researcher',
    'security engineer', 'functional consultant',
  ];

  static const _knownIndustries = [
    'banking', 'finance', 'insurance', 'fintech',
    'healthcare', 'pharma', 'biotech',
    'e-commerce', 'retail',
    'telecom', 'media',
    'manufacturing', 'automotive',
    'consulting', 'services',
  ];
}

// ─────────────────────────────────────────────────────────────
// INTERNAL VALUE OBJECTS
// ─────────────────────────────────────────────────────────────

class _SkillResult {
  const _SkillResult({required this.score, required this.matched, required this.missing});
  final int score;
  final List<String> matched;
  final List<String> missing;
}

class _ExpResult {
  const _ExpResult({required this.score, required this.isMatch});
  final int score;
  final bool isMatch;
}

class _DomainResult {
  const _DomainResult({required this.score, required this.matched});
  final int score;
  final List<String> matched;
}

class _ToolResult {
  const _ToolResult({required this.score, required this.matched, required this.missing});
  final int score;
  final List<String> matched;
  final List<String> missing;
}

class _JdRequirements {
  const _JdRequirements({
    required this.skills,
    required this.tools,
    required this.domains,
    required this.preferredCerts,
  });
  final List<String> skills;
  final List<String> tools;
  final List<String> domains;
  final List<String> preferredCerts;
}

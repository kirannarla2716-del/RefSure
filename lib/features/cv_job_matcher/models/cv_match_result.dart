// lib/features/cv_job_matcher/models/cv_match_result.dart
//
// Rich result produced by CvMatchingEngine.
// Extends the platform's MatchReport concept with CV-specific fields:
// role classification, domain match, tool match, and candidate suggestions.

enum ReferralRecommendation {
  stronglyRecommend,
  recommend,
  maybe,
  notRecommended,
}

enum DetectedRole {
  softwareEngineer,
  frontendDeveloper,
  backendDeveloper,
  fullStackDeveloper,
  devOpsEngineer,
  dataEngineer,
  dataScientist,
  mlEngineer,
  qaEngineer,
  businessAnalyst,
  productManager,
  projectManager,
  cloudEngineer,
  securityEngineer,
  mobileDeveloper,
  uiUxDesigner,
  dataAnalyst,
  functionalConsultant,
  supportEngineer,
  unknown,
}

class CvMatchResult {
  const CvMatchResult({
    required this.overallScore,
    required this.detectedRole,
    required this.roleLabel,
    required this.recommendation,
    required this.matchedSkills,
    required this.missingSkills,
    required this.strongAreas,
    required this.weakAreas,
    required this.candidateSuggestions,
    required this.providerSummary,
    required this.roleUnderstandingSummary,
    required this.coreSkillScore,
    required this.roleResponsibilityScore,
    required this.experienceScore,
    required this.domainScore,
    required this.toolsScore,
    required this.educationScore,
    required this.profileQualityScore,
    required this.experienceMatch,
    required this.domainMatch,
    required this.toolsMatch,
    this.matchedTools = const [],
    this.missingTools = const [],
    this.matchedDomains = const [],
  });

  // ── Core ────────────────────────────────────────────────────
  final int overallScore;                    // 0–100
  final DetectedRole detectedRole;
  final String roleLabel;                    // Human-readable role name
  final ReferralRecommendation recommendation;

  // ── Skills ──────────────────────────────────────────────────
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> matchedTools;
  final List<String> missingTools;
  final List<String> matchedDomains;

  // ── Narrative ───────────────────────────────────────────────
  final List<String> strongAreas;
  final List<String> weakAreas;
  final List<String> candidateSuggestions;
  final String providerSummary;              // 2-line note for provider
  final String roleUnderstandingSummary;     // What role we detected and why

  // ── Sub-scores (each 0–100, weighted to produce overallScore) ─
  final int coreSkillScore;        // weight 30 %
  final int roleResponsibilityScore; // weight 25 %
  final int experienceScore;       // weight 15 %
  final int domainScore;           // weight 10 %
  final int toolsScore;            // weight 10 %
  final int educationScore;        // weight  5 %
  final int profileQualityScore;   // weight  5 %

  // ── Boolean match indicators ────────────────────────────────
  final bool experienceMatch;
  final bool domainMatch;
  final bool toolsMatch;

  // ── Derived helpers ─────────────────────────────────────────
  String get recommendationLabel => switch (recommendation) {
    ReferralRecommendation.stronglyRecommend => '✅ Strongly Recommend',
    ReferralRecommendation.recommend         => '👍 Recommend',
    ReferralRecommendation.maybe             => '🤔 Maybe',
    ReferralRecommendation.notRecommended    => '❌ Not Recommended',
  };

  String get recommendationEmoji => switch (recommendation) {
    ReferralRecommendation.stronglyRecommend => '✅',
    ReferralRecommendation.recommend         => '👍',
    ReferralRecommendation.maybe             => '🤔',
    ReferralRecommendation.notRecommended    => '❌',
  };

  bool get isRecommended =>
      recommendation == ReferralRecommendation.stronglyRecommend ||
      recommendation == ReferralRecommendation.recommend;
}

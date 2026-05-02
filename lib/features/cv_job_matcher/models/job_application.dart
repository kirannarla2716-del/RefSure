// lib/features/cv_job_matcher/models/job_application.dart
//
// Platform application submitted by a requester.
// Extends the core Application model with CV text and
// the auto-generated CvMatchResult.
//
// Firestore path: /referral_applications/{id}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:refsure/features/cv_job_matcher/models/cv_match_result.dart';

enum ApplicationStatus {
  applied,
  underReview,
  shortlisted,
  referred,
  rejected,
  hired,
}

class JobApplication {
  const JobApplication({
    required this.id,
    required this.postedJobId,       // ID of the platform Job
    required this.requesterId,
    required this.requesterName,
    required this.requesterEmail,
    required this.providerId,
    required this.resumeText,        // Extracted text from uploaded CV
    this.resumeFileUrl,
    required this.appliedAt,
    this.status = ApplicationStatus.applied,
    this.matchResult,                // Set automatically after submission
    this.providerNote,
    this.decidedAt,
  });

  final String id;
  final String postedJobId;
  final String requesterId;
  final String requesterName;
  final String requesterEmail;
  final String providerId;
  final String resumeText;
  final String? resumeFileUrl;
  final DateTime appliedAt;
  final ApplicationStatus status;
  final CvMatchResult? matchResult;   // null until auto-match completes
  final String? providerNote;
  final DateTime? decidedAt;

  // ── Derived ────────────────────────────────────────────────

  int get matchScore => matchResult?.overallScore ?? 0;

  String get statusLabel => switch (status) {
    ApplicationStatus.applied     => 'Applied',
    ApplicationStatus.underReview => 'Under Review',
    ApplicationStatus.shortlisted => 'Shortlisted',
    ApplicationStatus.referred    => 'Referred',
    ApplicationStatus.rejected    => 'Rejected',
    ApplicationStatus.hired       => 'Hired',
  };

  bool get hasMatchResult => matchResult != null;

  // ── Firestore ─────────────────────────────────────────────

  Map<String, dynamic> toFirestore() => {
    'postedJobId':    postedJobId,
    'requesterId':    requesterId,
    'requesterName':  requesterName,
    'requesterEmail': requesterEmail,
    'providerId':     providerId,
    'resumeText':     resumeText,
    'resumeFileUrl':  resumeFileUrl,
    'appliedAt':      Timestamp.fromDate(appliedAt),
    'status':         status.name,
    'matchResult':    _matchResultToMap(),
    'providerNote':   providerNote,
    'decidedAt':      decidedAt != null ? Timestamp.fromDate(decidedAt!) : null,
  };

  Map<String, dynamic>? _matchResultToMap() {
    final r = matchResult;
    if (r == null) return null;
    return {
      'overallScore':           r.overallScore,
      'detectedRole':           r.detectedRole.name,
      'roleLabel':              r.roleLabel,
      'recommendation':         r.recommendation.name,
      'matchedSkills':          r.matchedSkills,
      'missingSkills':          r.missingSkills,
      'matchedTools':           r.matchedTools,
      'missingTools':           r.missingTools,
      'matchedDomains':         r.matchedDomains,
      'strongAreas':            r.strongAreas,
      'weakAreas':              r.weakAreas,
      'candidateSuggestions':   r.candidateSuggestions,
      'providerSummary':        r.providerSummary,
      'roleUnderstandingSummary': r.roleUnderstandingSummary,
      'coreSkillScore':         r.coreSkillScore,
      'roleResponsibilityScore':r.roleResponsibilityScore,
      'experienceScore':        r.experienceScore,
      'domainScore':            r.domainScore,
      'toolsScore':             r.toolsScore,
      'educationScore':         r.educationScore,
      'profileQualityScore':    r.profileQualityScore,
      'experienceMatch':        r.experienceMatch,
      'domainMatch':            r.domainMatch,
      'toolsMatch':             r.toolsMatch,
    };
  }

  factory JobApplication.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return JobApplication(
      id:             doc.id,
      postedJobId:    d['postedJobId']    ?? '',
      requesterId:    d['requesterId']    ?? '',
      requesterName:  d['requesterName']  ?? '',
      requesterEmail: d['requesterEmail'] ?? '',
      providerId:     d['providerId']     ?? '',
      resumeText:     d['resumeText']     ?? '',
      resumeFileUrl:  d['resumeFileUrl'],
      appliedAt:      (d['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status:         ApplicationStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'applied'),
        orElse: () => ApplicationStatus.applied),
      matchResult:    d['matchResult'] != null
          ? _matchResultFromMap(Map<String, dynamic>.from(d['matchResult']))
          : null,
      providerNote:   d['providerNote'],
      decidedAt:      (d['decidedAt'] as Timestamp?)?.toDate(),
    );
  }

  static CvMatchResult? _matchResultFromMap(Map<String, dynamic> m) {
    try {
      return CvMatchResult(
        overallScore:             m['overallScore'] ?? 0,
        detectedRole:             DetectedRole.values.firstWhere(
          (r) => r.name == (m['detectedRole'] ?? 'unknown'),
          orElse: () => DetectedRole.unknown),
        roleLabel:                m['roleLabel'] ?? '',
        recommendation:           ReferralRecommendation.values.firstWhere(
          (r) => r.name == (m['recommendation'] ?? 'notRecommended'),
          orElse: () => ReferralRecommendation.notRecommended),
        matchedSkills:            List<String>.from(m['matchedSkills'] ?? []),
        missingSkills:            List<String>.from(m['missingSkills'] ?? []),
        matchedTools:             List<String>.from(m['matchedTools'] ?? []),
        missingTools:             List<String>.from(m['missingTools'] ?? []),
        matchedDomains:           List<String>.from(m['matchedDomains'] ?? []),
        strongAreas:              List<String>.from(m['strongAreas'] ?? []),
        weakAreas:                List<String>.from(m['weakAreas'] ?? []),
        candidateSuggestions:     List<String>.from(m['candidateSuggestions'] ?? []),
        providerSummary:          m['providerSummary'] ?? '',
        roleUnderstandingSummary: m['roleUnderstandingSummary'] ?? '',
        coreSkillScore:           m['coreSkillScore'] ?? 0,
        roleResponsibilityScore:  m['roleResponsibilityScore'] ?? 0,
        experienceScore:          m['experienceScore'] ?? 0,
        domainScore:              m['domainScore'] ?? 0,
        toolsScore:               m['toolsScore'] ?? 0,
        educationScore:           m['educationScore'] ?? 0,
        profileQualityScore:      m['profileQualityScore'] ?? 0,
        experienceMatch:          m['experienceMatch'] ?? false,
        domainMatch:              m['domainMatch'] ?? false,
        toolsMatch:               m['toolsMatch'] ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  JobApplication copyWith({
    ApplicationStatus? status,
    CvMatchResult? matchResult,
    String? providerNote,
    DateTime? decidedAt,
  }) =>
      JobApplication(
        id:             id,
        postedJobId:    postedJobId,
        requesterId:    requesterId,
        requesterName:  requesterName,
        requesterEmail: requesterEmail,
        providerId:     providerId,
        resumeText:     resumeText,
        resumeFileUrl:  resumeFileUrl,
        appliedAt:      appliedAt,
        status:         status ?? this.status,
        matchResult:    matchResult ?? this.matchResult,
        providerNote:   providerNote ?? this.providerNote,
        decidedAt:      decidedAt ?? this.decidedAt,
      );
}

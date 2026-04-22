// lib/models/models.dart
// Enhanced v2.0 — Full referral platform data model
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────

enum UserRole { seeker, provider }
enum OnboardingSource { manual, linkedin, cvUpload }

enum AppStatus {
  pending,      // Just applied
  underReview,  // Provider opened the application
  strongMatch,  // Score 80+, flagged by engine
  needsReview,  // Score 60-79, borderline
  shortlisted,  // Provider manually shortlisted
  referred,     // Provider submitted referral
  interview,    // Interview scheduled
  hired,        // Offer accepted
  notSelected,  // Rejected
  closed,       // Job closed before decision
}

enum MatchBand { sureShotMatch, excellentMatch, goodToGo, needsReview, lowMatch }

enum ReferralBadgeTier { bronze, silver, gold, diamond, platinum }

enum JobSource { manual, careersPortal }

// ─────────────────────────────────────────────────────────────
// BADGE
// ─────────────────────────────────────────────────────────────

class ReferralBadge {
  final ReferralBadgeTier tier;
  final String label, emoji;
  const ReferralBadge(this.tier, this.label, this.emoji);

  static ReferralBadge? fromCount(int n) {
    if (n >= 300) return const ReferralBadge(ReferralBadgeTier.platinum, 'Platinum', '🏆');
    if (n >= 100) return const ReferralBadge(ReferralBadgeTier.diamond,  'Diamond',  '💎');
    if (n >= 30)  return const ReferralBadge(ReferralBadgeTier.gold,     'Gold',     '🥇');
    if (n >= 10)  return const ReferralBadge(ReferralBadgeTier.silver,   'Silver',   '🥈');
    if (n >= 1)   return const ReferralBadge(ReferralBadgeTier.bronze,   'Bronze',   '🥉');
    return null;
  }
}

// ─────────────────────────────────────────────────────────────
// MATCH REPORT — full intelligent match breakdown
// ─────────────────────────────────────────────────────────────

class MatchReport {
  final int score;                      // 0–100
  final MatchBand band;
  final String bandLabel;
  final String recommendation;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> strengths;
  final List<String> gaps;
  final int skillScore;                 // sub-score breakdown
  final int experienceScore;
  final int locationScore;
  final int contextScore;               // semantic/contextual
  final DateTime computedAt;

  MatchReport({
    required this.score,
    required this.band,
    required this.bandLabel,
    required this.recommendation,
    required this.matchedSkills,
    required this.missingSkills,
    required this.strengths,
    required this.gaps,
    required this.skillScore,
    required this.experienceScore,
    required this.locationScore,
    required this.contextScore,
    DateTime? computedAt,
  }) : computedAt = computedAt ?? DateTime.now();

  static MatchBand bandFromScore(int s) {
    if (s >= 90) return MatchBand.sureShotMatch;
    if (s >= 80) return MatchBand.excellentMatch;
    if (s >= 70) return MatchBand.goodToGo;
    if (s >= 60) return MatchBand.needsReview;
    return MatchBand.lowMatch;
  }

  static String labelFromBand(MatchBand b) => switch (b) {
    MatchBand.sureShotMatch => '🎯 Sure-shot Match',
    MatchBand.excellentMatch => '⭐ Excellent Match',
    MatchBand.goodToGo      => '✅ Good to Go',
    MatchBand.needsReview   => '⚠️ Needs Review',
    MatchBand.lowMatch      => '🔴 Low Match',
  };

  Map<String, dynamic> toMap() => {
    'score': score,
    'band': band.name,
    'bandLabel': bandLabel,
    'recommendation': recommendation,
    'matchedSkills': matchedSkills,
    'missingSkills': missingSkills,
    'strengths': strengths,
    'gaps': gaps,
    'skillScore': skillScore,
    'experienceScore': experienceScore,
    'locationScore': locationScore,
    'contextScore': contextScore,
    'computedAt': Timestamp.fromDate(computedAt),
  };

  factory MatchReport.fromMap(Map<String, dynamic> d) {
    final score = d['score'] ?? 0;
    final band  = MatchBand.values.firstWhere(
      (b) => b.name == (d['band'] ?? 'lowMatch'),
      orElse: () => MatchBand.lowMatch);
    return MatchReport(
      score: score, band: band, bandLabel: d['bandLabel'] ?? '',
      recommendation: d['recommendation'] ?? '',
      matchedSkills: List<String>.from(d['matchedSkills'] ?? []),
      missingSkills: List<String>.from(d['missingSkills'] ?? []),
      strengths: List<String>.from(d['strengths'] ?? []),
      gaps: List<String>.from(d['gaps'] ?? []),
      skillScore: d['skillScore'] ?? 0,
      experienceScore: d['experienceScore'] ?? 0,
      locationScore: d['locationScore'] ?? 0,
      contextScore: d['contextScore'] ?? 0,
      computedAt: (d['computedAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// APP USER
// ─────────────────────────────────────────────────────────────

class AppUser {
  final String id;
  final UserRole role;
  final String name;
  final String headline;
  final String? company;
  final bool verified;           // Manual verification by admin
  final bool orgVerified;        // Org email OTP verified
  final String title;
  final String location;
  final int experience;
  final List<String> skills;
  final List<String> preferredRoles;
  final String bio;
  final String? photoUrl;
  final String? email;
  final String? orgEmail;        // Work email (verified separately)
  final String? linkedinUrl;
  final String? resumeUrl;       // Firebase Storage URL
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final OnboardingSource onboardingSource;

  // Seeker fields
  final String? education;
  final String? currentCompany;
  final String? noticePeriod;
  final String? expectedSalary;
  final bool activelyLooking;
  final int profileComplete;
  final int referralsReceived;

  // Provider fields
  final int referralsMade;
  final int successfulReferrals;   // hired outcomes
  final int totalJobsPosted;
  final int successRate;           // percentage
  final String responseTime;       // display string
  final int avgResponseHours;
  final double responseRate;       // 0.0–1.0
  final double trustScore;         // computed 0–100

  AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.headline,
    this.company,
    this.verified = false,
    this.orgVerified = false,
    required this.title,
    required this.location,
    required this.experience,
    required this.skills,
    this.preferredRoles = const [],
    required this.bio,
    this.photoUrl,
    this.email,
    this.orgEmail,
    this.linkedinUrl,
    this.resumeUrl,
    DateTime? createdAt,
    this.lastActiveAt,
    this.onboardingSource = OnboardingSource.manual,
    this.education,
    this.currentCompany,
    this.noticePeriod,
    this.expectedSalary,
    this.activelyLooking = false,
    this.profileComplete = 30,
    this.referralsReceived = 0,
    this.referralsMade = 0,
    this.successfulReferrals = 0,
    this.totalJobsPosted = 0,
    this.successRate = 0,
    this.responseTime = '< 48h',
    this.avgResponseHours = 48,
    this.responseRate = 1.0,
    this.trustScore = 0.0,
  }) : createdAt = createdAt ?? DateTime.now();

  ReferralBadge? get badge => ReferralBadge.fromCount(referralsMade);

  bool get isTopProvider => referralsMade >= 10 && successRate >= 70;

  // Compute trust score from various signals
  double get computedTrustScore {
    double s = 0;
    if (orgVerified) s += 30;
    if (verified)    s += 20;
    if (profileComplete >= 80) s += 15;
    s += (successRate / 100) * 20;
    if (responseRate >= 0.8) s += 10;
    if (referralsMade >= 5)  s += 5;
    return s.clamp(0, 100);
  }

  Map<String, dynamic> toFirestore() => {
    'id': id, 'role': role.name, 'name': name, 'headline': headline,
    'company': company, 'verified': verified, 'orgVerified': orgVerified,
    'title': title, 'location': location, 'experience': experience,
    'skills': skills, 'preferredRoles': preferredRoles, 'bio': bio,
    'photoUrl': photoUrl, 'email': email, 'orgEmail': orgEmail,
    'linkedinUrl': linkedinUrl, 'resumeUrl': resumeUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'lastActiveAt': lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
    'onboardingSource': onboardingSource.name,
    'education': education, 'currentCompany': currentCompany,
    'noticePeriod': noticePeriod, 'expectedSalary': expectedSalary,
    'activelyLooking': activelyLooking, 'profileComplete': profileComplete,
    'referralsReceived': referralsReceived, 'referralsMade': referralsMade,
    'successfulReferrals': successfulReferrals, 'totalJobsPosted': totalJobsPosted,
    'successRate': successRate, 'responseTime': responseTime,
    'avgResponseHours': avgResponseHours, 'responseRate': responseRate,
    'trustScore': computedTrustScore,
  };

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      role: d['role'] == 'provider' ? UserRole.provider : UserRole.seeker,
      name: d['name'] ?? '',
      headline: d['headline'] ?? '',
      company: d['company'],
      verified: d['verified'] ?? false,
      orgVerified: d['orgVerified'] ?? false,
      title: d['title'] ?? '',
      location: d['location'] ?? '',
      experience: d['experience'] ?? 0,
      skills: List<String>.from(d['skills'] ?? []),
      preferredRoles: List<String>.from(d['preferredRoles'] ?? []),
      bio: d['bio'] ?? '',
      photoUrl: d['photoUrl'],
      email: d['email'],
      orgEmail: d['orgEmail'],
      linkedinUrl: d['linkedinUrl'],
      resumeUrl: d['resumeUrl'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (d['lastActiveAt'] as Timestamp?)?.toDate(),
      onboardingSource: OnboardingSource.values.firstWhere(
        (o) => o.name == (d['onboardingSource'] ?? 'manual'),
        orElse: () => OnboardingSource.manual),
      education: d['education'],
      currentCompany: d['currentCompany'],
      noticePeriod: d['noticePeriod'],
      expectedSalary: d['expectedSalary'],
      activelyLooking: d['activelyLooking'] ?? false,
      profileComplete: d['profileComplete'] ?? 30,
      referralsReceived: d['referralsReceived'] ?? 0,
      referralsMade: d['referralsMade'] ?? 0,
      successfulReferrals: d['successfulReferrals'] ?? 0,
      totalJobsPosted: d['totalJobsPosted'] ?? 0,
      successRate: d['successRate'] ?? 0,
      responseTime: d['responseTime'] ?? '< 48h',
      avgResponseHours: d['avgResponseHours'] ?? 48,
      responseRate: (d['responseRate'] ?? 1.0).toDouble(),
      trustScore: (d['trustScore'] ?? 0.0).toDouble(),
    );
  }

  AppUser copyWith({
    String? name, String? bio, String? headline, String? photoUrl,
    bool? activelyLooking, int? profileComplete, List<String>? skills,
    String? noticePeriod, String? expectedSalary, String? orgEmail,
    bool? orgVerified, String? resumeUrl, String? linkedinUrl,
    String? company, String? title, String? location, int? experience,
    List<String>? preferredRoles, String? education,
  }) => AppUser(
    id: id, role: role, name: name ?? this.name, headline: headline ?? this.headline,
    company: company ?? this.company, verified: verified,
    orgVerified: orgVerified ?? this.orgVerified, title: title ?? this.title,
    location: location ?? this.location, experience: experience ?? this.experience,
    skills: skills ?? this.skills, preferredRoles: preferredRoles ?? this.preferredRoles,
    bio: bio ?? this.bio, photoUrl: photoUrl ?? this.photoUrl, email: email,
    orgEmail: orgEmail ?? this.orgEmail, linkedinUrl: linkedinUrl ?? this.linkedinUrl,
    resumeUrl: resumeUrl ?? this.resumeUrl, createdAt: createdAt,
    lastActiveAt: DateTime.now(), onboardingSource: onboardingSource,
    education: education ?? this.education, currentCompany: currentCompany,
    noticePeriod: noticePeriod ?? this.noticePeriod,
    expectedSalary: expectedSalary ?? this.expectedSalary,
    activelyLooking: activelyLooking ?? this.activelyLooking,
    profileComplete: profileComplete ?? this.profileComplete,
    referralsReceived: referralsReceived, referralsMade: referralsMade,
    successfulReferrals: successfulReferrals, totalJobsPosted: totalJobsPosted,
    successRate: successRate, responseTime: responseTime,
    avgResponseHours: avgResponseHours, responseRate: responseRate,
  );
}

// ─────────────────────────────────────────────────────────────
// JOB
// ─────────────────────────────────────────────────────────────

class Job {
  final String id;
  final String providerId;
  final String company;
  final String companyLogo;
  final String title;
  final String department;
  final String location;
  final String workMode;
  final int minExp, maxExp;
  final int salaryMin, salaryMax;
  final List<String> skills;
  final List<String> preferredSkills;
  final List<String> tags;          // e.g. ['urgent','fintech','senior']
  final String description;
  final String? providerNote;       // Private note from provider
  final String status;
  final int applicants;
  final int viewCount;
  final String deadline;
  final DateTime postedAt;
  final String jobRefId;
  final bool isHot;                 // Flagged as hot/urgent
  final JobSource source;
  final String? externalUrl;        // Careers portal link

  Job({
    required this.id,
    required this.providerId,
    required this.company,
    required this.companyLogo,
    required this.title,
    required this.department,
    required this.location,
    required this.workMode,
    required this.minExp,
    required this.maxExp,
    this.salaryMin = 0,
    this.salaryMax = 0,
    required this.skills,
    this.preferredSkills = const [],
    this.tags = const [],
    required this.description,
    this.providerNote,
    this.status = 'active',
    this.applicants = 0,
    this.viewCount = 0,
    required this.deadline,
    DateTime? postedAt,
    this.jobRefId = '',
    this.isHot = false,
    this.source = JobSource.manual,
    this.externalUrl,
  }) : postedAt = postedAt ?? DateTime.now();

  bool get isNew => DateTime.now().difference(postedAt).inDays <= 1;
  bool get isRecent => DateTime.now().difference(postedAt).inDays <= 10;

  Map<String, dynamic> toFirestore() => {
    'providerId': providerId, 'company': company, 'companyLogo': companyLogo,
    'title': title, 'department': department, 'location': location,
    'workMode': workMode, 'minExp': minExp, 'maxExp': maxExp,
    'salaryMin': salaryMin, 'salaryMax': salaryMax, 'skills': skills,
    'preferredSkills': preferredSkills, 'tags': tags, 'description': description,
    'providerNote': providerNote, 'status': status, 'applicants': applicants,
    'viewCount': viewCount, 'deadline': deadline, 'postedAt': Timestamp.fromDate(postedAt),
    'jobRefId': jobRefId, 'isHot': isHot, 'source': source.name,
    'externalUrl': externalUrl,
  };

  factory Job.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      providerId: d['providerId'] ?? '',
      company: d['company'] ?? '',
      companyLogo: d['companyLogo'] ?? 'C',
      title: d['title'] ?? '',
      department: d['department'] ?? '',
      location: d['location'] ?? '',
      workMode: d['workMode'] ?? 'Hybrid',
      minExp: d['minExp'] ?? 0,
      maxExp: d['maxExp'] ?? 10,
      salaryMin: d['salaryMin'] ?? 0,
      salaryMax: d['salaryMax'] ?? 0,
      skills: List<String>.from(d['skills'] ?? []),
      preferredSkills: List<String>.from(d['preferredSkills'] ?? []),
      tags: List<String>.from(d['tags'] ?? []),
      description: d['description'] ?? '',
      providerNote: d['providerNote'],
      status: d['status'] ?? 'active',
      applicants: d['applicants'] ?? 0,
      viewCount: d['viewCount'] ?? 0,
      deadline: d['deadline'] ?? '',
      postedAt: (d['postedAt'] as Timestamp?)?.toDate(),
      jobRefId: d['jobRefId'] ?? '',
      isHot: d['isHot'] ?? false,
      source: JobSource.values.firstWhere(
        (s) => s.name == (d['source'] ?? 'manual'), orElse: () => JobSource.manual),
      externalUrl: d['externalUrl'],
    );
  }

  Job copyWith({int? applicants, String? status, int? viewCount}) => Job(
    id: id, providerId: providerId, company: company, companyLogo: companyLogo,
    title: title, department: department, location: location, workMode: workMode,
    minExp: minExp, maxExp: maxExp, salaryMin: salaryMin, salaryMax: salaryMax,
    skills: skills, preferredSkills: preferredSkills, tags: tags, description: description,
    providerNote: providerNote, status: status ?? this.status,
    applicants: applicants ?? this.applicants, viewCount: viewCount ?? this.viewCount,
    deadline: deadline, postedAt: postedAt, jobRefId: jobRefId,
    isHot: isHot, source: source, externalUrl: externalUrl,
  );
}

// ─────────────────────────────────────────────────────────────
// APPLICATION
// ─────────────────────────────────────────────────────────────

class Application {
  final String id;
  final String jobId;
  final String seekerId;
  final String providerId;
  final AppStatus status;
  final int matchScore;
  final MatchReport? matchReport;   // Full breakdown
  final DateTime appliedAt;
  final DateTime updatedAt;
  final DateTime? viewedAt;         // When provider first opened
  final String? providerNote;
  final bool strongMatchFlag;       // Auto-flagged by engine if score >= 80

  Application({
    required this.id,
    required this.jobId,
    required this.seekerId,
    required this.providerId,
    this.status = AppStatus.pending,
    required this.matchScore,
    this.matchReport,
    DateTime? appliedAt,
    DateTime? updatedAt,
    this.viewedAt,
    this.providerNote,
    this.strongMatchFlag = false,
  })  : appliedAt = appliedAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get statusLabel => switch (status) {
    AppStatus.pending       => 'Pending',
    AppStatus.underReview   => 'Under Review',
    AppStatus.strongMatch   => '🎯 Strong Match',
    AppStatus.needsReview   => '⚠️ Needs Review',
    AppStatus.shortlisted   => 'Shortlisted',
    AppStatus.referred      => '✅ Referred',
    AppStatus.interview     => '📅 Interview',
    AppStatus.hired         => '🎉 Hired',
    AppStatus.notSelected   => 'Not Selected',
    AppStatus.closed        => 'Position Closed',
    _ => 'Pending',
  };

  String get statusKey => status.name;

  Map<String, dynamic> toFirestore() => {
    'jobId': jobId, 'seekerId': seekerId, 'providerId': providerId,
    'status': status.name, 'matchScore': matchScore,
    'matchReport': matchReport?.toMap(),
    'appliedAt': Timestamp.fromDate(appliedAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
    'providerNote': providerNote,
    'strongMatchFlag': strongMatchFlag,
  };

  factory Application.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Application(
      id: doc.id,
      jobId: d['jobId'] ?? '',
      seekerId: d['seekerId'] ?? '',
      providerId: d['providerId'] ?? '',
      status: AppStatus.values.firstWhere(
        (s) => s.name == (d['status'] ?? 'pending'),
        orElse: () => AppStatus.pending),
      matchScore: d['matchScore'] ?? 0,
      matchReport: d['matchReport'] != null
          ? MatchReport.fromMap(Map<String, dynamic>.from(d['matchReport']))
          : null,
      appliedAt: (d['appliedAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      viewedAt:  (d['viewedAt']  as Timestamp?)?.toDate(),
      providerNote: d['providerNote'],
      strongMatchFlag: d['strongMatchFlag'] ?? false,
    );
  }

  Application copyWith({
    AppStatus? status, String? providerNote, DateTime? viewedAt}) =>
    Application(
      id: id, jobId: jobId, seekerId: seekerId, providerId: providerId,
      status: status ?? this.status, matchScore: matchScore,
      matchReport: matchReport, appliedAt: appliedAt, updatedAt: DateTime.now(),
      viewedAt: viewedAt ?? this.viewedAt, providerNote: providerNote ?? this.providerNote,
      strongMatchFlag: strongMatchFlag);
}

// ─────────────────────────────────────────────────────────────
// MESSAGE
// ─────────────────────────────────────────────────────────────

class Message {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final DateTime sentAt;
  final bool read;

  Message({
    required this.id, required this.fromId, required this.toId,
    required this.text, DateTime? sentAt, this.read = false,
  }) : sentAt = sentAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'fromId': fromId, 'toId': toId, 'text': text,
    'sentAt': Timestamp.fromDate(sentAt), 'read': read,
  };

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id, fromId: d['fromId'] ?? '', toId: d['toId'] ?? '',
      text: d['text'] ?? '', sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      read: d['read'] ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATION
// ─────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String text;
  final bool read;
  final DateTime createdAt;
  final String? actionRoute;   // Deep link on tap

  AppNotification({
    required this.id, required this.userId, required this.type,
    required this.text, this.read = false, DateTime? createdAt,
    this.actionRoute,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toFirestore() => {
    'userId': userId, 'type': type, 'text': text, 'read': read,
    'createdAt': Timestamp.fromDate(createdAt), 'actionRoute': actionRoute,
  };

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id, userId: d['userId'] ?? '', type: d['type'] ?? 'info',
      text: d['text'] ?? '', read: d['read'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      actionRoute: d['actionRoute'],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// OTP VERIFICATION RECORD
// ─────────────────────────────────────────────────────────────

class OtpRecord {
  final String id;
  final String email;
  final String otp;
  final String userId;
  final DateTime expiresAt;
  final bool verified;

  OtpRecord({
    required this.id, required this.email, required this.otp,
    required this.userId, required this.expiresAt, this.verified = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toFirestore() => {
    'email': email, 'otp': otp, 'userId': userId,
    'expiresAt': Timestamp.fromDate(expiresAt), 'verified': verified,
  };

  factory OtpRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return OtpRecord(
      id: doc.id, email: d['email'] ?? '', otp: d['otp'] ?? '',
      userId: d['userId'] ?? '',
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verified: d['verified'] ?? false,
    );
  }
}

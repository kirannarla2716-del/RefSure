// lib/features/cv_job_matcher/data/cv_matcher_repository.dart
// REFACTORED — auto-match on submit, no manual paste flow

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/features/cv_job_matcher/models/cv_match_result.dart';
import 'package:refsure/features/cv_job_matcher/models/job_application.dart';
import 'package:refsure/features/cv_job_matcher/models/job_opening.dart';
import 'package:refsure/features/cv_job_matcher/services/cv_matching_engine.dart';
import 'package:refsure/features/cv_job_matcher/services/job_fetch_service.dart';

class CvMatcherRepository {
  CvMatcherRepository({FirebaseFirestore? db, JobFetchService? jobFetchService})
      : _db = db ?? FirebaseFirestore.instance,
        _jobFetchService = jobFetchService ?? JobFetchService();

  final FirebaseFirestore _db;
  final JobFetchService _jobFetchService;

  CollectionReference get _applications => _db.collection('referral_applications');

  // ── REQUESTER: Submit application (auto-match runs here) ──

  Future<JobApplication> submitApplication({
    required Job job,
    required String requesterId,
    required String requesterName,
    required String requesterEmail,
    required String resumeText,
    String? resumeFileUrl,
  }) async {
    // 1 — Auto-match: no manual trigger needed
    final matchResult = await _runMatch(job: job, cvText: resumeText);

    // 2 — Build application
    final ref = _applications.doc();
    final app = JobApplication(
      id: ref.id,
      postedJobId: job.id,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterEmail: requesterEmail,
      providerId: job.providerId,
      resumeText: resumeText,
      resumeFileUrl: resumeFileUrl,
      appliedAt: DateTime.now(),
      status: ApplicationStatus.applied,
      matchResult: matchResult,
    );

    // 3 — Save
    await ref.set(app.toFirestore());
    await _db.collection('jobs').doc(job.id).update({
      'applicants': FieldValue.increment(1),
    });

    return app;
  }

  // ── PROVIDER: Watch applicants ranked by score ─────────────

  Stream<List<JobApplication>> watchJobApplications(String postedJobId) =>
      _applications.where('postedJobId', isEqualTo: postedJobId).snapshots().map(
        (snap) => snap.docs.map(JobApplication.fromFirestore).toList()
          ..sort((a, b) => b.matchScore.compareTo(a.matchScore)));

  Future<List<JobApplication>> fetchProviderApplications(String providerId) async {
    final snap = await _applications
        .where('providerId', isEqualTo: providerId)
        .orderBy('appliedAt', descending: true)
        .get();
    return snap.docs.map(JobApplication.fromFirestore).toList();
  }

  // ── PROVIDER: Shortlist / Refer / Reject ──────────────────

  Future<void> updateDecision({
    required String applicationId,
    required ApplicationStatus status,
    String? providerNote,
  }) async {
    await _applications.doc(applicationId).update({
      'status': status.name,
      'decidedAt': FieldValue.serverTimestamp(),
      if (providerNote != null) 'providerNote': providerNote,
    });
  }

  // ── PROVIDER: Company job fetch ────────────────────────────

  Future<List<JobOpening>> fetchCompanyJobs({
    required String companyName,
    required String country,
    int lastDays = 30,
    List<String> alreadyPostedIds = const [],
  }) async {
    final jobs = await _jobFetchService.fetchCompanyJobs(
      companyName: companyName,
      country: country,
      lastDays: lastDays,
    );
    return jobs.map((j) =>
      j.copyWith(isAlreadyPosted: alreadyPostedIds.contains(j.id))).toList();
  }

  // ── Internal: auto-run matching engine ────────────────────

  Future<CvMatchResult> _runMatch({required Job job, required String cvText}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return CvMatchingEngine.compute(
      cvText: cvText,
      jdText: '${job.description}\n${job.skills.join(" ")}',
      jdTitle: job.title,
      jdSkills: job.skills,
      jdMinExp: job.minExp,
      jdMaxExp: job.maxExp,
    );
  }
}

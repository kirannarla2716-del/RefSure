// lib/features/careers_portal/data/careers_portal_repository.dart
// ignore_for_file: require_trailing_commas

import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/external_job.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/features/jobs/data/jobs_repository.dart';
import 'package:refsure/services/careers_portal_service.dart';
import 'package:uuid/uuid.dart';
import 'package:refsure/core/constants/app_constants.dart';

class CareersPortalRepository {
  CareersPortalRepository(this._service, this._jobsRepository);

  final CareersPortalService _service;
  final JobsRepository _jobsRepository;

  /// Fetches open jobs for [companyName] from the best-matching ATS.
  Future<CareersPortalResult> fetchJobs(
    String companyName, {
    bool filterLast30Days = false,
  }) =>
      _service.fetchJobs(companyName, filterLast30Days: filterLast30Days);

  /// Imports an [ExternalJob] into RefSure as a proper [Job] posting.
  ///
  /// [providerId] is the uid of the referrer/provider performing the import.
  Future<String?> importJob(ExternalJob ext, String providerId) {
    final cleanedDescription =
        _stripHtml(_decodeHtmlEntities(ext.description ?? ''));
    final extractedSkills = _extractSkills(cleanedDescription);
    final deadline = DateTime.now().add(const Duration(days: 30));
    final deadlineStr = [
      deadline.year.toString(),
      deadline.month.toString().padLeft(2, '0'),
      deadline.day.toString().padLeft(2, '0'),
    ].join('-');

    final stableImportId = const Uuid()
        .v5(Namespace.url.value, '$providerId|${ext.company}|${ext.id}')
        .replaceAll('-', '');
    final job = Job(
      id: 'career_$stableImportId',
      providerId: providerId,
      company: ext.company,
      companyLogo: ext.company.isNotEmpty ? ext.company[0].toUpperCase() : '?',
      title: ext.title,
      department: ext.department ?? 'General',
      location: ext.location ?? 'Not specified',
      workMode: ext.workMode ?? 'Hybrid',
      minExp: 0,
      maxExp: 10,
      skills: extractedSkills,
      description: cleanedDescription,
      deadline: deadlineStr,
      postedAt: ext.postedAt,
      jobRefId: ext.id,
      source: JobSource.careersPortal,
      externalUrl: ext.applyUrl,
    );
    return _jobsRepository.postJob(job);
  }

  /// Extracts known skill keywords from free-text job description.
  static List<String> _extractSkills(String text) {
    final lower = text.toLowerCase();
    return AppConstants.skillOptions
        .where((skill) => lower.contains(skill.toLowerCase()))
        .toList();
  }

  /// Very lightweight HTML-to-text strip for job descriptions fetched
  /// from Greenhouse (which returns raw HTML).
  static String _stripHtml(String html) => html
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  static String _decodeHtmlEntities(String value) => value
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&');
}

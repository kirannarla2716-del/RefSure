// lib/features/careers_portal/presentation/cubit/careers_portal_state.dart

import 'package:equatable/equatable.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/external_job.dart';
import 'package:refsure/services/careers_portal_service.dart';

sealed class CareersPortalState extends Equatable {
  const CareersPortalState();

  @override
  List<Object?> get props => [];
}

class CareersPortalInitial extends CareersPortalState {
  const CareersPortalInitial();
}

class CareersPortalLoading extends CareersPortalState {
  const CareersPortalLoading(this.companyName);
  final String companyName;

  @override
  List<Object?> get props => [companyName];
}

class CareersPortalLoaded extends CareersPortalState {
  const CareersPortalLoaded({
    required this.jobs,
    required this.platform,
    required this.companyName,
    required this.companySlug,
    required this.totalFetched,
    this.filterLast30Days = true,
    this.query = '',
    this.location,
    this.department,
    this.workMode,
  });

  final List<ExternalJob> jobs;
  final AtsPlatform platform;
  final String companyName;
  final String companySlug;

  /// Raw count before date filtering.
  final int totalFetched;

  /// Whether the 30-day filter is currently active.
  final bool filterLast30Days;

  // ── Client-side filters applied on top of the fetched [jobs] ──
  /// Free-text search across title, department and location.
  final String query;

  /// Exact-match location filter (null = any).
  final String? location;

  /// Exact-match department filter (null = any).
  final String? department;

  /// Exact-match work-mode filter (null = any).
  final String? workMode;

  /// Distinct, sorted filter options derived from the fetched jobs.
  List<String> get locations => _distinct((j) => j.location);
  List<String> get departments => _distinct((j) => j.department);
  List<String> get workModes => _distinct((j) => j.workMode);

  List<String> _distinct(String? Function(ExternalJob) sel) {
    final set = <String>{};
    for (final j in jobs) {
      final v = sel(j)?.trim();
      if (v != null && v.isNotEmpty) set.add(v);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// True when any client-side filter (search/location/department/workMode)
  /// is currently narrowing the list.
  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      location != null ||
      department != null ||
      workMode != null;

  /// The jobs after applying the active client-side filters.
  List<ExternalJob> get filteredJobs {
    final q = query.trim().toLowerCase();
    return jobs.where((j) {
      if (location != null && j.location != location) return false;
      if (department != null && j.department != department) return false;
      if (workMode != null && j.workMode != workMode) return false;
      if (q.isNotEmpty) {
        final hay = [
          j.title,
          j.department ?? '',
          j.location ?? '',
          j.workMode ?? '',
        ].join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  CareersPortalLoaded copyWith({
    bool? filterLast30Days,
    String? query,
    Object? location = _sentinel,
    Object? department = _sentinel,
    Object? workMode = _sentinel,
  }) =>
      CareersPortalLoaded(
        jobs: jobs,
        platform: platform,
        companyName: companyName,
        companySlug: companySlug,
        totalFetched: totalFetched,
        filterLast30Days: filterLast30Days ?? this.filterLast30Days,
        query: query ?? this.query,
        location: location == _sentinel ? this.location : location as String?,
        department:
            department == _sentinel ? this.department : department as String?,
        workMode: workMode == _sentinel ? this.workMode : workMode as String?,
      );

  @override
  List<Object?> get props => [
        jobs,
        platform,
        companyName,
        companySlug,
        totalFetched,
        filterLast30Days,
        query,
        location,
        department,
        workMode,
      ];
}

/// Sentinel so [CareersPortalLoaded.copyWith] can distinguish "leave
/// unchanged" from "set to null" for nullable filter fields.
const Object _sentinel = Object();

class CareersPortalError extends CareersPortalState {
  const CareersPortalError(
    this.message, {
    this.companyName,
    this.filterLast30Days = true,
    this.diagnostics = const [],
    this.officialCareersUrl,
  });

  final String message;
  final String? companyName;
  final bool filterLast30Days;
  final List<CareersSourceDiagnostic> diagnostics;
  final Uri? officialCareersUrl;

  @override
  List<Object?> get props => [
        message,
        companyName,
        filterLast30Days,
        diagnostics,
        officialCareersUrl,
      ];
}

/// Emitted while a single job is being imported into RefSure.
class CareersPortalImporting extends CareersPortalState {
  const CareersPortalImporting(this.jobId);
  final String jobId;

  @override
  List<Object?> get props => [jobId];
}

/// Emitted after a successful import.
class CareersPortalImported extends CareersPortalState {
  const CareersPortalImported({
    required this.jobTitle,
    required this.refSureJobId,
    required this.externalJobId,
  });

  final String jobTitle;
  final String refSureJobId;

  /// The original [ExternalJob.id] — used to mark the card as imported.
  final String externalJobId;

  @override
  List<Object?> get props => [jobTitle, refSureJobId, externalJobId];
}

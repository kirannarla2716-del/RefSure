// lib/features/careers_portal/presentation/cubit/careers_portal_cubit.dart
// ignore_for_file: require_trailing_commas

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/core/models/external_job.dart';
import 'package:refsure/features/careers_portal/data/careers_portal_repository.dart';
import 'package:refsure/features/careers_portal/presentation/cubit/careers_portal_state.dart';
import 'package:refsure/services/careers_portal_service.dart';

class CareersPortalCubit extends Cubit<CareersPortalState> {
  CareersPortalCubit({required CareersPortalRepository repository})
      : _repository = repository,
        super(const CareersPortalInitial());

  final CareersPortalRepository _repository;

  /// Cached copy of the last successful load — restored after imports and
  /// used by [refresh] to re-fetch without re-supplying the company name.
  CareersPortalLoaded? _lastLoaded;
  String? _requestedCompany;
  bool _requestedFilterLast30Days = true;
  int _fetchGeneration = 0;

  // ── Fetch ─────────────────────────────────────────────────────

  /// Fetches open jobs for [companyName] from the best-matching ATS.
  ///
  /// When [filterLast30Days] is true (default) only jobs from the last
  /// 30 days are returned. The raw count before filtering is available on
  /// the resulting [CareersPortalLoaded.totalFetched].
  Future<void> fetchJobs(
    String companyName, {
    bool filterLast30Days = true,
  }) async {
    final name = companyName.trim();
    if (name.isEmpty) {
      reset();
      return;
    }

    final generation = ++_fetchGeneration;
    _requestedCompany = name;
    _requestedFilterLast30Days = filterLast30Days;
    emit(CareersPortalLoading(name));
    try {
      final result = await _repository.fetchJobs(
        name,
        filterLast30Days: filterLast30Days,
      );
      if (isClosed || generation != _fetchGeneration) return;
      final loaded = CareersPortalLoaded(
        jobs: result.jobs,
        platform: result.platform,
        companyName: name,
        companySlug: result.companySlug,
        totalFetched: result.totalFetched,
        filterLast30Days: filterLast30Days,
      );
      _lastLoaded = loaded;
      emit(loaded);
    } on CareersPortalException catch (e) {
      if (!isClosed && generation == _fetchGeneration) {
        emit(CareersPortalError(
          e.message,
          companyName: name,
          filterLast30Days: filterLast30Days,
          diagnostics: e.diagnostics,
          officialCareersUrl: e.officialCareersUrl,
        ));
      }
    } catch (e) {
      if (!isClosed && generation == _fetchGeneration) {
        emit(CareersPortalError(
          'Could not load jobs for "$name". Please try again.',
          companyName: name,
          filterLast30Days: filterLast30Days,
        ));
      }
    }
  }

  /// Re-fetches using the company name from the last successful load.
  /// No-ops if there has been no successful load yet.
  Future<void> refresh() async {
    final company = _requestedCompany;
    if (company == null) return;
    await fetchJobs(
      company,
      filterLast30Days: _requestedFilterLast30Days,
    );
  }

  // ── Date filter ───────────────────────────────────────────────

  /// Toggles the 30-day date filter and re-fetches immediately.
  void toggleDateFilter() {
    final current = state;
    if (current is! CareersPortalLoaded) return;
    fetchJobs(
      current.companyName,
      filterLast30Days: !current.filterLast30Days,
    );
  }

  // ── Client-side filters (no re-fetch) ─────────────────────────

  void setQuery(String value) {
    final c = state;
    if (c is! CareersPortalLoaded) return;
    _emitFiltered(c.copyWith(query: value));
  }

  void setLocation(String? value) {
    final c = state;
    if (c is! CareersPortalLoaded) return;
    _emitFiltered(c.copyWith(location: value));
  }

  void setDepartment(String? value) {
    final c = state;
    if (c is! CareersPortalLoaded) return;
    _emitFiltered(c.copyWith(department: value));
  }

  void setWorkMode(String? value) {
    final c = state;
    if (c is! CareersPortalLoaded) return;
    _emitFiltered(c.copyWith(workMode: value));
  }

  void clearFilters() {
    final c = state;
    if (c is! CareersPortalLoaded) return;
    _emitFiltered(
      c.copyWith(
        query: '',
        location: null,
        department: null,
        workMode: null,
      ),
    );
  }

  void _emitFiltered(CareersPortalLoaded loaded) {
    _lastLoaded = loaded;
    emit(loaded);
  }

  // ── Import ────────────────────────────────────────────────────

  /// Imports an [ExternalJob] into RefSure as a job posting.
  Future<void> importJob(ExternalJob job, String providerId) async {
    emit(CareersPortalImporting(job.id));
    try {
      final refSureId = await _repository.importJob(job, providerId);
      if (refSureId != null) {
        emit(CareersPortalImported(
          jobTitle: job.title,
          refSureJobId: refSureId,
          externalJobId: job.id,
        ));
        // Restore the loaded state after a brief delay so the screen can
        // show the success snackbar before the job list reappears.
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!isClosed && _lastLoaded != null) {
          emit(_lastLoaded!);
        }
      } else {
        emit(const CareersPortalError('Failed to post job. Please try again.'));
        // Restore the job list after the error snackbar fires.
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!isClosed && _lastLoaded != null) {
          emit(_lastLoaded!);
        }
      }
    } catch (e) {
      emit(CareersPortalError('Import failed: $e'));
      // Restore the job list after the error snackbar fires.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!isClosed && _lastLoaded != null) {
        emit(_lastLoaded!);
      }
    }
  }

  /// Resets to initial state (clears results).
  void reset() {
    _fetchGeneration++;
    _lastLoaded = null;
    _requestedCompany = null;
    _requestedFilterLast30Days = true;
    emit(const CareersPortalInitial());
  }
}

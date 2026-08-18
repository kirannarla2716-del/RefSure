import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/core/models/app_user.dart';
import 'package:refsure/core/models/application.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/features/dashboard/data/dashboard_repository.dart';
import 'package:refsure/features/dashboard/presentation/cubit/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required DashboardRepository dashboardRepository})
      : _repository = dashboardRepository,
        super(const DashboardInitial());

  final DashboardRepository _repository;
  final List<StreamSubscription<dynamic>> _subs = [];

  List<AppUser> _seekers = [];
  List<Job> _jobs = [];
  List<Application> _applications = [];

  void loadDashboard(String uid) {
    emit(const DashboardLoading());

    _subs
      ..forEach((s) => s.cancel())
      ..clear();

    _subs.add(_repository.watchSeekers().listen((list) {
      _seekers = list;
      _emitLoaded();
    }));

    _subs.add(_repository.watchActiveJobs().listen((list) {
      _jobs = list;
      _emitLoaded();
    }));

    _subs.add(_repository.watchProviderApplications(uid).listen((list) {
      _applications = list;
      _emitLoaded();
    }));
  }

  void _emitLoaded() {
    emit(DashboardLoaded(
      seekers: _seekers,
      jobs: _jobs,
      applications: _applications,
    ));
  }

  @override
  Future<void> close() {
    for (final s in _subs) {
      s.cancel();
    }
    return super.close();
  }
}

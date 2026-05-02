import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/core/models/application.dart';
import 'package:refsure/features/applications/data/applications_repository.dart';
import 'package:refsure/features/applications/presentation/cubit/applications_state.dart';

class ApplicationsCubit extends Cubit<ApplicationsState> {
  ApplicationsCubit({required ApplicationsRepository applicationsRepository})
      : _repository = applicationsRepository,
        super(const ApplicationsInitial());

  final ApplicationsRepository _repository;
  StreamSubscription<List<Application>>? _appsSub;

  void loadSeekerApplications(String uid) {
    emit(const ApplicationsLoading());
    _appsSub?.cancel();
    _appsSub = _repository.watchSeekerApplications(uid).listen(
      (apps) {
        emit(ApplicationsLoaded(applications: apps));
      },
      onError: (Object error) {
        emit(ApplicationsError(error.toString()));
      },
    );
  }

  void loadProviderApplications(String uid) {
    emit(const ApplicationsLoading());
    _appsSub?.cancel();
    _appsSub = _repository.watchProviderApplications(uid).listen(
      (apps) {
        emit(ApplicationsLoaded(applications: apps));
      },
      onError: (Object error) {
        emit(ApplicationsError(error.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _appsSub?.cancel();
    return super.close();
  }
}

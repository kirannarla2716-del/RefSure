// ignore_for_file: require_trailing_commas

import 'package:refsure/core/models/app_user.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/core/models/application.dart';
import 'package:refsure/services/firestore_service.dart';

class DashboardRepository {
  DashboardRepository(this._db);
  final FirestoreService _db;

  Stream<List<AppUser>> watchSeekers() => _db.watchSeekers();

  Stream<List<Job>> watchActiveJobs() => _db.watchActiveJobs();

  Stream<List<Application>> watchProviderApplications(String uid) =>
      _db.watchProviderApplications(uid);
}

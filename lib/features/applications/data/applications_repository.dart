// ignore_for_file: require_trailing_commas

import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/application.dart';
import 'package:refsure/core/models/notification.dart';
import 'package:refsure/core/models/match_report.dart';
import 'package:refsure/core/models/job.dart';
import 'package:refsure/core/models/app_user.dart';
import 'package:refsure/services/firestore_service.dart';
import 'package:refsure/services/match_engine.dart';

class ApplicationsRepository {
  ApplicationsRepository(this._db);
  final FirestoreService _db;

  Stream<List<Application>> watchSeekerApplications(String uid) =>
      _db.watchSeekerApplications(uid);

  Stream<List<Application>> watchProviderApplications(String uid) =>
      _db.watchProviderApplications(uid);

  Future<bool> hasApplied(String jobId, String seekerId) =>
      _db.hasApplied(jobId, seekerId);

  Future<void> submitApplication(Application app) =>
      _db.submitApplication(app);

  Future<void> updateApplicationStatus(
    String appId,
    AppStatus status, {
    String? note,
  }) =>
      _db.updateApplicationStatus(appId, status, note: note);

  Future<void> createNotification(AppNotification notification) =>
      _db.createNotification(notification);

  MatchReport computeMatch({required AppUser seeker, required Job job}) =>
      MatchEngine.compute(seeker: seeker, job: job);
}

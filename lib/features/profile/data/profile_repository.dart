// ignore_for_file: require_trailing_commas

import 'package:refsure/services/firestore_service.dart';
import 'package:refsure/services/storage_service.dart';
import 'package:refsure/core/models/app_user.dart';

class ProfileRepository {
  ProfileRepository(this._db, this._storage);
  final FirestoreService _db;
  final StorageService _storage;

  Stream<AppUser?> watchUser(String uid) => _db.watchUser(uid);

  Future<AppUser?> getUser(String uid) => _db.getUser(uid);

  Future<void> updateProfile(String uid, Map<String, dynamic> data) =>
      _db.updateUser(uid, data);

  Future<String?> uploadResume(String uid) async {
    final url = await _storage.uploadResumeFile(uid);
    if (url != null) await _db.updateUser(uid, {'resumeUrl': url});
    return url;
  }
}

// lib/services/storage_service.dart — v2.0
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ── Profile photo ─────────────────────────────────────────

  Future<String?> uploadProfilePhoto(String uid) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (picked == null) return null;

      final ref = _storage.ref('profile_photos/$uid.jpg');
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(picked.path), SettableMetadata(contentType: 'image/jpeg'));
      }
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── Resume / CV upload ────────────────────────────────────

  Future<String?> uploadResumeFile(String uid) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: kIsWeb);

      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;

      final ext = file.extension ?? 'pdf';
      final ref = _storage.ref('resumes/$uid/resume.$ext');
      final meta = SettableMetadata(contentType:
        ext == 'pdf' ? 'application/pdf' : 'application/msword');

      if (kIsWeb && file.bytes != null) {
        await ref.putData(file.bytes!, meta);
      } else if (file.path != null) {
        await ref.putFile(File(file.path!), meta);
      }

      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── Company logo placeholder ──────────────────────────────

  Future<void> deleteProfilePhoto(String uid) async {
    try { await _storage.ref('profile_photos/$uid.jpg').delete(); }
    catch (_) {}
  }
}

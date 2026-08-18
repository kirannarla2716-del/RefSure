// lib/services/storage_service.dart — v2.1
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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
      // Use readAsBytes() on all platforms — avoids dart:io File on web.
      final bytes = await picked.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('uploadProfilePhoto error: $e');
      return null;
    }
  }

  // ── Resume / CV upload ────────────────────────────────────

  /// Picks a CV/resume and uploads it to Storage.
  /// Returns the download URL on success.
  /// Returns null only when the user cancels the picker.
  /// Throws [ResumeUploadException] with a readable message on real failures
  /// so the UI can show the actual cause instead of a generic error.
  Future<String?> uploadResumeFile(String uid) async {
    // ── Pick file (a thrown error here is unexpected; surface it) ──
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true, // request bytes on ALL platforms — no dart:io File needed
      );
    } catch (e) {
      debugPrint('uploadResumeFile pick error: $e');
      throw ResumeUploadException('Could not open the file picker. $e');
    }

    // User cancelled — not an error.
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const ResumeUploadException(
          'That file appears to be empty or could not be read. Try another file.');
    }

    final ext = (file.extension ?? 'pdf').toLowerCase();
    final contentType = ext == 'pdf'
        ? 'application/pdf'
        : (ext == 'docx'
            ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
            : 'application/msword');

    try {
      final ref = _storage.ref('resumes/$uid/resume.$ext');
      await ref.putData(bytes, SettableMetadata(contentType: contentType));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('uploadResumeFile storage error: ${e.code} ${e.message}');
      final msg = switch (e.code) {
        'unauthorized' =>
          'Upload was blocked by Storage security rules. Deploy storage.rules and try again.',
        'unauthenticated' => 'You are not signed in. Please sign in and retry.',
        'retry-limit-exceeded' =>
          'Upload timed out. Check your connection and try again.',
        _ => 'Upload failed (${e.code}). ${e.message ?? ''}',
      };
      throw ResumeUploadException(msg);
    } catch (e) {
      debugPrint('uploadResumeFile error: $e');
      throw ResumeUploadException('Upload failed. $e');
    }
  }

  // ── Profile photo delete ──────────────────────────────────

  Future<void> deleteProfilePhoto(String uid) async {
    try {
      await _storage.ref('profile_photos/$uid.jpg').delete();
    } catch (e) {
      debugPrint('deleteProfilePhoto error: $e');
    }
  }
}

/// Raised when a resume upload fails for a real reason (not user cancel).
/// Carries a user-readable [message].
class ResumeUploadException implements Exception {
  final String message;
  const ResumeUploadException(this.message);
  @override
  String toString() => message;
}

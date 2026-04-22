// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Current Firebase user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;

  // ── Email / Password ───────────────────────────────────────

  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
      await credential.user!.updateDisplayName(name);

      // Create user document in Firestore
      final user = AppUser(
        id: credential.user!.uid,
        role: role,
        name: name,
        headline: role == UserRole.provider
            ? 'Referral Provider' : 'Job Seeker',
        title: '',
        location: '',
        experience: 0,
        skills: [],
        bio: '',
        email: email,
        profileComplete: 30,
      );
      await _db.collection('users')
          .doc(credential.user!.uid)
          .set(user.toFirestore());

      return AuthResult(success: true, uid: credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    }
  }

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
      return AuthResult(success: true, uid: credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────

  Future<AuthResult> signInWithGoogle({UserRole role = UserRole.seeker}) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return AuthResult(success: false, error: 'Cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      // Create profile if new user
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        final user = AppUser(
          id: uid,
          role: role,
          name: googleUser.displayName ?? 'User',
          headline: role == UserRole.provider ? 'Referral Provider' : 'Job Seeker',
          title: '',
          location: '',
          experience: 0,
          skills: [],
          bio: '',
          email: googleUser.email,
          photoUrl: googleUser.photoUrl,
          profileComplete: 40,
        );
        await _db.collection('users').doc(uid).set(user.toFirestore());
      }

      return AuthResult(success: true, uid: uid);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  // ── Password reset ─────────────────────────────────────────

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    }
  }

  // ── Sign out ───────────────────────────────────────────────

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // ── Error messages ─────────────────────────────────────────

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':   return 'An account with this email already exists.';
      case 'invalid-email':          return 'Please enter a valid email address.';
      case 'weak-password':          return 'Password must be at least 6 characters.';
      case 'user-not-found':         return 'No account found with this email.';
      case 'wrong-password':         return 'Incorrect password. Please try again.';
      case 'too-many-requests':      return 'Too many attempts. Please try again later.';
      case 'network-request-failed': return 'No internet connection. Please try again.';
      default:                       return 'Something went wrong. Please try again.';
    }
  }
}

class AuthResult {
  final bool success;
  final String? uid;
  final String? error;
  const AuthResult({required this.success, this.uid, this.error});
}

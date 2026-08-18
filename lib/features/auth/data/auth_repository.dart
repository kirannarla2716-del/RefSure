// ignore_for_file: require_trailing_commas

import 'package:dartz/dartz.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/error/failures.dart';
import 'package:refsure/services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._authService);
  final AuthService _authService;

  Stream<String?> get authUidStream =>
      _authService.authStateChanges.map((user) => user?.uid);

  String? get currentUid => _authService.currentUid;

  Future<Either<Failure, String>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    if (result.success) {
      return Right(result.uid!);
    }
    return Left(AuthFailure(result.error ?? 'Sign in failed'));
  }

  Future<Either<Failure, String>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final result = await _authService.signUpWithEmail(
      email: email,
      password: password,
      name: name,
      role: role,
    );
    if (result.success) {
      return Right(result.uid!);
    }
    return Left(AuthFailure(result.error ?? 'Sign up failed'));
  }

  Future<Either<Failure, String>> signInWithGoogle({
    UserRole role = UserRole.seeker,
  }) async {
    final result = await _authService.signInWithGoogle(role: role);
    if (result.success) {
      return Right(result.uid!);
    }
    return Left(AuthFailure(result.error ?? 'Google sign in failed'));
  }

  Future<Either<Failure, void>> sendPasswordReset(String email) async {
    final result = await _authService.sendPasswordReset(email);
    if (result.success) {
      return const Right(null);
    }
    return Left(AuthFailure(result.error ?? 'Password reset failed'));
  }

  Future<void> signOut() => _authService.signOut();
}

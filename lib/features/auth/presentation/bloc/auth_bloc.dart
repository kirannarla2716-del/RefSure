import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refsure/features/auth/data/auth_repository.dart';
import 'package:refsure/features/auth/presentation/bloc/auth_event.dart';
import 'package:refsure/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<EmailSignInRequested>(_onEmailSignIn);
    on<EmailSignUpRequested>(_onEmailSignUp);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<PasswordResetRequested>(_onPasswordReset);
    on<SignOutRequested>(_onSignOut);
    on<AuthErrorDismissed>(_onErrorDismissed);
  }

  final AuthRepository _authRepository;

  Future<void> _onEmailSignIn(
    EmailSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.signInWithEmail(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (uid) => emit(AuthSuccess(uid)),
    );
  }

  Future<void> _onEmailSignUp(
    EmailSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.signUpWithEmail(
      email: event.email,
      password: event.password,
      name: event.name,
      role: event.role,
    );
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (uid) => emit(AuthSuccess(uid)),
    );
  }

  Future<void> _onGoogleSignIn(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.signInWithGoogle(role: event.role);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (uid) => emit(AuthSuccess(uid)),
    );
  }

  Future<void> _onPasswordReset(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.sendPasswordReset(event.email);
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(const AuthPasswordResetSent()),
    );
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(const AuthUnauthenticated());
  }

  void _onErrorDismissed(
    AuthErrorDismissed event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthInitial());
  }
}

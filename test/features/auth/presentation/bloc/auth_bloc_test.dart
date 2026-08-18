import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/error/failures.dart' as failures;
import 'package:refsure/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:refsure/features/auth/presentation/bloc/auth_event.dart';
import 'package:refsure/features/auth/presentation/bloc/auth_state.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepository;

  setUpAll(() {
    registerFallbackValue(UserRole.seeker);
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  group('Feature: User Authentication', () {
    // ── Scenario: Email Sign In ────────────────────────────────
    group('Scenario: User signs in with email and password', () {
      blocTest<AuthBloc, AuthState>(
        'Given valid credentials, '
        'When EmailSignInRequested is added, '
        'Then it should emit [AuthLoading, AuthSuccess]',
        build: () {
          when(
            () => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer((_) async => const Right('test-uid-123'));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(
          const EmailSignInRequested(
            email: 'test@example.com',
            password: 'password123',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthSuccess('test-uid-123'),
        ],
        verify: (_) {
          verify(
            () => mockAuthRepository.signInWithEmail(
              email: 'test@example.com',
              password: 'password123',
            ),
          ).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'Given invalid credentials, '
        'When EmailSignInRequested is added, '
        'Then it should emit [AuthLoading, AuthFailure]',
        build: () {
          when(
            () => mockAuthRepository.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer(
            (_) async =>
                const Left(failures.AuthFailure('No account found with this email.')),
          );
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(
          const EmailSignInRequested(
            email: 'wrong@example.com',
            password: 'wrong',
          ),
        ),
        expect: () => [
          const AuthLoading(),
          isA<AuthFailure>().having(
            (s) => s.message,
            'message',
            'No account found with this email.',
          ),
        ],
      );
    });

    // ── Scenario: Email Sign Up ────────────────────────────────
    group('Scenario: User creates a new account', () {
      blocTest<AuthBloc, AuthState>(
        'Given valid registration details, '
        'When EmailSignUpRequested is added, '
        'Then it should emit [AuthLoading, AuthSuccess]',
        build: () {
          when(
            () => mockAuthRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              name: any(named: 'name'),
              role: any(named: 'role'),
            ),
          ).thenAnswer((_) async => const Right('new-uid-456'));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(
          const EmailSignUpRequested(
            name: 'Test User',
            email: 'test@example.com',
            password: 'password123',
            role: UserRole.seeker,
          ),
        ),
        expect: () => [
          const AuthLoading(),
          const AuthSuccess('new-uid-456'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'Given an email that is already in use, '
        'When EmailSignUpRequested is added, '
        'Then it should emit [AuthLoading, AuthFailure]',
        build: () {
          when(
            () => mockAuthRepository.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              name: any(named: 'name'),
              role: any(named: 'role'),
            ),
          ).thenAnswer(
            (_) async => const Left(
              failures.AuthFailure('An account with this email already exists.'),
            ),
          );
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(
          const EmailSignUpRequested(
            name: 'Test User',
            email: 'existing@example.com',
            password: 'password123',
            role: UserRole.seeker,
          ),
        ),
        expect: () => [
          const AuthLoading(),
          isA<AuthFailure>().having(
            (s) => s.message,
            'message',
            'An account with this email already exists.',
          ),
        ],
      );
    });

    // ── Scenario: Google Sign In ───────────────────────────────
    group('Scenario: User signs in with Google', () {
      blocTest<AuthBloc, AuthState>(
        'Given Google auth succeeds, '
        'When GoogleSignInRequested is added, '
        'Then it should emit [AuthLoading, AuthSuccess]',
        build: () {
          when(
            () => mockAuthRepository.signInWithGoogle(
              role: any(named: 'role'),
            ),
          ).thenAnswer((_) async => const Right('google-uid-789'));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) =>
            bloc.add(const GoogleSignInRequested(role: UserRole.seeker)),
        expect: () => [
          const AuthLoading(),
          const AuthSuccess('google-uid-789'),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'Given Google auth is cancelled, '
        'When GoogleSignInRequested is added, '
        'Then it should emit [AuthLoading, AuthFailure]',
        build: () {
          when(
            () => mockAuthRepository.signInWithGoogle(
              role: any(named: 'role'),
            ),
          ).thenAnswer(
            (_) async => const Left(failures.AuthFailure('Cancelled')),
          );
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const GoogleSignInRequested()),
        expect: () => [
          const AuthLoading(),
          isA<AuthFailure>(),
        ],
      );
    });

    // ── Scenario: Password Reset ───────────────────────────────
    group('Scenario: User requests a password reset', () {
      blocTest<AuthBloc, AuthState>(
        'Given a valid email, '
        'When PasswordResetRequested is added, '
        'Then it should emit [AuthLoading, AuthPasswordResetSent]',
        build: () {
          when(
            () => mockAuthRepository.sendPasswordReset(any()),
          ).thenAnswer((_) async => const Right(null));
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) =>
            bloc.add(const PasswordResetRequested('test@example.com')),
        expect: () => [
          const AuthLoading(),
          const AuthPasswordResetSent(),
        ],
      );
    });

    // ── Scenario: Sign Out ─────────────────────────────────────
    group('Scenario: User signs out', () {
      blocTest<AuthBloc, AuthState>(
        'Given user is authenticated, '
        'When SignOutRequested is added, '
        'Then it should emit [AuthUnauthenticated]',
        build: () {
          when(() => mockAuthRepository.signOut())
              .thenAnswer((_) async {});
          return AuthBloc(authRepository: mockAuthRepository);
        },
        act: (bloc) => bloc.add(const SignOutRequested()),
        expect: () => [const AuthUnauthenticated()],
        verify: (_) {
          verify(() => mockAuthRepository.signOut()).called(1);
        },
      );
    });

    // ── Scenario: Error Dismissed ──────────────────────────────
    group('Scenario: User dismisses an error', () {
      blocTest<AuthBloc, AuthState>(
        'Given an error state, '
        'When AuthErrorDismissed is added, '
        'Then it should emit [AuthInitial]',
        build: () => AuthBloc(authRepository: mockAuthRepository),
        seed: () => const AuthFailure('Some error'),
        act: (bloc) => bloc.add(const AuthErrorDismissed()),
        expect: () => [const AuthInitial()],
      );
    });
  });
}

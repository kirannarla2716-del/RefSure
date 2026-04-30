# RefSure Architecture Plan

## Overview

Feature-first modular architecture with Clean Architecture layers, BLoC state management,
atomic design system, localization, and BDD test coverage.

## Directory Structure

```
lib/
├── core/
│   ├── constants/       # App-wide constants (api_constants.dart)
│   ├── di/              # Dependency injection (injection.dart)
│   ├── enums/           # Shared enums (enums.dart)
│   ├── error/           # Typed failures + exceptions (failures.dart, exceptions.dart)
│   ├── models/          # Domain models (app_user.dart, job.dart, notification.dart, etc.)
│   └── router/          # Route names (route_names.dart)
├── design_system/
│   ├── theme/           # AppColors, AppTypography, AppTheme (buildAppTheme)
│   ├── atoms/           # Smallest UI primitives (10 widgets)
│   ├── molecules/       # Composed UI components (7 widgets)
│   ├── organisms/       # Complex UI sections (5 widgets)
│   └── design_system.dart  # Barrel export
├── features/
│   ├── auth/
│   │   ├── data/        # AuthRepository (wraps AuthService with Either<Failure,T>)
│   │   ├── presentation/
│   │   │   ├── bloc/    # AuthBloc, AuthEvent (sealed), AuthState (sealed)
│   │   │   ├── screens/ # AuthScreen (BLoC-driven)
│   │   │   └── widgets/ # ErrorBanner, OrDivider, GoogleSignInButton, RoleChip
│   │   └── auth.dart    # Barrel
│   ├── profile/
│   │   ├── data/        # ProfileRepository
│   │   ├── presentation/
│   │   │   └── cubit/   # ProfileCubit, ProfileState (sealed)
│   │   └── profile.dart
│   ├── jobs/
│   │   ├── data/        # JobsRepository
│   │   ├── presentation/
│   │   │   └── cubit/   # JobsCubit, JobsState (sealed)
│   │   └── jobs.dart
│   ├── applications/
│   │   ├── data/        # ApplicationsRepository
│   │   ├── presentation/
│   │   │   └── cubit/   # ApplicationsCubit, ApplicationsState (sealed)
│   │   └── applications.dart
│   ├── notifications/
│   │   ├── data/        # NotificationsRepository
│   │   ├── presentation/
│   │   │   └── cubit/   # NotificationsCubit, NotificationsState (sealed)
│   │   └── notifications.dart
│   ├── messaging/
│   │   ├── data/        # MessagingRepository
│   │   ├── presentation/
│   │   │   └── cubit/   # MessagingCubit, MessagingState (sealed)
│   │   └── messaging.dart
│   ├── dashboard/
│   │   ├── data/        # DashboardRepository
│   │   ├── presentation/
│   │   │   └── cubit/   # DashboardCubit, DashboardState (sealed)
│   │   └── dashboard.dart
│   └── onboarding/
│       ├── presentation/
│       │   └── cubit/   # OnboardingCubit, OnboardingState (sealed)
│       └── onboarding.dart
├── l10n/
│   ├── app_en.arb       # English translations (~100 keys)
│   └── generated/       # Auto-generated localization code
├── services/            # Firebase services (auth, firestore, storage, otp, match_engine)
├── providers/           # Legacy AppProvider (coexists during migration)
├── screens/             # Legacy monolithic screens (Strangler Fig pattern)
├── widgets/             # Barrel re-exports to new design_system
├── utils/               # Barrel re-exports to new design_system/theme
└── main.dart            # App entry with DI init, localization delegates
```

## Phase 1: Foundation (Core Layer)

### Requirements
- [x] pubspec.yaml has: flutter_bloc ^8.1.6, get_it ^8.0.2, dartz ^0.10.1, equatable ^2.0.5, very_good_analysis ^6.0.0, bloc_test ^9.1.7, mocktail ^1.0.4
- [x] `lib/core/di/injection.dart` exports `configureDependencies()` and `getIt` final
- [x] `lib/core/error/failures.dart` has sealed Failure class with AuthFailure, ServerFailure, CacheFailure, ValidationFailure
- [x] `lib/core/error/exceptions.dart` has typed exception classes
- [x] `lib/core/enums/enums.dart` has UserRole, ApplicationStatus, MatchBand, JobSource
- [x] `lib/core/constants/api_constants.dart` has API/collection name constants
- [x] `lib/core/models/` has individual model files (app_user.dart, job.dart, notification.dart, etc.)
- [x] `lib/core/router/route_names.dart` has route path constants
- [x] `lib/main.dart` calls `configureDependencies()` before runApp

## Phase 2: Design System (Atomic Design)

### Requirements
- [x] `lib/design_system/theme/app_colors.dart` - AppColors class with all color constants
- [x] `lib/design_system/theme/app_typography.dart` - AppTypography class with text style presets
- [x] `lib/design_system/theme/app_theme.dart` - buildAppTheme() function
- [x] 10 atoms: user_avatar, verified_badge, org_badge, skill_chip, status_pill, work_mode_pill, tag_chip, hot_badge, loading_spinner, info_row
- [x] 7 molecules: match_score_ring, match_band_pill, stat_box, section_header, trust_score_bar, profile_completeness_bar, company_logo
- [x] 5 organisms: section_card, empty_state, job_card, provider_card, application_card
- [x] `lib/design_system/design_system.dart` barrel exports all above
- [x] `lib/widgets/common.dart` re-exports atoms/molecules/organisms for backward compat
- [x] `lib/widgets/cards.dart` re-exports card organisms for backward compat
- [x] `lib/utils/theme.dart` re-exports app_colors + app_theme for backward compat

## Phase 3: Auth Feature (Full BLoC)

### Requirements
- [x] `AuthRepository` wraps AuthService with `Either<Failure, T>` return types using dartz
- [x] `AuthEvent` is a sealed class with: EmailSignInRequested, EmailSignUpRequested, GoogleSignInRequested, PasswordResetRequested, SignOutRequested, AuthErrorDismissed
- [x] `AuthState` is a sealed class with: AuthInitial, AuthLoading, AuthSuccess(uid), AuthPasswordResetSent, AuthFailure(message), AuthUnauthenticated
- [x] `AuthBloc` has handlers for all 6 events, uses result.fold() pattern
- [x] Auth screen uses BlocListener for navigation and BlocBuilder for UI
- [x] Router wraps auth route with BlocProvider<AuthBloc>
- [x] Extracted widgets: ErrorBanner, OrDivider, GoogleSignInButton, RoleChip
- [x] Old `lib/screens/auth_screen.dart` is a barrel re-export

## Phase 4: Feature Cubits (Strangler Fig)

### Requirements
- [x] Each feature has: data/repository + presentation/cubit/state + barrel export
- [x] ProfileRepository: watchUser, getUser, updateProfile, uploadResume
- [x] ProfileCubit: loadProfile (stream sub), updateProfile, uploadResume
- [x] ProfileState: ProfileInitial, ProfileLoading, ProfileLoaded(user), ProfileUpdating(user), ProfileError(message)
- [x] JobsRepository: watchActiveJobs, postJob, computeMatch, hasApplied
- [x] JobsCubit: loadJobs (stream sub), postJob
- [x] JobsState: JobsInitial, JobsLoading, JobsLoaded(jobs), JobPostSuccess(jobId), JobsError(message)
- [x] ApplicationsRepository: watchApplications, apply, withdraw
- [x] ApplicationsCubit: loadApplications (stream sub), apply, withdraw
- [x] NotificationsRepository: watchNotifications, markAllRead, markRead
- [x] NotificationsCubit: loadNotifications (stream sub with unread count), markAllRead, markRead
- [x] MessagingRepository: watchConversations, watchMessages, sendMessage
- [x] MessagingCubit: loadConversations (stream sub), loadMessages, sendMessage
- [x] DashboardRepository: watchSeekers, watchJobs, watchApplications
- [x] DashboardCubit: loadDashboard (multiple stream subs)
- [x] OnboardingCubit: step navigation (nextStep, previousStep, completeOnboarding)
- [x] All repositories registered as lazySingletons in DI
- [x] All blocs/cubits registered as factories in DI

## Phase 5: Localization + Lint Rules

### Requirements
- [x] `l10n.yaml` config at project root with output-dir: lib/l10n/generated
- [x] `lib/l10n/app_en.arb` with ~100 translation keys covering all UI text
- [x] `pubspec.yaml` has `generate: true` under flutter section
- [x] Generated localization code in `lib/l10n/generated/`
- [x] `main.dart` includes localizationsDelegates and supportedLocales from AppLocalizations
- [x] `analysis_options.yaml` excludes `lib/l10n/generated/**`
- [x] `analysis_options.yaml` includes architecture enforcement lint comments
- [x] Uses `very_good_analysis` package for strict lint rules

## Phase 6: BDD Test Coverage

### Requirements
- [x] `test/helpers/mocks.dart` - Mock classes for all 7 repositories using mocktail
- [x] Tests use BDD naming: "Given X, When Y, Then Z"
- [x] Tests grouped by Feature > Scenario pattern
- [x] AuthBloc tests (10 scenarios): sign in success/failure, sign up success/failure, Google sign in success/cancelled, password reset, sign out, error dismissed
- [x] ProfileCubit tests (3 scenarios): load profile, null stream, update profile
- [x] JobsCubit tests (5 scenarios): load jobs, empty list, stream error, post success, post failure
- [x] NotificationsCubit tests (5 scenarios): load with unread count, empty, stream error, mark all read, mark single read
- [x] All tests use `registerFallbackValue` for non-primitive matcher types (UserRole, Job)
- [x] All 23 tests pass

## Verification Checklist

- [x] `flutter test` - All 23 tests pass
- [x] `flutter analyze` - 0 errors (only pre-existing info/warnings in legacy code)
- [x] `flutter build web --release` - Succeeds
- [x] Backward compatibility maintained via barrel re-exports
- [x] Legacy Provider code coexists with new BLoC (Strangler Fig)
- [x] DI container registers all services, repositories, blocs/cubits

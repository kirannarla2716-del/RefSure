import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:refsure/core/enums/enums.dart';
import 'package:refsure/core/models/app_user.dart';
import 'package:refsure/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:refsure/features/profile/presentation/cubit/profile_state.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockProfileRepository mockProfileRepository;

  setUp(() {
    mockProfileRepository = MockProfileRepository();
  });

  final testUser = AppUser(
    id: 'uid-1',
    role: UserRole.seeker,
    name: 'Test User',
    headline: 'Job Seeker',
    title: 'Developer',
    location: 'Bangalore',
    experience: 5,
    skills: ['Flutter', 'Dart'],
    bio: 'A test user',
    email: 'test@example.com',
    profileComplete: 80,
  );

  group('Feature: User Profile Management', () {
    // ── Scenario: Load Profile ─────────────────────────────────
    group('Scenario: User loads their profile', () {
      blocTest<ProfileCubit, ProfileState>(
        'Given a valid user ID, '
        'When loadProfile is called, '
        'Then it should emit [ProfileLoading, ProfileLoaded]',
        build: () {
          when(() => mockProfileRepository.watchUser(any()))
              .thenAnswer((_) => Stream.value(testUser));
          return ProfileCubit(profileRepository: mockProfileRepository);
        },
        act: (cubit) => cubit.loadProfile('uid-1'),
        expect: () => [
          const ProfileLoading(),
          isA<ProfileLoaded>()
              .having((s) => s.user.name, 'user.name', 'Test User'),
        ],
      );

      blocTest<ProfileCubit, ProfileState>(
        'Given the user stream emits null, '
        'When loadProfile is called, '
        'Then it should only emit [ProfileLoading]',
        build: () {
          when(() => mockProfileRepository.watchUser(any()))
              .thenAnswer((_) => Stream.value(null));
          return ProfileCubit(profileRepository: mockProfileRepository);
        },
        act: (cubit) => cubit.loadProfile('uid-unknown'),
        expect: () => [const ProfileLoading()],
      );
    });

    // ── Scenario: Update Profile ───────────────────────────────
    group('Scenario: User updates their profile', () {
      blocTest<ProfileCubit, ProfileState>(
        'Given a loaded profile, '
        'When updateProfile is called with new data, '
        'Then it should emit [ProfileUpdating] and call repository',
        build: () {
          when(
            () => mockProfileRepository.updateProfile(any(), any()),
          ).thenAnswer((_) async {});
          return ProfileCubit(profileRepository: mockProfileRepository);
        },
        seed: () => ProfileLoaded(testUser),
        act: (cubit) => cubit.updateProfile('uid-1', {'title': 'Sr Dev'}),
        expect: () => [isA<ProfileUpdating>()],
        verify: (_) {
          verify(
            () => mockProfileRepository.updateProfile(
              'uid-1',
              {'title': 'Sr Dev'},
            ),
          ).called(1);
        },
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/core/router/route_names.dart';
import 'package:refsure/router.dart';

void main() {
  String? redirect({
    String location = '/',
    bool authReady = true,
    bool isSignedOut = false,
    bool isGuest = false,
    bool isProvider = false,
    bool hasProfile = true,
    int profileComplete = 80,
  }) =>
      resolveAppRedirect(
        location: location,
        authReady: authReady,
        isSignedOut: isSignedOut,
        isGuest: isGuest,
        isProvider: isProvider,
        hasProfile: hasProfile,
        profileComplete: profileComplete,
      );

  group('authentication and onboarding redirects', () {
    test('does not redirect while authentication is still resolving', () {
      expect(
        redirect(authReady: false, isSignedOut: true, hasProfile: false),
        isNull,
      );
    });

    test('sends signed-out users to auth without looping on auth', () {
      expect(redirect(isSignedOut: true), '/auth');
      expect(redirect(location: '/auth', isSignedOut: true), isNull);
    });

    test('requires onboarding for an incomplete real account', () {
      expect(redirect(profileComplete: 69), '/onboarding');
      expect(
        redirect(location: '/onboarding', profileComplete: 69),
        isNull,
      );
      expect(redirect(hasProfile: false), '/onboarding');
    });

    test('does not force demo guests through onboarding', () {
      expect(
        redirect(isGuest: true, hasProfile: false, profileComplete: 0),
        isNull,
      );
    });

    test('moves completed real accounts out of auth and onboarding', () {
      expect(redirect(location: '/auth'), '/');
      expect(redirect(location: '/onboarding'), '/');
    });
  });

  group('role guards', () {
    for (final route in [
      '/verify-org',
      '/post-job',
      RouteNames.careersPortal,
    ]) {
      test('blocks seeker access to $route', () {
        expect(redirect(location: route), '/');
      });

      test('allows provider access to $route', () {
        expect(redirect(location: route, isProvider: true), isNull);
      });
    }
  });
}

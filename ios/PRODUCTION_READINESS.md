# RefSure iOS production readiness

## Local configuration

- Product bundle identifier: `com.refsure.refsure`
- Minimum supported version: iOS 14.0
- Display name: RefSure
- Signing: automatic; an Apple Development Team must be selected outside source control
- App Check provider: App Attest in production builds
- Authentication: email/password; Google Sign-In is hidden on iOS until an
  iOS OAuth client and reversed client ID are issued

Run the static preflight from the repository root:

```sh
./ios/scripts/check_production_readiness.sh
```

After Xcode and CocoaPods are installed, verify an unsigned simulator build:

```sh
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ios --simulator \
  --dart-define=APP_ENV=production \
  --dart-define=ENABLE_FIREBASE_APP_CHECK=true
```

## Required account configuration

These values cannot safely be generated or committed to this repository:

1. Register `com.refsure.refsure` in the Apple Developer account and Firebase project `refsure-d6e3a`.
2. Download that Firebase app's `GoogleService-Info.plist` to `ios/Runner/GoogleService-Info.plist`.
3. To enable optional Google Sign-In, create an iOS OAuth client and add its `REVERSED_CLIENT_ID` as a URL scheme in `ios/Runner/Info.plist`. Never ship a placeholder scheme.
4. The iOS entry in `lib/firebase_options.dart` targets Firebase app `1:1085369749507:ios:f1eed666dca41b7e46fe36`.
5. Select the distribution team and enable the App Attest capability for the Runner target. Register the iOS app in Firebase App Check and enforce it only after release validation.
6. Enable Google authentication in Firebase and configure the OAuth consent screen and support email.
7. Create App Store Connect records, distribution certificates/profiles, privacy answers, age rating, support/privacy URLs, screenshots, and review credentials.

## Release validation gates

- Test Google and email authentication on a physical device.
- Test App Attest with Firebase App Check metrics before enforcement.
- Test photo selection, camera denial/recovery, CV upload, jobs, referral creation, status changes, gratitude, notifications, and account deletion.
- Validate Dynamic Type, VoiceOver, keyboard navigation, dark/light contrast, offline/retry behavior, and iPhone SE through current Pro Max layouts.
- Archive using Release configuration, run Xcode validation, upload to TestFlight, and complete internal and external beta passes without critical defects.

The app is not App Store production-ready until all account configuration and release validation gates pass.

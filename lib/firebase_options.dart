import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class RefSureRuntimeConfig {
  const RefSureRuntimeConfig({
    required this.environment,
    required this.useFirebaseEmulators,
    required this.enableAppCheck,
    required this.appCheckWebKey,
  });

  static const fromBuild = RefSureRuntimeConfig(
    environment: String.fromEnvironment(
      'REFSURE_ENV',
      defaultValue: 'development',
    ),
    useFirebaseEmulators: bool.fromEnvironment('USE_FIREBASE_EMULATORS'),
    enableAppCheck: bool.fromEnvironment('ENABLE_FIREBASE_APP_CHECK'),
    appCheckWebKey: String.fromEnvironment('FIREBASE_APP_CHECK_WEB_KEY'),
  );

  final String environment;
  final bool useFirebaseEmulators;
  final bool enableAppCheck;
  final String appCheckWebKey;

  bool get isProduction => environment == 'production';

  void validate({required bool isWeb}) {
    if (isProduction && useFirebaseEmulators) {
      throw StateError('Production builds cannot use Firebase emulators.');
    }
    if (isProduction && !enableAppCheck) {
      throw StateError(
        'Production builds require ENABLE_FIREBASE_APP_CHECK=true.',
      );
    }
    if (enableAppCheck && isWeb && appCheckWebKey.trim().isEmpty) {
      throw StateError(
        'FIREBASE_APP_CHECK_WEB_KEY is required when App Check is enabled.',
      );
    }
  }
}

class DefaultFirebaseOptions {
  static bool get supportsGoogleSignIn =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.iOS) return ios;
    throw UnsupportedError(
      'RefSure production Firebase is currently configured for web and iOS. '
      'Register a refsure-d6e3a ${_platformName(defaultTargetPlatform)} app '
      'and regenerate Firebase options before building this platform.',
    );
  }

  static String _platformName(TargetPlatform platform) => switch (platform) {
        TargetPlatform.android => 'Android',
        TargetPlatform.iOS => 'iOS',
        TargetPlatform.macOS => 'macOS',
        TargetPlatform.windows => 'Windows',
        TargetPlatform.linux => 'Linux',
        TargetPlatform.fuchsia => 'Fuchsia',
      };

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCJwmIPCp93FNk_TmQjmC-T7OJxDGnCd7Q',
    appId: '1:1085369749507:web:e607ca3dcc14665e46fe36',
    messagingSenderId: '1085369749507',
    projectId: 'refsure-d6e3a',
    authDomain: 'refsure-d6e3a.firebaseapp.com',
    storageBucket: 'refsure-d6e3a.firebasestorage.app',
    measurementId: 'G-9RC499ECVR',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCJ1CJ7DnHXqbKPDbZTiu1EvUW0bddzbNE',
    appId: '1:1085369749507:ios:f1eed666dca41b7e46fe36',
    messagingSenderId: '1085369749507',
    projectId: 'refsure-d6e3a',
    storageBucket: 'refsure-d6e3a.firebasestorage.app',
    iosBundleId: 'com.refsure.refsure',
  );
}

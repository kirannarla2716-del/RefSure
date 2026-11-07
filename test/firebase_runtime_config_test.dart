import 'package:flutter_test/flutter_test.dart';
import 'package:refsure/firebase_options.dart';

void main() {
  test('production requires App Check', () {
    const config = RefSureRuntimeConfig(
      environment: 'production',
      useFirebaseEmulators: false,
      enableAppCheck: false,
      appCheckWebKey: '',
    );
    expect(
      () => config.validate(isWeb: true),
      throwsA(isA<StateError>()),
    );
  });

  test('production rejects emulator routing', () {
    const config = RefSureRuntimeConfig(
      environment: 'production',
      useFirebaseEmulators: true,
      enableAppCheck: true,
      appCheckWebKey: 'key',
    );
    expect(
      () => config.validate(isWeb: true),
      throwsA(isA<StateError>()),
    );
  });

  test('web App Check requires a site key', () {
    const config = RefSureRuntimeConfig(
      environment: 'staging',
      useFirebaseEmulators: false,
      enableAppCheck: true,
      appCheckWebKey: '',
    );
    expect(
      () => config.validate(isWeb: true),
      throwsA(isA<StateError>()),
    );
  });

  test('local emulator configuration remains App Check independent', () {
    const config = RefSureRuntimeConfig(
      environment: 'development',
      useFirebaseEmulators: true,
      enableAppCheck: false,
      appCheckWebKey: '',
    );
    expect(() => config.validate(isWeb: true), returnsNormally);
  });
}

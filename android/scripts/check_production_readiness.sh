#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
ANDROID="$ROOT/android"
APP="$ANDROID/app"
PACKAGE_PATH="$APP/src/main/kotlin/com/refsure/refsure/MainActivity.kt"
errors=0
repository_only="${REFSURE_ANDROID_REPOSITORY_ONLY:-0}"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  errors=$((errors + 1))
}

[ -f "$ANDROID/settings.gradle.kts" ] || fail "settings.gradle.kts is missing."
[ -f "$ANDROID/build.gradle.kts" ] || fail "build.gradle.kts is missing."
[ -f "$APP/build.gradle.kts" ] || fail "app/build.gradle.kts is missing."
[ -x "$ANDROID/gradlew" ] || fail "Executable Gradle wrapper is missing."
[ -f "$ANDROID/gradlew.bat" ] || fail "Windows Gradle wrapper is missing."
[ -f "$ANDROID/gradle/wrapper/gradle-wrapper.jar" ] || \
  fail "Gradle wrapper JAR is missing."
[ ! -f "$ANDROID/settings.gradle" ] || fail "Legacy settings.gradle conflicts with Kotlin DSL."
[ ! -f "$ANDROID/build.gradle" ] || fail "Legacy build.gradle conflicts with Kotlin DSL."
[ ! -f "$APP/build.gradle" ] || fail "Legacy app/build.gradle conflicts with Kotlin DSL."

grep -q 'applicationId = "com.refsure.refsure"' "$APP/build.gradle.kts" || \
  fail "Expected application ID com.refsure.refsure is not configured."
grep -q 'namespace = "com.refsure.refsure"' "$APP/build.gradle.kts" || \
  fail "Expected namespace com.refsure.refsure is not configured."
[ -f "$PACKAGE_PATH" ] || fail "Canonical MainActivity package is missing."
[ "$(find "$APP/src/main/kotlin" -name MainActivity.kt | wc -l | tr -d ' ')" = "1" ] || \
  fail "Exactly one Android MainActivity must exist."

if grep -Eq 'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)|signingConfigs\.debug' \
    "$APP/build.gradle.kts"; then
  fail "Release builds must not use the debug signing key."
fi

if grep -q 'android:roundIcon="@mipmap/ic_launcher_round"' \
    "$APP/src/main/AndroidManifest.xml" && \
    ! find "$APP/src/main/res" -name 'ic_launcher_round.*' -print -quit | grep -q .; then
  fail "Manifest references a missing round launcher icon."
fi

if [ "$repository_only" != "1" ]; then
  if ! grep -q 'TargetPlatform.android => android' "$ROOT/lib/firebase_options.dart"; then
    fail "Android Firebase options are missing. Register com.refsure.refsure in refsure-d6e3a."
  fi

  [ -f "$ANDROID/key.properties" ] || \
    fail "Production key.properties is missing (the example file is not a signing credential)."
fi

if [ "$errors" -ne 0 ]; then
  printf '\nRefSure Android preflight failed with %s blocker(s).\n' "$errors" >&2
  exit 1
fi

printf 'RefSure Android static production preflight passed.\n'

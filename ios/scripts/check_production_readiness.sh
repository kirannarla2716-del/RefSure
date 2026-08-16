#!/bin/sh
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
IOS="$ROOT/ios"
PLIST="$IOS/Runner/Info.plist"
FIREBASE_PLIST="$IOS/Runner/GoogleService-Info.plist"
PROJECT="$IOS/Runner.xcodeproj/project.pbxproj"
errors=0

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  errors=$((errors + 1))
}

plutil -lint "$PLIST" >/dev/null || fail "Runner/Info.plist is invalid."
grep -q 'PRODUCT_BUNDLE_IDENTIFIER = com.refsure.refsure;' "$PROJECT" || \
  fail "Expected bundle identifier com.refsure.refsure is not configured."
grep -q "platform :ios, '14.0'" "$IOS/Podfile" || \
  fail "Podfile deployment target must be iOS 14.0."
grep -q 'IPHONEOS_DEPLOYMENT_TARGET = 14.0;' "$PROJECT" || \
  fail "Xcode deployment target must be iOS 14.0."

if [ ! -f "$FIREBASE_PLIST" ]; then
  fail "GoogleService-Info.plist is missing. Download the iOS config for com.refsure.refsure."
else
  plist_bundle_id="$(/usr/libexec/PlistBuddy -c 'Print:BUNDLE_ID' "$FIREBASE_PLIST" 2>/dev/null || true)"
  reversed_client_id="$(/usr/libexec/PlistBuddy -c 'Print:REVERSED_CLIENT_ID' "$FIREBASE_PLIST" 2>/dev/null || true)"
  [ "$plist_bundle_id" = 'com.refsure.refsure' ] || \
    fail "Firebase plist BUNDLE_ID does not match com.refsure.refsure."
  if [ -z "$reversed_client_id" ] && \
      ! grep -q 'defaultTargetPlatform != TargetPlatform.iOS' \
        "$ROOT/lib/firebase_options.dart"; then
    fail "Google Sign-In must be configured or disabled on iOS."
  fi
  if [ -n "$reversed_client_id" ] && ! grep -q "$reversed_client_id" "$PLIST"; then
    fail "Info.plist must register the Firebase REVERSED_CLIENT_ID URL scheme."
  fi
fi

if grep -q 'YOUR_REVERSED_CLIENT_ID' "$PLIST"; then
  fail "Info.plist still contains the placeholder Google URL scheme."
fi

if [ "$errors" -ne 0 ]; then
  printf '\nRefSure iOS preflight failed with %s blocker(s).\n' "$errors" >&2
  exit 1
fi

printf 'RefSure iOS static production preflight passed.\n'

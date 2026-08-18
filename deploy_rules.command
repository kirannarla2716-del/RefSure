#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="refsure-d6e3a"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARAM_FILE="$ROOT/functions/.env.$PROJECT_ID"

cd "$ROOT"

command -v flutter >/dev/null || {
  echo "flutter is required." >&2
  exit 1
}
command -v firebase >/dev/null || {
  echo "firebase-tools is required." >&2
  exit 1
}
: "${FIREBASE_APP_CHECK_WEB_KEY:?Set FIREBASE_APP_CHECK_WEB_KEY.}"
: "${VERIFICATION_MAIL_FROM:?Set VERIFICATION_MAIL_FROM.}"

firebase projects:list --json >/dev/null
firebase functions:secrets:access OTP_HMAC_SECRET \
  --project "$PROJECT_ID" >/dev/null
firebase functions:secrets:access VERIFICATION_MAIL_API_KEY \
  --project "$PROJECT_ID" >/dev/null

cat >"$PARAM_FILE" <<EOF
ENFORCE_APP_CHECK=true
VERIFICATION_MAIL_FROM=$VERIFICATION_MAIL_FROM
EOF
trap 'rm -f "$PARAM_FILE"' EXIT

flutter pub get
flutter analyze \
  lib/main.dart \
  lib/firebase_options.dart \
  lib/services/trusted_application_service.dart
flutter test
npm --prefix functions install
npm --prefix functions test
npm --prefix functions exec -- tsc \
  --module commonjs \
  --moduleResolution node \
  --target es2022 \
  --strict \
  --esModuleInterop \
  --skipLibCheck \
  --sourceMap \
  --outDir lib \
  --rootDir src \
  src/index.ts
npm --prefix test/security ci
npm --prefix test/security test
flutter build web --release \
  --dart-define=REFSURE_ENV=production \
  --dart-define=ENABLE_FIREBASE_APP_CHECK=true \
  --dart-define=FIREBASE_APP_CHECK_WEB_KEY="$FIREBASE_APP_CHECK_WEB_KEY"

firebase deploy \
  --project "$PROJECT_ID" \
  --only functions,firestore:rules,firestore:indexes,storage,hosting \
  --non-interactive

# RefSure Project Status

Last verified: 2026-08-18

This is the canonical handoff for RefSure. Update it when implementation,
deployment state, test evidence, blockers, or release decisions change.

## Objective

Build a trusted referral platform where:

- seekers discover jobs, request referrals, track applications, and thank
  referrers;
- referrers import current careers-portal jobs, review candidates for their
  own postings, and move applications through a controlled lifecycle;
- sensitive role, verification, referral, reputation, notification, and
  counter operations remain server-authoritative;
- web launches first at `refsure.in`, followed by a production-quality iOS
  application.

## Current Decision

**Production: NO-GO. Local seeded web demo: GO.**

The local demo is running at `http://127.0.0.1:7357`. Its seeded referral
request fallback is intentionally in-memory and debug/demo-only. It proves the
UI journey but does not prove persisted seeker-to-referrer delivery.

## Platform State

### Web

- Responsive seeker/referrer UI and release build work.
- Firebase project: `refsure-d6e3a`.
- Web Firebase app: `1:1085369749507:web:e607ca3dcc14665e46fe36`.
- Hardened Firestore rules and indexes are deployed.
- Hosting exists at `https://refsure-d6e3a.web.app`, but production
  Hosting/Functions/Storage are not fully deployed.
- `refsure.in` is registered through GoDaddy but DNS does not resolve because
  the registrar reports `clientHold`.

### iOS

- Bundle ID: `com.refsure.refsure`.
- Firebase iOS app: `1:1085369749507:ios:f1eed666dca41b7e46fe36`.
- Firebase options, plist, iOS 14 minimum, launch screen, CocoaPods, privacy
  declarations, and static preflight are configured.
- CocoaPods installed 45 pods successfully.
- Google Sign-In is hidden on iOS until an iOS OAuth client exists;
  email/password remains available.
- App Store archive and device sign-off are pending.

### Android

- Android is not production-ready and has no verified release build.
- The local machine has no Android SDK, so an App Bundle cannot currently be
  compiled or validated.
- Firebase options contain web and iOS registrations only; there is no
  Android Firebase registration or `google-services.json`.
- Duplicate Groovy/Kotlin Gradle configurations and duplicate MainActivity
  packages disagree on the application ID (`com.refsure.app` versus
  `com.refsure.refsure`). Release signing still uses the debug key.
- The manifest references a missing `ic_launcher_round` resource.

### Brand Assets

- iOS, Android, and web currently ship the stock Flutter logo rather than a
  RefSure production mark. A final icon system, adaptive Android icon, and
  store artwork are required before mobile submission.

## Working And Verified

- Authentication and onboarding routing.
- Seeker and referrer dashboards.
- Job discovery, filters, details, and responsive 320/375 px cards.
- Careers-portal company switching, stale-response protection, refresh, and
  filter preservation.
- Application versioning and optimistic transition commands.
- Trusted callable clients for applications, roles, gratitude, and work-email
  verification.
- Server-derived matching and deterministic/idempotent commands.
- Public-profile projection and privacy-safe discovery.
- Firestore/Storage rules with denial tests for protected state.
- Participant-only gratitude reads and bounded canonical message writes.
- Demo referral UI: success, pending state, and duplicate prevention.
- Mobile large-text, safe-area, keyboard, touch-target, and loading semantics.
- Production-equivalent web compilation and iOS static preflight.
- Canonical role presentation uses `Referral-SEEKER` and
  `Referral-PROVIDER`; profile switching handles trusted errors and supports a
  strictly local debug/demo fallback.
- The persistent mode banner uses the same purple brand treatment for both
  seeker and provider modes; focused BDD verification passes 9 scenarios.
- The persistent mode banner now uses a larger icon container, 13 px bold role
  label, and expanded spacing while preserving the canonical role naming and
  purple treatment. The daily-jobs callout uses the primary opportunity color,
  work icon, and a high-contrast count badge.
- The seeker Home page highlights the exact number of active jobs posted
  today, with direct navigation to Jobs.
- The Apply page no longer offers Hired as a stage; legacy hired records remain
  readable and are presented under Completed.
- A guarded Administration workspace supports account activation,
  deactivation/removal, scoped additional access, time-bound onboarding
  exceptions, custom-claim authorization, and immutable audit events. Demo
  mode includes local test users; production commands require deployed
  Functions and an approved Firebase `admin` custom claim.
- Five-check feature readiness and Given/When/Then acceptance conventions are
  documented in `docs/BDD_ACCEPTANCE.md`. The Investor experience remains NOT
  READY until all five checks have evidence.
- Referral-PROVIDER Jobs is role-specific: My Positions contains only owned
  postings with candidates grouped by position, while Organization Jobs embeds
  the current careers feed with filters and one-click posting. Provider job
  details expose candidate review rather than referral requests and reject
  direct access to another provider's position.
- Careers-portal imports use deterministic per-provider/external-role IDs and
  transactional create-if-absent behavior, preventing duplicate postings and
  counter resets on retries. Encoded careers descriptions are decoded before
  HTML removal.
- The referral marketplace now has explicit `accepted`, `declined`,
  `withdrawn`, and `expired` states. Seekers can withdraw active requests;
  providers accept or decline with a reason; terminal states cannot be
  reopened.
- Providers can publish referral availability and a bounded capacity. Trusted
  application submission rejects paused/full providers, increments the
  server-owned active-request counter, and terminal outcomes release capacity.
- New requests receive a 48-hour response deadline. A scheduled trusted
  function expires unanswered requests, updates counters, releases capacity,
  records an immutable event, and notifies the seeker.
- Marking a candidate referred requires an internal referral reference. The
  trusted command writes a participant-readable, client-immutable referral
  receipt; seeker application cards surface receipt confirmation.
- Conversation safety now includes report, block, and unblock controls. Blocks
  are owner-controlled and Firestore rejects new messages in both directions;
  reports use an authenticated App Check-protected callable with canonical
  categories, bounded details, idempotency, and a five-per-hour limit. Clients
  cannot read or forge report or rate-limit records.
- Administrators now have a protected safety-moderation queue for open reports
  with required-note resolve, dismiss, and escalate decisions. Decisions are
  App Check protected, admin-claim authorized, idempotent, and recorded in a
  client-inaccessible immutable moderation event.
- Profile now exposes explicit data-export and account-deletion request
  controls. The trusted callable queues one server-owned pending request per
  user/action and records an immutable event; the UI accurately presents this
  as a verified operations request rather than immediate destructive action.
- Unexpected trusted-command failures now emit a structured `RS-XXXXXXXX`
  support reference in server logs and safe callable error details.

## Latest Evidence

### 2026-08-18 Mobile Release Audit

- iOS static production preflight: passed.
- Full Xcode is not installed, so archive, simulator/device, TestFlight, and
  App Store validation remain unverified.
- Android release App Bundle: not run because Flutter Doctor reports no
  Android SDK.
- Android Firebase registration, canonical package ID, release keystore,
  Gradle configuration, round/adaptive icon, Play Console setup, and device
  testing are incomplete.
- Visual inspection confirmed that all current platform icons are stock
  Flutter artwork, not RefSure branding.

### 2026-08-16 Production Readiness Audit

- Full Flutter suite: 116 passed.
- Firebase Functions: 58 passed.
- Firestore/Storage rules: 18 passed.
- Production-configured Flutter web release build: passed with App Check
  enabled and a non-production audit placeholder key.
- iOS static production preflight: passed.
- Full analyzer: 0 errors, 36 warnings, and 1,760 infos (1,796 total).
- Public-profile migration safety initially failed because referral
  availability and capacity were omitted. The schema drift was corrected and
  both migration tests now pass; CI now includes the migration suite.
- `refsure.in` and `www.refsure.in` do not resolve.
- `https://refsure-d6e3a.web.app` returns HTTP 404.
- Production checks for `submitApplication`, `transitionApplication`,
  `changeRole`, `reportUser`, `requestPrivacy`, and
  `adminListSafetyReports` all return HTTP 404.
- The configured Firebase Storage bucket endpoint returns HTTP 404.
- The audit found that `main` did not track `functions/` or CI. The
  `codex/refsure-latest-release` publication branch now includes the backend,
  CI, security tests, migrations, lockfiles, documentation, and application
  changes as one reviewable release candidate.
- GitHub publication completed to `kirannarla2716-del/RefSure` on branch
  `codex/refsure-latest-release`. Initial release commit: `c8d3410`. Public,
  ready-for-review PR:
  `https://github.com/kirannarla2716-del/RefSure/pull/3`.
- `git diff --check`: passed.

The production decision remains **NO-GO**.

- Full Flutter suite: 116 passed on 2026-08-11.
- Firebase Functions: 58 passed on 2026-08-11.
- Firestore/Storage rules: 18 passed.
- Public-profile migration safety: 2 passed.
- Production-equivalent web release build: passed.
- Full analyzer: no compile errors; 1,766 legacy findings remain.
- `git diff --check`: passed after the latest referral fix.
- Production-equivalent web release build passed on 2026-08-11.
- Demo-enabled web release build passed and was visually smoke-tested at
  `http://127.0.0.1:7357` on 2026-08-11. Home, Profile, Referrers, Messages,
  applications, notifications, provider-owned jobs, candidates, and sample-CV
  state are populated without weakening or depending on production rules.
- A real `AdminUser.additionalAccess` analyzer type error found during this
  pass was corrected; analyzer compile errors are now zero.
- A fresh demo-enabled web release build containing the referral lifecycle,
  provider capacity, receipt, and expiry changes passed on 2026-08-11.
- A subsequent demo-enabled web release build containing the enlarged mode
  banner and revised daily-jobs callout passed on 2026-08-11; 26 focused
  routing, BDD, and responsive job-card tests passed.
- A demo-enabled web release build containing report/block/unblock UX and
  bidirectional rule enforcement passed on 2026-08-11 and was visually
  smoke-tested through the blocked-composer state.
- A fresh demo-enabled web release build containing the moderation queue,
  privacy request controls, and structured support references passed on
  2026-08-11. Home and the seeded Administration moderation queue were visually
  smoke-tested at `http://127.0.0.1:7357`.
- Administration demo initialization now refreshes as profile data arrives;
  a fresh direct `/admin` deep link was rebuilt and visually verified with all
  7 seeded accounts and the open moderation report on 2026-08-11.

Focused test counts overlap the full suite and must not be added to it.

## Pending

### Investor And CEO Cross-Check

The 2026-08-11 cross-check rates weighted product completion at **71%**. The
job-specific referral loop, referrer capacity, response SLA, controlled
lifecycle, and referral receipt are a credible product wedge. The remaining
investment risks are not additional dashboard features: they are live
marketplace proof, cohort liquidity, analytics and retention evidence,
production fulfillment of privacy requests, production reliability, and
deployed cross-role delivery. Monetization intentionally remains deferred until the 10,000-user
and demonstrated-value gates; no paid-access claim should appear before then.

### P0 Web Release Blockers

1. Upgrade Firebase Spark to Blaze. This paid action requires explicit
   authorization at action time.
2. Initialize Firebase Storage and deploy `storage.rules`.
3. Create `OTP_HMAC_SECRET` and `VERIFICATION_MAIL_API_KEY` in Secret Manager.
4. Configure and verify `VERIFICATION_MAIL_FROM` with a real mail provider.
5. Register a production web App Check site key.
6. Deploy Functions, rules, indexes, Storage, and production Hosting together.
7. Pass live seeker -> referrer -> transition -> seeker smoke tests.
8. Remove GoDaddy `clientHold`, configure Firebase DNS records, and validate
   SSL for `refsure.in` and `www.refsure.in`.
9. Review and merge the `codex/refsure-latest-release` candidate before any
   production deployment.

### iOS Release Blockers

1. Install full Xcode; installation currently requires the Mac administrator
   credential, which must not be requested in chat or bypassed.
2. Configure Apple Developer Team, signing, provisioning, and App Attest.
3. Register/enforce iOS App Check after observing release metrics.
4. Build on simulator and devices, then validate through TestFlight.
5. Complete App Store Connect privacy, support, screenshots, review account,
   age rating, and release metadata.
6. Optional: create iOS Google OAuth credentials and re-enable Google Sign-In.

### Android Release Blockers

1. Install Android Studio/SDK and accept the Android toolchain licenses.
2. Choose one permanent package ID, register it in Firebase, and add the
   matching `google-services.json` and generated Android Firebase options.
3. Remove the conflicting Gradle and MainActivity variants, then verify the
   canonical build path.
4. Create a protected upload keystore and Play App Signing configuration;
   release builds must not use debug signing.
5. Add RefSure adaptive/round launcher icons and validate required Android
   permissions against actual features.
6. Build and test a signed AAB across supported API levels, configure Play
   Console privacy/data-safety/store metadata, and pass internal testing.

### Quality And Operations

- Establish or reduce the 1,601-item analyzer baseline.
- Add deployed callable/App Check integration smoke tests.
- Add monitoring, alerts, support references, backup/restore evidence, and a
  rollback rehearsal.
- Run deployed beta journeys and collect PO, QA, architecture, support, and
  beta-user sign-offs.

### Local Demo Boundary

- Core implemented modules are fully populated in debug or explicit demo mode
  using deterministic in-memory data. The demo no longer attempts forbidden
  client writes for providers, applications, messages, or notifications.
- Demo profiles include a sample CV. When a tester selects a CV while Firebase
  Storage is unavailable, explicit demo mode keeps the sample CV as the local
  uploaded document; production builds still require Storage.
- Local demo completeness does not constitute persisted backend or production
  delivery evidence.

## Referral Semantics

Production design:

1. `submitApplication` reads the authenticated seeker and stored job.
2. The backend derives matching and creates one deterministic application
   linked by `jobId`, `seekerId`, and `providerId`.
3. Events, notification, counters, and version are written atomically.
4. The owning referrer sees it under Candidates for that job.
5. Trusted transitions update both participants after reload.

Current local demo:

- only seeded `seed_job_*` jobs may use the in-memory fallback;
- it activates only in debug/demo mode when the callable is unavailable;
- production and non-seeded jobs fail closed;
- success does not imply persistence until Functions deploy and live smoke
  tests pass.

## Important Files

- Module completion report: `docs/MODULE_COMPLETION_REPORT.md`
- Release gates: `docs/PRODUCT_READINESS_GATES.md`
- Canonical deploy: `deploy_rules.command`
- CI: `.github/workflows/ci.yml`
- Runtime: `lib/firebase_options.dart`, `lib/main.dart`
- Referral: `lib/services/trusted_application_service.dart`,
  `lib/providers/app_provider.dart`, `functions/src/applications/`
- Security: `firestore.rules`, `storage.rules`, `test/security/rules.test.cjs`
- iOS: `ios/PRODUCTION_READINESS.md`,
  `ios/scripts/check_production_readiness.sh`

## Incremental Workflow

1. Read this file and run `git status --short`.
2. Inspect only files related to the newest request and listed blocker.
3. Do not repeat broad discovery or agent cycles unless evidence is stale, the
   change has broad impact, or the user explicitly asks.
4. Run focused tests while implementing.
5. Run full relevant release gates before deployment or changing sign-off.
6. Update this file with changed facts, exact evidence, and date.
7. Never infer production readiness from local/demo fallback behavior.

## GitHub Publication

- Target repository: `kirannarla2716-del/RefSure`
- Release branch: `codex/refsure-latest-release`
- Public ready-for-review pull request:
  `https://github.com/kirannarla2716-del/RefSure/pull/3`
- The source release candidate is published for review. This does not change
  the production NO-GO decision until Firebase deployment and live smoke-test
  gates pass.

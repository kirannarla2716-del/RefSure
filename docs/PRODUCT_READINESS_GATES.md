# RefSure Product Readiness Gates

RefSure uses a referral-first product loop:

`PO -> BA -> Architecture -> Development -> QA -> Beta Users -> Support -> PO`

No role may approve a release based only on feature completion. A failed gate
returns the finding to the PO and BA for prioritization, then through
implementation and verification again.

## Agent Responsibilities

| Role | Required output | Sign-off authority |
|---|---|---|
| Product Owner | Vision, outcomes, prioritized backlog, release scope | Product value and scope |
| Business Analyst | Journeys, business rules, data contracts, acceptance criteria | Requirements completeness |
| Architect | Target architecture, ADRs, NFRs, migration and risk controls | Architecture and scalability |
| Developer 1 | Careers intelligence and company-job synchronization | Careers implementation |
| Developer 2 | Platform, Firebase, security and data integrity | Platform implementation |
| Developer 3 | Product workflows and automated quality infrastructure | Workflow implementation |
| QA 1 | Functional, integration, responsive and end-to-end verification | Functional quality |
| QA 2 | Security, privacy, performance and reliability verification | Nonfunctional quality |
| Support 1 | User help, issue taxonomy and safe resolutions | Support readiness |
| Support 2 | Monitoring, incidents, escalation and rollback | Operational readiness |
| Support 3 | Onboarding, documentation and product terminology | Documentation readiness |
| Support 4 | Voice of customer, churn risks and opportunity ranking | Customer relevance |
| Beta Users | Persona-based journeys, friction, trust and retention evidence | Beta experience |

## Mandatory Release Gates

### G1: Product

- The release solves a documented seeker or referrer outcome.
- Every workflow has an accountable actor and an unambiguous next step.
- Referral requests and external applications are clearly distinguished.
- Product claims match implemented and measured behavior.

### G2: Requirements

- User stories have testable acceptance criteria.
- Roles, permissions, states, transitions and failure behavior are defined.
- Privacy, retention, consent and support consequences are documented.

### G3: Architecture

- Trust-sensitive operations run in a trusted backend.
- Writes are authorized, validated, transactional and idempotent.
- Environments and Firebase configuration are consistent across platforms.
- ATS synchronization is observable, cached, paginated and resilient.
- Capacity, cost and rollback targets are documented.

### G4: Security And Privacy

- No open P0 or P1 security/privacy defects.
- Firestore and Storage rules have allow/deny emulator tests.
- OTPs, verification, counters and reputation cannot be controlled by clients.
- Private profile data and resumes are visible only to authorized parties.
- App Check, abuse controls, audit logs and privacy workflows are enabled.

### G5: Functional Quality

- Unit, widget, integration and critical browser journeys pass.
- Seeker and referrer workflows pass on supported viewport sizes.
- Duplicate applications/imports and invalid state transitions are prevented.
- Network failure, retry and recovery behavior is tested.

### G6: Reliability And Operations

- Crash/error reporting, structured events and support reference IDs exist.
- Critical journeys have synthetic monitoring and actionable alerts.
- Versioned artifacts, staged rollout and tested rollback are available.
- Support, incident, privacy and abuse runbooks have named owners.

### G7: Beta Experience

- All critical and high beta findings are closed or explicitly rejected by PO
  with documented evidence and risk acceptance.
- First-time seeker and referrer journeys complete without assisted recovery.
- Users understand what happens after every primary action.
- Trust, usefulness and retention targets are measured and achieved.

### G8: Release Evidence

- Full automated test suite passes on the release commit.
- Analyzer has no compile errors.
- QA, Security QA, Architect, Support Operations, PO and Beta Users record
  explicit sign-off against the same immutable release candidate.
- Production smoke tests pass after deployment.

## Current Status

Current decision: **NO-GO**.

### Cycle 3 Evidence

- Flutter tests: 61 passed.
- Firebase Functions tests: 19 passed.
- Firestore and Storage rules tests: 11 passed.
- Flutter web release build: passed.
- Careers discovery and same-route company switching: beta-validated.
- Support 4 customer-value review: approved only for a controlled,
  referral-first beta.
- Functional QA, Security QA, Architecture, Beta Users, and Support Operations:
  sign-off withheld.

### Cycle 3 Blockers

- Verification domain logic exists, but callable exports, client transport,
  secrets, mail delivery, and deployment configuration are incomplete.
- Referral submission sends a Firestore `Timestamp` through JSON and fails at
  runtime.
- Real profile and job payloads do not match Firestore Rules allowlists.
- Discovery still reads private `users` instead of `publicProfiles`.
- Public-profile migration has no continuous projection trigger.
- Application counters use incompatible `applicationCount` and `applicants`
  field names.
- Application transitions lack optimistic version checks and stable retry IDs.
- Functions trust client-supplied match scores.
- Firebase and OAuth projects remain inconsistent across platforms.
- App Check, callable emulator E2E, CI/CD, monitoring, support references, and
  exercised rollback remain absent.
- Privacy/Terms acceptance, real support contact paths, and accurate beta
  product claims remain incomplete.

### Cycle 6 Evidence

- Flutter tests: 94 passed.
- Firebase Functions tests: 45 passed.
- Firestore and Storage rules tests: 13 passed.
- Public-profile migration safety tests: 2 passed.
- Production-equivalent web release build: passed.
- Full analyzer completed with no compile errors; legacy warnings remain.
- CocoaPods installation: passed with 45 pods.
- iOS static production preflight and Firebase app registration: passed.
- Hardened Firestore rules and indexes deployed to `refsure-d6e3a`.
- Message writes are schema- and size-constrained; gratitude reads are limited
  to relationship participants.
- App Check defaults to enforced outside the Functions emulator.

### Cycle 6 External Release Blockers

- Firebase project is on the Spark plan. Secret Manager and production Cloud
  Functions cannot be enabled without a Blaze billing upgrade.
- Firebase Storage has not been initialized in the project.
- No production mail-provider API key or verified sender exists for work-email
  verification.
- No production web App Check site key is registered.
- `refsure.in` is under the registrar `clientHold` status, so DNS does not
  resolve and Firebase custom-domain verification cannot begin.
- Full Xcode installation requires an administrator credential; this machine
  has no Apple signing identity, App Attest registration, provisioning profile,
  or App Store Connect release configuration.

### Cycle 7 Evidence

- Flutter tests: 116 passed.
- Firebase Functions tests: 58 passed.
- Firestore and Storage rules tests: 18 passed.
- Demo-enabled Flutter web release build: passed.
- Safety reports now have an admin-claim-protected moderation queue with
  required notes, bounded decisions, idempotency, and immutable events.
- Data-export and account-deletion requests use an authenticated, App Check
  protected, server-owned queue with immutable request events.
- Unexpected trusted callable failures return a safe structured support
  reference correlated with server logs.
- Rebuilt Home and seeded Administration moderation queue passed visual smoke
  checks at `http://127.0.0.1:7357`.

Cycle 7 does not change the production **NO-GO** decision: latest Functions,
rules, and indexes are not deployed, and the Cycle 6 external blockers remain.

### Cycle 8 Evidence (2026-08-16)

- Flutter tests: 116 passed.
- Firebase Functions tests: 58 passed.
- Firestore and Storage rules tests: 18 passed.
- Public-profile migration tests initially exposed canonical schema drift in
  referral availability and capacity fields. The migration was corrected, CI
  now runs the suite, and both tests pass.
- Production-configured web release build and iOS static preflight: passed.
- Analyzer: 0 errors, 36 warnings, and 1,760 infos.
- Hosting, six core callable endpoints, and the configured Storage bucket all
  returned HTTP 404; the custom domain did not resolve.
- The audit found Functions and CI untracked on `main`; the
  `codex/refsure-latest-release` publication branch packages them with the
  application, lockfiles, rules, migrations, tests, and evidence for review.

Cycle 8 decision: **NO-GO**. G3, G4, G6, G7, and G8 remain unsatisfied.

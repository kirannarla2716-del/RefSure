---
name: refsure-project
description: Resume, implement, test, review, or deploy the RefSure Flutter/Firebase platform using its canonical verified status instead of rediscovering the entire repository. Use for any RefSure feature, bug, readiness, web hosting, Firebase, referral workflow, careers portal, security, or iOS release task.
---

# RefSure Project

## Start Here

1. Read `docs/REFSURE_STATUS.md` from the repository root.
2. Run `git status --short` to preserve the dirty worktree.
3. Use the status file to limit investigation to the newest request and its
   affected files.

Do not repeat broad repository audits, agent sign-off cycles, or full test runs
only to regain context. Repeat them when the change has broad impact, evidence
is stale, or the user explicitly asks.

## Working Rules

- Treat `docs/REFSURE_STATUS.md` as canonical current state.
- Treat `docs/PRODUCT_READINESS_GATES.md` as release criteria and history.
- Preserve unrelated uncommitted changes.
- Use focused tests while editing; run full relevant gates before deployment
  or changing sign-off.
- Keep trusted operations server-authoritative. Never weaken production rules
  to make the local demo pass.
- Distinguish in-memory demo referrals from persisted backend delivery.
- Paid upgrades, credentials, domain verification, and Apple account actions
  require legitimate access and applicable confirmation.

## Finish Material Work

Update `docs/REFSURE_STATUS.md` only when a fact changes. Record:

- implementation or deployment change;
- exact test/build evidence;
- blockers opened or closed;
- platform and sign-off impact;
- new verification date.

Do not inflate test totals by adding overlapping focused and full-suite counts.

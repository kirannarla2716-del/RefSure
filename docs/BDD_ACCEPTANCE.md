# RefSure BDD Acceptance Framework

Every new feature must have executable scenarios using **Given / When / Then**
language. A feature is available only when all five product checks pass and its
focused acceptance scenarios, regression suite, and relevant trusted-backend
tests pass.

## Five Checks

1. **User need:** evidence identifies the user and unmet need.
2. **Importance:** the problem is material enough to prioritize.
3. **Usability:** target users can discover and complete the journey.
4. **Value add:** user and RefSure outcomes are explicit and measurable.
5. **Acceptance evidence:** BDD scenarios and applicable security tests pass.

## Investor Experience Assessment

The proposed experience could help users identify relevant investors, evaluate
funding fit, and request trusted introductions. It should not be implemented as
an open investor directory. Before approval, validate demand with beta users,
define investor consent and verification, test discovery/introduction UX, agree
success metrics, and pass privacy, abuse, and acceptance scenarios. Until all
five checks are recorded as passed, its status remains **NOT READY**.

## New Release Scenarios

- Given a seeker or provider, when any mode title is displayed, then it uses
  `Referral-SEEKER` or `Referral-PROVIDER` consistently.
- Given a user changes mode, when the trusted command succeeds, then navigation,
  subscriptions, and profile state rebuild for the selected mode.
- Given the seeded debug demo cannot reach Functions, when mode is changed, then
  only local demo state changes; production remains fail-closed.
- Given the Apply page, when statuses render, then no Hired filter or stage is
  offered and historical terminal records are counted as Completed.
- Given active jobs posted today, when a seeker opens Home, then a top banner
  announces the exact count and opens Jobs.
- Given a non-admin, when Administration is opened, then access is denied.
- Given an admin action, when it succeeds, then an immutable audit event records
  actor, subject, action, details, and timestamp.
- Given a proposed feature with any failed check, when release eligibility is
  evaluated, then it remains unavailable.
- Given Referral-PROVIDER mode, when Jobs opens, then only positions owned by
  that provider and current organization-feed roles are available; seeker
  referral-request controls are absent.
- Given a provider position, when candidates open, then only applications for
  that position are shown, ranked by match, with lifecycle-valid actions.
- Given the same external organization role is posted repeatedly, when the
  command retries, then the deterministic RefSure job is reused and candidate
  counters are not reset.

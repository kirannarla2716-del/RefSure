import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
  planExpireApplication,
  planTransitionApplication,
} from "../../src/applications/commands";
import {
  allowedTransitions,
  assertTransitionAllowed,
} from "../../src/applications/policy";
import {ApplicationStatus, applicationStatuses} from "../../src/applications/types";
import {CommandError} from "../../src/shared/errors";

function application(status: ApplicationStatus) {
  return {
    id: "app-1",
    jobId: "job-1",
    seekerId: "seeker-1",
    providerId: "provider-1",
    status,
    matchScore: 75,
    version: 3,
  };
}

describe("application transition policy", () => {
  it("accepts every explicitly allowed transition", () => {
    for (const from of applicationStatuses) {
      for (const to of allowedTransitions(from)) {
        assert.doesNotThrow(() => assertTransitionAllowed(from, to));
      }
    }
  });

  it("rejects every transition not in the policy", () => {
    for (const from of applicationStatuses) {
      for (const to of applicationStatuses) {
        if (allowedTransitions(from).includes(to)) continue;
        assert.throws(
          () => assertTransitionAllowed(from, to),
          (error: unknown) =>
            error instanceof CommandError &&
            error.code === "failed-precondition",
        );
      }
    }
  });

  it("makes terminal statuses immutable", () => {
    for (const status of [
      "hired",
      "notSelected",
      "closed",
      "declined",
      "withdrawn",
      "expired",
    ] as const) {
      assert.deepEqual(allowedTransitions(status), []);
    }
  });
});

describe("transitionApplication command", () => {
  it("creates application, event, notification, and status counter mutations", () => {
    const plan = planTransitionApplication({
      actorId: "provider-1",
      input: {
        applicationId: "app-1",
        commandId: "command-1",
        expectedVersion: 3,
        toStatus: "shortlisted",
        note: "Strong candidate",
      },
      application: application("underReview"),
    });

    assert.equal(plan.status, "shortlisted");
    assert.equal(plan.idempotent, false);
    assert.equal(plan.version, 4);
    assert.equal(plan.mutations.length, 5);
    assert.equal(plan.mutations[0]?.path, "applications/app-1");
    assert.deepEqual(plan.mutations[0]?.data.version, 4);
    assert.match(plan.mutations[1]?.path ?? "", /^applicationEvents\/app-1_/);
    assert.match(plan.mutations[2]?.path ?? "", /^notifications\/app-1_/);
    assert.deepEqual(plan.mutations[3]?.data, {
      "applicationStatusCounts.underReview": {$increment: -1},
      "applicationStatusCounts.shortlisted": {$increment: 1},
    });
    assert.deepEqual(plan.mutations[4]?.data, {
      "byStatus.underReview": {$increment: -1},
      "byStatus.shortlisted": {$increment: 1},
    });
  });

  it("returns an idempotent no-op when the command event exists", () => {
    const plan = planTransitionApplication({
      actorId: "provider-1",
      input: {
        applicationId: "app-1",
        commandId: "stable-retry-key",
        expectedVersion: 3,
        toStatus: "shortlisted",
      },
      application: {...application("shortlisted"), version: 4},
      existingEvent: {
        toStatus: "shortlisted",
        expectedVersion: 3,
        resultVersion: 4,
      },
    });

    assert.equal(plan.idempotent, true);
    assert.equal(plan.version, 4);
    assert.deepEqual(plan.mutations, []);
  });

  it("rejects actors other than the owning provider", () => {
    assert.throws(
      () => planTransitionApplication({
        actorId: "another-provider",
        input: {
          applicationId: "app-1",
          commandId: "command-1",
          expectedVersion: 3,
          toStatus: "underReview",
        },
        application: application("pending"),
      }),
      (error: unknown) =>
        error instanceof CommandError &&
        error.code === "permission-denied",
    );
  });

  it("lets only the seeker withdraw an active request", () => {
    const plan = planTransitionApplication({
      actorId: "seeker-1",
      input: {
        applicationId: "app-1",
        commandId: "withdraw-1",
        expectedVersion: 3,
        toStatus: "withdrawn",
      },
      application: application("pending"),
    });
    assert.equal(plan.status, "withdrawn");
    assert.throws(
      () => planTransitionApplication({
        actorId: "provider-1",
        input: {
          applicationId: "app-1",
          commandId: "withdraw-2",
          expectedVersion: 3,
          toStatus: "withdrawn",
        },
        application: application("pending"),
      }),
      (error: unknown) =>
        error instanceof CommandError && error.code === "permission-denied",
    );
  });

  it("requires and creates a referral receipt", () => {
    assert.throws(
      () => planTransitionApplication({
        actorId: "provider-1",
        input: {
          applicationId: "app-1",
          commandId: "refer-missing-receipt",
          expectedVersion: 3,
          toStatus: "referred",
        },
        application: application("shortlisted"),
      }),
      (error: unknown) =>
        error instanceof CommandError && error.code === "invalid-argument",
    );

    const plan = planTransitionApplication({
      actorId: "provider-1",
      input: {
        applicationId: "app-1",
        commandId: "refer-with-receipt",
        expectedVersion: 3,
        toStatus: "referred",
        receiptReference: "ATS-REF-123",
      },
      application: application("shortlisted"),
    });
    assert.equal(plan.mutations[0]?.data.referralReceiptId, "app-1");
    assert.deepEqual(plan.mutations[1], {
      path: "referralReceipts/app-1",
      mode: "create",
      data: {
        applicationId: "app-1",
        jobId: "job-1",
        seekerId: "seeker-1",
        providerId: "provider-1",
        reference: "ATS-REF-123",
        submittedAt: "$serverTimestamp",
        createdAt: "$serverTimestamp",
      },
    });
  });

  it("rejects command ID reuse for a different target status", () => {
    assert.throws(
      () => planTransitionApplication({
        actorId: "provider-1",
        input: {
          applicationId: "app-1",
          commandId: "reused-command",
          expectedVersion: 3,
          toStatus: "interview",
        },
        application: application("shortlisted"),
        existingEvent: {
          toStatus: "referred",
          expectedVersion: 3,
          resultVersion: 4,
        },
      }),
      (error: unknown) =>
        error instanceof CommandError &&
        error.code === "failed-precondition",
    );
  });

  it("rejects stale expectedVersion with conflict details", () => {
    assert.throws(
      () => planTransitionApplication({
        actorId: "provider-1",
        input: {
          applicationId: "app-1",
          commandId: "stale-command",
          expectedVersion: 2,
          toStatus: "shortlisted",
        },
        application: application("underReview"),
      }),
      (error: unknown) => {
        assert(error instanceof CommandError);
        assert.equal(error.code, "failed-precondition");
        assert.deepEqual(error.details, {
          reason: "version-conflict",
          expectedVersion: 2,
          actualVersion: 3,
        });
        return true;
      },
    );
  });

  it("rejects command reuse with a different expected version", () => {
    assert.throws(
      () => planTransitionApplication({
        actorId: "provider-1",
        input: {
          applicationId: "app-1",
          commandId: "reused-command",
          expectedVersion: 2,
          toStatus: "shortlisted",
        },
        application: application("underReview"),
        existingEvent: {
          toStatus: "shortlisted",
          expectedVersion: 1,
          resultVersion: 2,
        },
      }),
      (error: unknown) =>
        error instanceof CommandError &&
        error.code === "failed-precondition",
    );
  });
});

describe("referral request expiry", () => {
  it("expires an unanswered request and releases provider capacity", () => {
    const plan = planExpireApplication(application("pending"));
    assert.equal(plan.status, "expired");
    assert.equal(plan.version, 4);
    assert.ok(plan.mutations.some((mutation) =>
      mutation.path === "users/provider-1" &&
      mutation.data.activeReferralRequests != null));
    assert.ok(plan.mutations.some((mutation) =>
      mutation.path.startsWith("notifications/application-expired:")));
  });
});

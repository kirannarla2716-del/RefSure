import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
  gratitudeEligibleStatuses,
  gratitudeId,
  planGratitude,
} from "../../src/gratitude/domain";
import {CommandError} from "../../src/shared/errors";

const base = {
  seekerId: "seeker-1",
  seekerRole: "seeker",
  providerId: "provider-1",
  providerRole: "provider",
  eligibleRelationship: true,
};

describe("trusted gratitude", () => {
  it("accepts only referral-complete relationship statuses", () => {
    assert.deepEqual(
      [...gratitudeEligibleStatuses].sort(),
      ["hired", "interview", "referred"],
    );
  });

  it("uses deterministic uniqueness per seeker/provider relationship", () => {
    const first = planGratitude(base);
    const second = planGratitude(base);
    assert.equal(first.gratitudeId, gratitudeId("seeker-1", "provider-1"));
    assert.equal(first.gratitudeId, second.gratitudeId);
    assert.equal(first.idempotent, false);
  });

  it("returns an idempotent no-op for an existing matching gratitude", () => {
    const plan = planGratitude({
      ...base,
      eligibleRelationship: false,
      existing: {
        fromSeekerId: "seeker-1",
        toReferrerId: "provider-1",
      },
    });
    assert.equal(plan.idempotent, true);
  });

  it("rejects ineligible relationships, wrong roles, and self gratitude", () => {
    const cases = [
      {...base, eligibleRelationship: false},
      {...base, seekerRole: "provider"},
      {...base, providerRole: "seeker"},
      {...base, providerId: "seeker-1"},
    ];
    for (const input of cases) {
      assert.throws(
        () => planGratitude(input),
        (error: unknown) => error instanceof CommandError,
      );
    }
  });

  it("rejects deterministic ID collisions", () => {
    assert.throws(
      () => planGratitude({
        ...base,
        existing: {
          fromSeekerId: "another-seeker",
          toReferrerId: "provider-1",
        },
      }),
      (error: unknown) =>
        error instanceof CommandError &&
        error.code === "failed-precondition",
    );
  });
});

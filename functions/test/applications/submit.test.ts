import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {planSubmitApplication} from "../../src/applications/commands";
import {CommandError} from "../../src/shared/errors";
import {applicationId} from "../../src/shared/ids";

const job = {
  id: "job-1",
  providerId: "provider-1",
  status: "active",
  skills: ["dart", "flutter"],
  minExp: 2,
  maxExp: 5,
  location: "Bengaluru",
  workMode: "Hybrid",
};

const trustedMatch = {
  score: 72,
  band: "goodToGo",
  matchedSkills: ["dart"],
  missingSkills: ["flutter"],
  skillScore: 42,
  experienceScore: 20,
  locationScore: 10,
  computedAt: "$serverTimestamp" as const,
  source: "server" as const,
  algorithmVersion: 1 as const,
};

const provider = {
  id: "provider-1",
  role: "provider",
  availableForReferrals: true,
  weeklyReferralCapacity: 5,
  activeReferralRequests: 1,
};

describe("submitApplication command", () => {
  it("uses a deterministic application ID and creates all side effects", () => {
    const first = planSubmitApplication({
      seekerId: "seeker-1",
      input: {jobId: job.id},
      job,
      trustedMatch,
      provider,
    });
    const second = planSubmitApplication({
      seekerId: "seeker-1",
      input: {jobId: job.id},
      job,
      trustedMatch,
      provider,
    });

    assert.equal(first.applicationId, applicationId("seeker-1", "job-1"));
    assert.equal(first.applicationId, second.applicationId);
    assert.equal(first.status, "pending");
    assert.equal(first.version, 1);
    assert.equal(first.idempotent, false);
    assert.deepEqual(
      first.mutations.map((mutation) => mutation.path),
      [
        `applications/${first.applicationId}`,
        `applicationEvents/${first.applicationId}_submitted`,
        `notifications/${first.applicationId}_submitted`,
        "jobs/job-1",
        "users/seeker-1",
        "users/provider-1",
        "metrics/applications",
      ],
    );
  });

  it("derives strongMatch status from the score", () => {
    const plan = planSubmitApplication({
      seekerId: "seeker-1",
      input: {jobId: job.id},
      job,
      trustedMatch: {...trustedMatch, score: 80},
      provider,
    });

    assert.equal(plan.status, "strongMatch");
    const application = plan.mutations[0];
    assert.equal(application?.data.strongMatchFlag, true);
    assert.equal(application?.data.version, 1);
    assert.deepEqual(application?.data.matchReport, {
      ...trustedMatch,
      score: 80,
    });
  });

  it("returns an idempotent no-op for an existing matching application", () => {
    const id = applicationId("seeker-1", job.id);
    const plan = planSubmitApplication({
      seekerId: "seeker-1",
      input: {jobId: job.id},
      job,
      trustedMatch,
      provider,
      existing: {
        id,
        jobId: job.id,
        seekerId: "seeker-1",
        providerId: "provider-1",
        status: "underReview",
        matchScore: 55,
        version: 4,
      },
    });

    assert.equal(plan.idempotent, true);
    assert.equal(plan.status, "underReview");
    assert.equal(plan.version, 4);
    assert.deepEqual(plan.mutations, []);
  });

  it("rejects inactive jobs", () => {
    assert.throws(
      () => planSubmitApplication({
        seekerId: "seeker-1",
        input: {jobId: job.id},
        job: {...job, status: "closed"},
        trustedMatch,
        provider,
      }),
      (error: unknown) =>
        error instanceof CommandError &&
        error.code === "failed-precondition",
    );
  });

  it("does not accept a deterministic ID collision", () => {
    const id = applicationId("seeker-1", job.id);
    assert.throws(
      () => planSubmitApplication({
        seekerId: "seeker-1",
        input: {jobId: job.id},
        job,
        trustedMatch,
        provider,
        existing: {
          id,
          jobId: "another-job",
          seekerId: "seeker-1",
          providerId: "provider-1",
          status: "pending",
          matchScore: 50,
          version: 1,
        },
      }),
      (error: unknown) =>
        error instanceof CommandError &&
        error.code === "failed-precondition",
    );
  });

  it("increments only the canonical applicants job counter", () => {
    const plan = planSubmitApplication({
      seekerId: "seeker-1",
      input: {jobId: job.id},
      job,
      trustedMatch,
      provider,
    });
    const jobMutation = plan.mutations.find(
      (mutation) => mutation.path === "jobs/job-1",
    );
    assert.deepEqual(jobMutation?.data, {applicants: {$increment: 1}});
    assert.equal("applicationCount" in (jobMutation?.data ?? {}), false);
  });

  it("rejects unavailable and capacity-full referrers", () => {
    assert.throws(
      () => planSubmitApplication({
        seekerId: "seeker-1",
        input: {jobId: job.id},
        job,
        trustedMatch,
        provider: {...provider, availableForReferrals: false},
      }),
      (error: unknown) =>
        error instanceof CommandError &&
        error.code === "failed-precondition",
    );
    assert.throws(
      () => planSubmitApplication({
        seekerId: "seeker-1",
        input: {jobId: job.id},
        job,
        trustedMatch,
        provider: {...provider, activeReferralRequests: 5},
      }),
      (error: unknown) =>
        error instanceof CommandError && error.code === "resource-exhausted",
    );
  });
});

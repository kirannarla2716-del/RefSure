import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {CommandError} from "../../src/shared/errors";
import {
  assertSeekerRole,
  computeTrustedMatch,
} from "../../src/applications/trusted_match";

const seeker = {
  id: "seeker-1",
  role: "seeker",
  skills: ["Dart", "Flutter", "Firebase"],
  experience: 4,
  location: "Bengaluru",
};

const job = {
  id: "job-1",
  providerId: "provider-1",
  status: "active",
  skills: ["dart", "flutter", "typescript", "DART"],
  minExp: 3,
  maxExp: 5,
  location: "Bengaluru",
  workMode: "Hybrid",
};

describe("trusted application matching", () => {
  it("derives a deterministic server-owned snapshot from stored documents", () => {
    const report = computeTrustedMatch(seeker, job);

    assert.equal(report.source, "server");
    assert.equal(report.algorithmVersion, 1);
    assert.deepEqual(report.matchedSkills, ["dart", "flutter"]);
    assert.deepEqual(report.missingSkills, ["typescript"]);
    assert.equal(report.experienceScore, 20);
    assert.equal(report.locationScore, 10);
    assert.equal(report.computedAt, "$serverTimestamp");
  });

  it("uses a neutral skill score when a job has no skill data", () => {
    const report = computeTrustedMatch(seeker, {...job, skills: []});
    assert.equal(report.skillScore, 35);
  });

  it("accepts seekers and rejects provider role escalation", () => {
    assert.doesNotThrow(() => assertSeekerRole(seeker));
    assert.throws(
      () => assertSeekerRole({...seeker, role: "provider"}),
      (error: unknown) =>
        error instanceof CommandError &&
        error.code === "permission-denied",
    );
  });
});

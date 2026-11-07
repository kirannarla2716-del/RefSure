import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {buildPublicProfile} from "../../src/profiles/projection";
import type {PublicProfileProjection} from "../../src/profiles/projection";

const timestamp = {seconds: 123, nanoseconds: 0};

function serializedUser(): Record<string, unknown> {
  return {
    id: "client-controlled-id",
    role: "provider",
    name: "Alice Provider",
    headline: "Engineering leader",
    company: "Acme",
    verified: true,
    orgVerified: true,
    title: "Director",
    location: "Bengaluru",
    experience: 12,
    skills: ["Dart", "Leadership"],
    preferredRoles: ["Engineering Manager"],
    bio: "Public biography",
    photoUrl: "https://example.com/photo.jpg",
    email: "private@example.com",
    orgEmail: "alice@acme.example",
    resumeUrl: "https://private.example/resume.pdf",
    linkedinUrl: "https://linkedin.example/private",
    education: "Private education",
    noticePeriod: "30 days",
    expectedSalary: "private",
    activelyLooking: true,
    createdAt: timestamp,
    updatedAt: timestamp,
    lastActiveAt: timestamp,
    profileComplete: 95,
    referralsReceived: 2,
    referralsMade: 10,
    successfulReferrals: 4,
    totalJobsPosted: 8,
    successRate: 40,
    responseTime: "< 24h",
    avgResponseHours: 12,
    responseRate: 0.9,
    trustScore: 87,
    gratitudesReceived: 6,
    applicationsSubmitted: 0,
    applicationsReceived: 15,
    applicationStatusCounts: {pending: 3},
  };
}

describe("public profile projection", () => {
  it("maps the exact serialized shape and uses the document ID", () => {
    const projection = buildPublicProfile(
      "trusted-document-id",
      serializedUser(),
      {seconds: 999, nanoseconds: 0},
    );

    assert.equal(projection.id, "trusted-document-id");
    assert.equal(projection.role, "provider");
    assert.equal(projection.updatedAt, timestamp);
    assert.equal(projection.referralsMade, 10);
    assert.equal(projection.totalJobsPosted, 8);
    assert.deepEqual(projection.skills, ["Dart", "Leadership"]);
  });

  it("never projects private PII or server-internal application counters", () => {
    const projection = buildPublicProfile(
      "alice",
      serializedUser(),
      timestamp,
    );
    const keys = new Set(Object.keys(projection));

    for (const forbidden of [
      "email",
      "orgEmail",
      "resumeUrl",
      "linkedinUrl",
      "education",
      "noticePeriod",
      "expectedSalary",
      "activelyLooking",
      "applicationsSubmitted",
      "applicationsReceived",
      "applicationStatusCounts",
    ]) {
      assert.equal(keys.has(forbidden), false, forbidden);
    }
  });

  it("provides stable defaults for legacy private profiles", () => {
    const projectedAt = {seconds: 456, nanoseconds: 0};
    const projection: PublicProfileProjection = buildPublicProfile(
      "legacy",
      {id: "wrong", name: "Legacy"},
      projectedAt,
    );

    assert.equal(projection.id, "legacy");
    assert.equal(projection.role, "seeker");
    assert.equal(projection.name, "Legacy");
    assert.equal(projection.avgResponseHours, 48);
    assert.equal(projection.responseRate, 1);
    assert.equal(projection.updatedAt, projectedAt);
    assert.deepEqual(projection.skills, []);
  });
});

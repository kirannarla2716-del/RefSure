import assert from "node:assert/strict";
import test from "node:test";
import {
  requestOrganizationVerificationCommand,
  verifyOrganizationVerificationCommand,
} from "../../src/verification/commands";
import {OrganizationVerificationService} from "../../src/verification/service";
import {
  Challenge,
  IssueLimits,
  VerificationMailer,
  VerificationStore,
  VerifyOutcome,
} from "../../src/verification/types";
import {secureHashEquals} from "../../src/verification/otp_crypto";

class IntegrationStore implements VerificationStore {
  challenge?: Challenge;
  verifiedOrganization?: {domain: string; email: string; companyName: string};

  async issue(challenge: Challenge, _limits: IssueLimits, _now: Date) {
    this.challenge = structuredClone(challenge);
  }

  async verify(input: {
    challengeId: string;
    userId: string;
    email: string;
    candidateHash: string;
    organization: {domain: string; email: string; companyName: string};
    now: Date;
  }): Promise<VerifyOutcome> {
    if (
      !this.challenge ||
      this.challenge.id !== input.challengeId ||
      this.challenge.userId !== input.userId ||
      !secureHashEquals(this.challenge.otpHash, input.candidateHash)
    ) {
      return {status: "not-found"};
    }
    this.verifiedOrganization = input.organization;
    return {status: "verified"};
  }

  async revoke() {}
}

class IntegrationMailer implements VerificationMailer {
  otp?: string;

  async sendOrganizationOtp(input: {otp: string}) {
    this.otp = input.otp;
  }
}

function fixture() {
  const store = new IntegrationStore();
  const mailer = new IntegrationMailer();
  return {
    store,
    mailer,
    service: new OrganizationVerificationService(store, mailer, {
      hmacSecret: "integration-secret-with-at-least-32-characters",
      createId: () => "challenge-1",
      createOtp: () => "654321",
    }),
  };
}

test("callable commands require authenticated context", async () => {
  const {service} = fixture();
  await assert.rejects(
    () => requestOrganizationVerificationCommand(
      service,
      undefined,
      {email: "employee@acme.com"},
    ),
    {code: "unauthenticated"},
  );
});

test("callable request and verify integrate normalized organization data", async () => {
  const {service, store, mailer} = fixture();
  const issued = await requestOrganizationVerificationCommand(
    service,
    "user-1",
    {email: " Employee@Acme-Tech.COM "},
  );
  assert.equal(issued.success, true);
  assert.equal(issued.domain, "acme-tech.com");
  assert.equal(mailer.otp, "654321");

  const verified = await verifyOrganizationVerificationCommand(
    service,
    "user-1",
    {
      challengeId: issued.challengeId,
      email: "employee@acme-tech.com",
      code: "654321",
    },
  );
  assert.deepEqual(verified, {
    success: true,
    domain: "acme-tech.com",
    companyName: "Acme Tech",
  });
  assert.deepEqual(store.verifiedOrganization, {
    domain: "acme-tech.com",
    email: "employee@acme-tech.com",
    companyName: "Acme Tech",
  });
});

test("callable input rejects personal domains before issuing mail", async () => {
  const {service, mailer} = fixture();
  await assert.rejects(
    () => requestOrganizationVerificationCommand(
      service,
      "user-1",
      {email: "employee@gmail.com"},
    ),
    {code: "personal-email"},
  );
  assert.equal(mailer.otp, undefined);
});

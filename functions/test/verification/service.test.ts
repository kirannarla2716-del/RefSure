import assert from 'node:assert/strict';
import test from 'node:test';

import {
  OrganizationVerificationService,
} from '../../src/verification/service';
import {VerificationError} from '../../src/verification/domain';
import {secureHashEquals} from '../../src/verification/otp_crypto';
import type {
  Challenge,
  IssueLimits,
  VerificationMailer,
  VerificationStore,
  VerifyOutcome,
} from '../../src/verification/types';

class MemoryStore implements VerificationStore {
  challenges = new Map<string, Challenge>();
  issued: Date[] = [];

  async issue(challenge: Challenge, limits: IssueLimits, now: Date) {
    const recent = this.issued.filter(
      (date) => now.getTime() - date.getTime() < limits.windowMs,
    );
    if (recent.length >= limits.perUserWindow) {
      throw new VerificationError('rate-limited', 'Too many verification requests.');
    }
    const latest = recent.at(-1);
    if (latest && now.getTime() - latest.getTime() < limits.resendCooldownMs) {
      throw new VerificationError('cooldown', 'Wait before requesting another code.');
    }
    for (const existing of this.challenges.values()) {
      if (existing.userId === challenge.userId && !existing.consumedAt) {
        existing.revokedAt = now;
      }
    }
    this.issued.push(now);
    this.challenges.set(challenge.id, structuredClone(challenge));
  }

  async verify(input: {
    challengeId: string;
    userId: string;
    email: string;
    candidateHash: string;
    now: Date;
  }): Promise<VerifyOutcome> {
    const challenge = this.challenges.get(input.challengeId);
    if (!challenge || challenge.userId !== input.userId
        || challenge.email !== input.email) {
      return {status: 'not-found'};
    }
    if (challenge.consumedAt || challenge.revokedAt) return {status: 'replayed'};
    if (challenge.expiresAt <= input.now) {
      challenge.revokedAt = input.now;
      return {status: 'expired'};
    }
    if (!secureHashEquals(challenge.otpHash, input.candidateHash)) {
      challenge.attemptsRemaining -= 1;
      if (challenge.attemptsRemaining === 0) {
        challenge.revokedAt = input.now;
        return {status: 'exhausted'};
      }
      return {
        status: 'incorrect',
        attemptsRemaining: challenge.attemptsRemaining,
      };
    }
    challenge.consumedAt = input.now;
    return {status: 'verified'};
  }

  async revoke(challengeId: string, now: Date) {
    const challenge = this.challenges.get(challengeId);
    if (challenge) challenge.revokedAt = now;
  }
}

class MemoryMailer implements VerificationMailer {
  sent: Array<{email: string; otp: string}> = [];
  shouldFail = false;

  async sendOrganizationOtp(input: {email: string; otp: string}) {
    if (this.shouldFail) throw new Error('mail unavailable');
    this.sent.push(input);
  }
}

const secret = 'test-secret-that-is-at-least-32-characters-long';

function fixture(overrides = {}) {
  let now = new Date('2026-07-26T00:00:00Z');
  const store = new MemoryStore();
  const mailer = new MemoryMailer();
  const service = new OrganizationVerificationService(store, mailer, {
    hmacSecret: secret,
    now: () => now,
    createId: () => `challenge-${store.challenges.size + 1}`,
    createOtp: () => '123456',
    limits: {resendCooldownMs: 0},
    ...overrides,
  });
  return {
    store,
    mailer,
    service,
    advance: (milliseconds: number) => {
      now = new Date(now.getTime() + milliseconds);
    },
  };
}

test('issues only normalized organization email challenges without plaintext OTP', async () => {
  const {service, store, mailer} = fixture();
  const result = await service.issue('user-1', ' Engineer@Acme-Tech.COM ');
  assert.equal(result.domain, 'acme-tech.com');
  assert.equal(mailer.sent[0]?.otp, '123456');
  const stored = store.challenges.get(result.challengeId)!;
  assert.notEqual(stored.otpHash, '123456');
  assert.equal(JSON.stringify(stored).includes('123456'), false);
});

test('rejects personal and malformed email domains', async () => {
  const {service} = fixture();
  await assert.rejects(() => service.issue('user-1', 'person@gmail.com'), {
    code: 'personal-email',
  });
  await assert.rejects(() => service.issue('user-1', 'not-an-email'), {
    code: 'invalid-email',
  });
});

test('verifies once and rejects replay', async () => {
  const {service} = fixture();
  const issued = await service.issue('user-1', 'person@acme.com');
  const verified = await service.verify(
    'user-1',
    issued.challengeId,
    'person@acme.com',
    '123456',
  );
  assert.equal(verified.companyName, 'Acme');
  await assert.rejects(
    () => service.verify(
      'user-1',
      issued.challengeId,
      'person@acme.com',
      '123456',
    ),
    {code: 'replayed'},
  );
});

test('exhausts attempts and cannot recover with the correct code', async () => {
  const {service} = fixture({maxAttempts: 2});
  const issued = await service.issue('user-1', 'person@acme.com');
  await assert.rejects(
    () => service.verify('user-1', issued.challengeId, 'person@acme.com', '000000'),
    {code: 'incorrect-code'},
  );
  await assert.rejects(
    () => service.verify('user-1', issued.challengeId, 'person@acme.com', '000000'),
    {code: 'exhausted'},
  );
  await assert.rejects(
    () => service.verify('user-1', issued.challengeId, 'person@acme.com', '123456'),
    {code: 'replayed'},
  );
});

test('rejects expired challenges', async () => {
  const {service, advance} = fixture({ttlMs: 1000});
  const issued = await service.issue('user-1', 'person@acme.com');
  advance(1001);
  await assert.rejects(
    () => service.verify('user-1', issued.challengeId, 'person@acme.com', '123456'),
    {code: 'expired'},
  );
});

test('enforces request limits and revokes failed deliveries', async () => {
  const limited = fixture({
    limits: {
      perUserWindow: 1,
      perEmailWindow: 1,
      resendCooldownMs: 0,
    },
  });
  await limited.service.issue('user-1', 'person@acme.com');
  await assert.rejects(
    () => limited.service.issue('user-1', 'other@acme.com'),
    {code: 'rate-limited'},
  );

  const failed = fixture();
  failed.mailer.shouldFail = true;
  await assert.rejects(
    () => failed.service.issue('user-1', 'person@acme.com'),
    {code: 'delivery-failed'},
  );
  assert.ok([...failed.store.challenges.values()][0]?.revokedAt);
});

test('enforces resend cooldown independently of the hourly limit', async () => {
  const {service, advance} = fixture({
    limits: {
      perUserWindow: 5,
      perEmailWindow: 5,
      resendCooldownMs: 60_000,
    },
  });
  await service.issue('user-1', 'person@acme.com');
  await assert.rejects(
    () => service.issue('user-1', 'person@acme.com'),
    {code: 'cooldown'},
  );
  advance(60_001);
  await assert.doesNotReject(
    () => service.issue('user-1', 'person@acme.com'),
  );
});

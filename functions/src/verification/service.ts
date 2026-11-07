import {randomUUID} from 'node:crypto';

import {
  parseOrganizationEmail,
  VerificationError,
} from './domain';
import {generateOtp, hashOtp} from './otp_crypto';
import type {
  Challenge,
  IssueLimits,
  VerificationMailer,
  VerificationStore,
} from './types';

export type VerificationConfig = {
  hmacSecret: string;
  ttlMs?: number;
  maxAttempts?: number;
  limits?: Partial<IssueLimits>;
  now?: () => Date;
  createId?: () => string;
  createOtp?: () => string;
};

const defaultLimits: IssueLimits = {
  perUserWindow: 5,
  perEmailWindow: 5,
  windowMs: 60 * 60 * 1000,
  resendCooldownMs: 60 * 1000,
};

export class OrganizationVerificationService {
  private readonly store: VerificationStore;
  private readonly mailer: VerificationMailer;
  private readonly config: VerificationConfig;
  private readonly now: () => Date;
  private readonly createId: () => string;
  private readonly createOtp: () => string;
  private readonly ttlMs: number;
  private readonly maxAttempts: number;
  private readonly limits: IssueLimits;

  constructor(
    store: VerificationStore,
    mailer: VerificationMailer,
    config: VerificationConfig,
  ) {
    this.store = store;
    this.mailer = mailer;
    this.config = config;
    if (config.hmacSecret.length < 32) {
      throw new Error('OTP HMAC secret must contain at least 32 characters.');
    }
    this.now = config.now ?? (() => new Date());
    this.createId = config.createId ?? randomUUID;
    this.createOtp = config.createOtp ?? generateOtp;
    this.ttlMs = config.ttlMs ?? 10 * 60 * 1000;
    this.maxAttempts = config.maxAttempts ?? 5;
    this.limits = {...defaultLimits, ...config.limits};
  }

  async issue(userId: string, rawEmail: string) {
    if (!userId) {
      throw new VerificationError('unauthenticated', 'Sign in before verifying.');
    }
    const organization = parseOrganizationEmail(rawEmail);
    const now = this.now();
    const otp = this.createOtp();
    if (!/^\d{6}$/.test(otp)) {
      throw new Error('OTP generator must return exactly six digits.');
    }

    const challenge: Challenge = {
      id: this.createId(),
      userId,
      email: organization.email,
      domain: organization.domain,
      otpHash: '',
      createdAt: now,
      expiresAt: new Date(now.getTime() + this.ttlMs),
      attemptsRemaining: this.maxAttempts,
      consumedAt: null,
      revokedAt: null,
    };
    challenge.otpHash = hashOtp({
      secret: this.config.hmacSecret,
      challengeId: challenge.id,
      userId,
      email: challenge.email,
      otp,
    });

    await this.store.issue(challenge, this.limits, now);
    try {
      await this.mailer.sendOrganizationOtp({
        email: challenge.email,
        otp,
        expiresInMinutes: Math.ceil(this.ttlMs / 60_000),
      });
    } catch (error) {
      await this.store.revoke(challenge.id, this.now());
      throw new VerificationError(
        'delivery-failed',
        'The verification email could not be delivered. Try again later.',
      );
    }

    return {
      challengeId: challenge.id,
      email: challenge.email,
      domain: challenge.domain,
      expiresAt: challenge.expiresAt.toISOString(),
    };
  }

  async verify(
    userId: string,
    challengeId: string,
    rawEmail: string,
    rawOtp: string,
  ) {
    if (!userId) {
      throw new VerificationError('unauthenticated', 'Sign in before verifying.');
    }
    if (!challengeId) {
      throw new VerificationError('invalid-challenge', 'Request a new verification code.');
    }
    const organization = parseOrganizationEmail(rawEmail);
    const otp = rawOtp.trim();
    if (!/^\d{6}$/.test(otp)) {
      throw new VerificationError('invalid-code', 'Enter the six-digit verification code.');
    }

    const outcome = await this.store.verify({
      challengeId,
      userId,
      email: organization.email,
      candidateHash: hashOtp({
        secret: this.config.hmacSecret,
        challengeId,
        userId,
        email: organization.email,
        otp,
      }),
      organization: {
        domain: organization.domain,
        email: organization.email,
        companyName: organization.companyName,
      },
      now: this.now(),
    });

    if (outcome.status === 'verified') {
      return {
        domain: organization.domain,
        companyName: organization.companyName,
      };
    }
    if (outcome.status === 'incorrect') {
      throw new VerificationError(
        'incorrect-code',
        `Incorrect code. ${outcome.attemptsRemaining} attempts remaining.`,
      );
    }
    const messages: Record<string, string> = {
      expired: 'The verification code expired. Request a new one.',
      exhausted: 'Too many incorrect attempts. Request a new code.',
      'not-found': 'No matching verification request was found.',
      replayed: 'This verification code has already been used.',
    };
    throw new VerificationError(
      outcome.status,
      messages[outcome.status] ?? 'Verification failed.',
    );
  }
}

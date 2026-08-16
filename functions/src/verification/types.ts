export type Challenge = {
  id: string;
  userId: string;
  email: string;
  domain: string;
  otpHash: string;
  createdAt: Date;
  expiresAt: Date;
  attemptsRemaining: number;
  consumedAt: Date | null;
  revokedAt: Date | null;
};

export type IssueLimits = {
  perUserWindow: number;
  perEmailWindow: number;
  windowMs: number;
  resendCooldownMs: number;
};

export type VerifyOutcome =
  | {status: 'verified'}
  | {status: 'incorrect'; attemptsRemaining: number}
  | {status: 'expired' | 'exhausted' | 'not-found' | 'replayed'};

export type VerifiedOrganization = {
  domain: string;
  email: string;
  companyName: string;
};

export interface VerificationStore {
  issue(
    challenge: Challenge,
    limits: IssueLimits,
    now: Date,
  ): Promise<void>;

  verify(input: {
    challengeId: string;
    userId: string;
    email: string;
    candidateHash: string;
    organization: VerifiedOrganization;
    now: Date;
  }): Promise<VerifyOutcome>;

  revoke(challengeId: string, now: Date): Promise<void>;
}

export interface VerificationMailer {
  sendOrganizationOtp(input: {
    email: string;
    otp: string;
    expiresInMinutes: number;
  }): Promise<void>;
}

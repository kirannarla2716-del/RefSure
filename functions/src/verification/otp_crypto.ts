import {
  createHmac,
  randomInt,
  timingSafeEqual,
} from 'node:crypto';

export function generateOtp(): string {
  return randomInt(0, 1_000_000).toString().padStart(6, '0');
}

export function hashOtp(input: {
  secret: string;
  challengeId: string;
  userId: string;
  email: string;
  otp: string;
}): string {
  if (input.secret.length < 32) {
    throw new Error('OTP HMAC secret must contain at least 32 characters.');
  }
  return createHmac('sha256', input.secret)
    .update(`${input.challengeId}\n${input.userId}\n${input.email}\n${input.otp}`)
    .digest('hex');
}

export function secureHashEquals(expected: string, actual: string): boolean {
  const expectedBytes = Buffer.from(expected, 'hex');
  const actualBytes = Buffer.from(actual, 'hex');
  return expectedBytes.length === actualBytes.length
    && timingSafeEqual(expectedBytes, actualBytes);
}

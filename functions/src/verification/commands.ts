import {VerificationError} from "./domain";
import {OrganizationVerificationService} from "./service";

function inputRecord(data: unknown): Record<string, unknown> {
  if (data == null || typeof data !== "object" || Array.isArray(data)) {
    throw new VerificationError("invalid-argument", "Request data is required.");
  }
  return data as Record<string, unknown>;
}

function requiredString(
  value: unknown,
  field: string,
  maxLength: number,
): string {
  if (typeof value !== "string" || !value.trim() || value.length > maxLength) {
    throw new VerificationError(
      "invalid-argument",
      `${field} must be a non-empty string.`,
    );
  }
  return value.trim();
}

export async function requestOrganizationVerificationCommand(
  service: OrganizationVerificationService,
  userId: string | undefined,
  data: unknown,
) {
  if (!userId) {
    throw new VerificationError("unauthenticated", "Sign in is required.");
  }
  const input = inputRecord(data);
  const result = await service.issue(
    userId,
    requiredString(input.email, "email", 254),
  );
  return {
    success: true,
    challengeId: result.challengeId,
    domain: result.domain,
    expiresAt: result.expiresAt,
    message: "Verification code sent. Check your work inbox.",
  };
}

export async function verifyOrganizationVerificationCommand(
  service: OrganizationVerificationService,
  userId: string | undefined,
  data: unknown,
) {
  if (!userId) {
    throw new VerificationError("unauthenticated", "Sign in is required.");
  }
  const input = inputRecord(data);
  const result = await service.verify(
    userId,
    requiredString(input.challengeId, "challengeId", 128),
    requiredString(input.email, "email", 254),
    requiredString(input.code, "code", 6),
  );
  return {
    success: true,
    domain: result.domain,
    companyName: result.companyName,
  };
}

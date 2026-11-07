import {createHash} from "node:crypto";
import {CommandError} from "../shared/errors";

export const gratitudeEligibleStatuses = new Set([
  "referred",
  "interview",
  "hired",
]);

export function gratitudeId(seekerId: string, providerId: string): string {
  const hash = createHash("sha256")
    .update(`${seekerId}\u001f${providerId}`)
    .digest("hex")
    .slice(0, 32);
  return `gratitude_${hash}`;
}

export interface GratitudePlan {
  gratitudeId: string;
  idempotent: boolean;
}

export function planGratitude(params: {
  seekerId: string;
  seekerRole: string;
  providerId: string;
  providerRole: string;
  eligibleRelationship: boolean;
  existing?: {fromSeekerId?: unknown; toReferrerId?: unknown};
}): GratitudePlan {
  const {
    seekerId,
    seekerRole,
    providerId,
    providerRole,
    eligibleRelationship,
    existing,
  } = params;
  if (seekerId === providerId) {
    throw new CommandError(
      "failed-precondition",
      "You cannot send gratitude to yourself.",
    );
  }
  if (seekerRole !== "seeker") {
    throw new CommandError(
      "permission-denied",
      "Only seekers can send gratitude.",
    );
  }
  if (providerRole !== "provider") {
    throw new CommandError(
      "failed-precondition",
      "Gratitude can only be sent to a provider.",
    );
  }
  const id = gratitudeId(seekerId, providerId);
  if (existing) {
    if (
      existing.fromSeekerId !== seekerId ||
      existing.toReferrerId !== providerId
    ) {
      throw new CommandError(
        "failed-precondition",
        "The deterministic gratitude ID is already in use.",
      );
    }
    return {gratitudeId: id, idempotent: true};
  }
  if (!eligibleRelationship) {
    throw new CommandError(
      "failed-precondition",
      "Gratitude requires a completed referral relationship.",
    );
  }
  return {gratitudeId: id, idempotent: false};
}

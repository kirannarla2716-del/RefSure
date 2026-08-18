import {CommandError, optionalString, requireString} from "../shared/errors";

export const adminActions = [
  "activate",
  "deactivate",
  "remove",
  "grantAccess",
  "onboardingException",
] as const;
export type AdminAction = (typeof adminActions)[number];

export interface AdminCommand {
  userId: string;
  action: AdminAction;
  commandId: string;
  additionalAccess: string[];
  exceptionReason?: string;
  exceptionUntil?: Date;
}

export function parseAdminCommand(raw: unknown): AdminCommand {
  const input = raw as Record<string, unknown> | null;
  const userId = requireString(input?.userId, "userId");
  const actionValue = requireString(input?.action, "action");
  if (!adminActions.includes(actionValue as AdminAction)) {
    throw new CommandError("invalid-argument", "Unsupported admin action.");
  }
  const action = actionValue as AdminAction;
  const commandId = requireString(input?.commandId, "commandId");
  const rawAccess = input?.additionalAccess ?? [];
  if (!Array.isArray(rawAccess) || rawAccess.some((item) =>
    typeof item !== "string" || item.trim().length === 0)) {
    throw new CommandError(
      "invalid-argument",
      "additionalAccess must contain permission names.",
    );
  }
  const additionalAccess = [...new Set(rawAccess.map((item) =>
    String(item).trim()))].sort();
  const exceptionReason = optionalString(
    input?.exceptionReason,
    "exceptionReason",
    300,
  );
  const rawUntil = input?.exceptionUntil;
  const exceptionUntil = typeof rawUntil === "string" ? new Date(rawUntil) : undefined;
  if (action === "onboardingException" &&
      (!exceptionReason || !exceptionUntil || Number.isNaN(exceptionUntil.valueOf()) ||
       exceptionUntil <= new Date())) {
    throw new CommandError(
      "invalid-argument",
      "A reason and future exceptionUntil are required.",
    );
  }
  return {
    userId,
    action,
    commandId,
    additionalAccess,
    exceptionReason,
    exceptionUntil,
  };
}

export function assertAdmin(actorId: string | undefined, adminClaim: unknown): string {
  if (!actorId) throw new CommandError("unauthenticated", "Sign in is required.");
  if (adminClaim !== true) {
    throw new CommandError("permission-denied", "Administrator access is required.");
  }
  return actorId;
}

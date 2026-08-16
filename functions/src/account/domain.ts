import {createHash} from "node:crypto";
import {CommandError} from "../shared/errors";

export type AccountRole = "seeker" | "provider";

export interface RoleChangePlan {
  role: AccountRole;
  idempotent: boolean;
  eventId: string;
}

export function parseAccountRole(value: unknown): AccountRole {
  if (value !== "seeker" && value !== "provider") {
    throw new CommandError(
      "invalid-argument",
      "role must be seeker or provider.",
    );
  }
  return value;
}

export function roleChangeEventId(uid: string, commandId: string): string {
  const hash = createHash("sha256")
    .update(`${uid}\u001f${commandId}`)
    .digest("hex")
    .slice(0, 24);
  return `role_${uid}_${hash}`;
}

export function planRoleChange(params: {
  uid: string;
  currentRole: AccountRole;
  targetRole: AccountRole;
  commandId: string;
  existingEventRole?: string;
}): RoleChangePlan {
  const {uid, currentRole, targetRole, commandId, existingEventRole} = params;
  const eventId = roleChangeEventId(uid, commandId);
  if (existingEventRole != null && existingEventRole !== targetRole) {
    throw new CommandError(
      "failed-precondition",
      "commandId was already used for a different role change.",
    );
  }
  if (existingEventRole === targetRole || currentRole === targetRole) {
    return {role: targetRole, idempotent: true, eventId};
  }
  return {role: targetRole, idempotent: false, eventId};
}

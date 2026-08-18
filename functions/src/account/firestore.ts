import {FieldValue, Firestore} from "firebase-admin/firestore";
import {buildPublicProfile} from "../profiles/projection";
import {CommandError, requireString} from "../shared/errors";
import {
  AccountRole,
  parseAccountRole,
  planRoleChange,
  roleChangeEventId,
} from "./domain";

function currentRole(value: unknown): AccountRole {
  if (value === "seeker" || value === "provider") return value;
  throw new CommandError(
    "failed-precondition",
    "The current account role is invalid.",
  );
}

export async function changeRoleTransaction(
  firestore: Firestore,
  uid: string,
  rawInput: unknown,
): Promise<{role: AccountRole; idempotent: boolean}> {
  const input = rawInput as Record<string, unknown> | null;
  const targetRole = parseAccountRole(input?.role);
  const commandId = requireString(input?.commandId, "commandId");
  const eventId = roleChangeEventId(uid, commandId);

  return firestore.runTransaction(async (transaction) => {
    const userRef = firestore.doc(`users/${uid}`);
    const publicRef = firestore.doc(`publicProfiles/${uid}`);
    const eventRef = firestore.doc(`accountEvents/${eventId}`);
    const [userDocument, eventDocument] = await transaction.getAll(
      userRef,
      eventRef,
    );
    if (!userDocument?.exists) {
      throw new CommandError("not-found", "User profile not found.");
    }
    if (!eventDocument) {
      throw new CommandError("not-found", "Role audit resource not found.");
    }

    const userData = userDocument.data() ?? {};
    const plan = planRoleChange({
      uid,
      currentRole: currentRole(userData.role),
      targetRole,
      commandId,
      existingEventRole: eventDocument.exists
        ? eventDocument.data()?.toRole as string | undefined
        : undefined,
    });
    if (plan.idempotent) {
      return {role: plan.role, idempotent: true};
    }

    const updatedAt = FieldValue.serverTimestamp();
    const projection = buildPublicProfile(
      uid,
      {...userData, role: targetRole, updatedAt},
      updatedAt,
    );
    transaction.update(userRef, {role: targetRole, updatedAt});
    transaction.set(publicRef, projection);
    transaction.create(eventRef, {
      id: eventId,
      type: "roleChanged",
      actorId: uid,
      fromRole: userData.role,
      toRole: targetRole,
      createdAt: updatedAt,
    });
    return {role: plan.role, idempotent: false};
  });
}

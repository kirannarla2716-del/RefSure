import {getAuth} from "firebase-admin/auth";
import {FieldValue, Firestore, Timestamp} from "firebase-admin/firestore";
import {CommandError} from "../shared/errors";
import {AdminCommand} from "./domain";

export async function listAdminUsers(firestore: Firestore): Promise<unknown[]> {
  const snapshot = await firestore.collection("users").orderBy("createdAt", "desc").limit(100).get();
  return snapshot.docs.map((document) => {
    const data = document.data();
    const until = data.onboardingExceptionUntil;
    return {
      id: document.id,
      name: data.name ?? "",
      email: data.email ?? "",
      role: data.role ?? "seeker",
      disabled: data.adminDisabled === true,
      additionalAccess: Array.isArray(data.additionalAccess) ? data.additionalAccess : [],
      onboardingExceptionUntil: until instanceof Timestamp ? until.toDate().toISOString() : null,
      onboardingExceptionReason: data.onboardingExceptionReason ?? null,
    };
  });
}

export async function manageAdminUser(
  firestore: Firestore,
  actorId: string,
  command: AdminCommand,
): Promise<{idempotent: boolean}> {
  if (actorId === command.userId && ["deactivate", "remove"].includes(command.action)) {
    throw new CommandError("failed-precondition", "Administrators cannot disable their own account.");
  }
  const userRef = firestore.doc(`users/${command.userId}`);
  const publicProfileRef = firestore.doc(`publicProfiles/${command.userId}`);
  const eventRef = firestore.doc(`adminEvents/${command.commandId}`);
  const result = await firestore.runTransaction(async (transaction) => {
    const [user, event] = await transaction.getAll(userRef, eventRef);
    if (!user?.exists) throw new CommandError("not-found", "User profile not found.");
    if (event?.exists) return {idempotent: true};
    const patch: Record<string, unknown> = {updatedAt: FieldValue.serverTimestamp()};
    if (command.action === "activate") patch.adminDisabled = false;
    if (command.action === "deactivate") patch.adminDisabled = true;
    if (command.action === "grantAccess") patch.additionalAccess = command.additionalAccess;
    if (command.action === "onboardingException") {
      patch.onboardingExceptionReason = command.exceptionReason;
      patch.onboardingExceptionUntil = Timestamp.fromDate(command.exceptionUntil!);
    }
    if (command.action === "remove") {
      transaction.delete(userRef);
      transaction.delete(publicProfileRef);
    } else {
      transaction.update(userRef, patch);
    }
    transaction.create(eventRef, {
      actorId,
      subjectId: command.userId,
      action: command.action,
      details: {
        additionalAccess: command.additionalAccess,
        exceptionReason: command.exceptionReason ?? null,
        exceptionUntil: command.exceptionUntil ? Timestamp.fromDate(command.exceptionUntil) : null,
      },
      createdAt: FieldValue.serverTimestamp(),
    });
    return {idempotent: false};
  });
  if (!result.idempotent) {
    if (command.action === "activate") await getAuth().updateUser(command.userId, {disabled: false});
    if (command.action === "deactivate") await getAuth().updateUser(command.userId, {disabled: true});
    if (command.action === "remove") await getAuth().deleteUser(command.userId);
  }
  return result;
}

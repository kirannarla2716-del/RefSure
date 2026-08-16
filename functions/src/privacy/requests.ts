import {FieldValue, Firestore} from "firebase-admin/firestore";
import {CommandError, requireString} from "../shared/errors";

const requestTypes = new Set(["data_export", "account_deletion"]);

export interface PrivacyRequestInput {
  type: string;
  commandId: string;
}

export function parsePrivacyRequest(raw: unknown): PrivacyRequestInput {
  const value = raw as Record<string, unknown> | null;
  const type = requireString(value?.type, "type");
  if (!requestTypes.has(type)) {
    throw new CommandError("invalid-argument", "Invalid privacy request type.");
  }
  const commandId = requireString(value?.commandId, "commandId");
  if (commandId.length > 100 || commandId.includes("/")) {
    throw new CommandError("invalid-argument", "Invalid commandId.");
  }
  return {type, commandId};
}

export async function requestPrivacyAction(
  firestore: Firestore,
  userId: string,
  rawInput: unknown,
): Promise<{requestId: string; status: string; idempotent: boolean}> {
  const input = parsePrivacyRequest(rawInput);
  const requestId = `${userId}_${input.type}`;
  const requestRef = firestore.doc(`privacyRequests/${requestId}`);
  const eventRef = firestore.doc(`privacyEvents/${input.commandId}`);

  return firestore.runTransaction(async (transaction) => {
    const [request, event] = await transaction.getAll(requestRef, eventRef);
    if (event?.exists) {
      const previous = event.data();
      if (previous?.userId !== userId || previous?.type !== input.type) {
        throw new CommandError(
          "already-exists",
          "commandId was already used for another privacy request.",
        );
      }
      return {requestId, status: "pending", idempotent: true};
    }
    if (request?.data()?.status === "pending") {
      return {requestId, status: "pending", idempotent: true};
    }

    transaction.set(requestRef, {
      userId,
      type: input.type,
      status: "pending",
      requestedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.create(eventRef, {
      requestId,
      userId,
      type: input.type,
      action: "requested",
      createdAt: FieldValue.serverTimestamp(),
    });
    return {requestId, status: "pending", idempotent: false};
  });
}

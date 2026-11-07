import {FieldValue, Firestore, Timestamp} from "firebase-admin/firestore";
import {CommandError, optionalString, requireString} from "../shared/errors";

const decisions = new Set(["resolved", "dismissed", "escalated"]);

export interface ModerationInput {
  reportId: string;
  decision: string;
  note: string;
  commandId: string;
}

export function parseModerationInput(raw: unknown): ModerationInput {
  const value = raw as Record<string, unknown> | null;
  const reportId = requireString(value?.reportId, "reportId");
  const decision = requireString(value?.decision, "decision");
  if (!decisions.has(decision)) {
    throw new CommandError("invalid-argument", "Invalid moderation decision.");
  }
  const note = optionalString(value?.note, "note", 1000);
  if (!note) {
    throw new CommandError("invalid-argument", "A moderation note is required.");
  }
  const commandId = requireString(value?.commandId, "commandId");
  if (commandId.length > 100 || commandId.includes("/")) {
    throw new CommandError("invalid-argument", "Invalid commandId.");
  }
  return {reportId, decision, note, commandId};
}

export async function listSafetyReports(
  firestore: Firestore,
  status: unknown,
): Promise<unknown[]> {
  const normalized = typeof status === "string" ? status : "open";
  if (!["open", "resolved", "dismissed", "escalated"].includes(normalized)) {
    throw new CommandError("invalid-argument", "Invalid report status.");
  }
  const snapshot = await firestore.collection("safetyReports")
    .where("status", "==", normalized)
    .orderBy("createdAt", "desc")
    .limit(100)
    .get();
  return snapshot.docs.map((document) => {
    const data = document.data();
    const createdAt = data.createdAt;
    return {
      id: document.id,
      reporterId: data.reporterId ?? "",
      targetId: data.targetId ?? "",
      category: data.category ?? "other",
      details: data.details ?? "",
      contextId: data.contextId ?? null,
      status: data.status ?? "open",
      createdAt: createdAt instanceof Timestamp ?
        createdAt.toDate().toISOString() : null,
    };
  });
}

export async function reviewSafetyReport(
  firestore: Firestore,
  actorId: string,
  rawInput: unknown,
): Promise<{idempotent: boolean}> {
  const input = parseModerationInput(rawInput);
  const reportRef = firestore.doc(`safetyReports/${input.reportId}`);
  const eventRef = firestore.doc(`moderationEvents/${input.commandId}`);
  return firestore.runTransaction(async (transaction) => {
    const [report, event] = await transaction.getAll(reportRef, eventRef);
    if (!report?.exists) {
      throw new CommandError("not-found", "Safety report was not found.");
    }
    if (event?.exists) {
      const previous = event.data();
      if (previous?.reportId !== input.reportId ||
          previous?.decision !== input.decision ||
          previous?.actorId !== actorId) {
        throw new CommandError(
          "already-exists",
          "commandId was already used for another moderation action.",
        );
      }
      return {idempotent: true};
    }
    transaction.update(reportRef, {
      status: input.decision,
      moderationNote: input.note,
      reviewedBy: actorId,
      reviewedAt: FieldValue.serverTimestamp(),
    });
    transaction.create(eventRef, {
      reportId: input.reportId,
      actorId,
      decision: input.decision,
      note: input.note,
      createdAt: FieldValue.serverTimestamp(),
    });
    return {idempotent: false};
  });
}

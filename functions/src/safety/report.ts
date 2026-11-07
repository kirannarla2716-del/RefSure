import {FieldValue, Firestore, Timestamp} from "firebase-admin/firestore";
import {CommandError, optionalString, requireString} from "../shared/errors";

const categories = new Set([
  "spam",
  "harassment",
  "fraud",
  "inappropriate",
  "other",
]);

export interface SafetyReportInput {
  targetId: string;
  category: string;
  details: string;
  contextId?: string;
  commandId: string;
}

export function parseSafetyReport(raw: unknown): SafetyReportInput {
  const value = raw as Record<string, unknown> | null;
  const targetId = requireString(value?.targetId, "targetId");
  if (targetId.includes("/")) {
    throw new CommandError("invalid-argument", "Invalid targetId.");
  }
  const category = requireString(value?.category, "category");
  if (!categories.has(category)) {
    throw new CommandError("invalid-argument", "Invalid report category.");
  }
  const details = optionalString(value?.details, "details", 1000);
  if (!details) {
    throw new CommandError("invalid-argument", "Report details are required.");
  }
  const commandId = requireString(value?.commandId, "commandId");
  if (commandId.length > 100 || commandId.includes("/")) {
    throw new CommandError("invalid-argument", "Invalid commandId.");
  }
  return {
    targetId,
    category,
    details,
    contextId: optionalString(value?.contextId, "contextId", 200),
    commandId,
  };
}

export async function reportUserTransaction(
  firestore: Firestore,
  reporterId: string,
  rawInput: unknown,
): Promise<{reportId: string; idempotent: boolean}> {
  const input = parseSafetyReport(rawInput);
  if (input.targetId === reporterId) {
    throw new CommandError("invalid-argument", "You cannot report yourself.");
  }
  const reportId = `${reporterId}:${input.commandId}`;
  const hourKey = new Date().toISOString().slice(0, 13).replace(/[-T:]/g, "");
  const rateId = `${reporterId}:${hourKey}`;
  return firestore.runTransaction(async (transaction) => {
    const targetRef = firestore.doc(`users/${input.targetId}`);
    const reportRef = firestore.doc(`safetyReports/${reportId}`);
    const rateRef = firestore.doc(`safetyRateLimits/${rateId}`);
    const [target, existing, rate] = await transaction.getAll(
      targetRef,
      reportRef,
      rateRef,
    );
    if (!target?.exists) {
      throw new CommandError("not-found", "Reported user was not found.");
    }
    if (existing?.exists) return {reportId, idempotent: true};
    const count = Number(rate?.data()?.count ?? 0);
    if (count >= 5) {
      throw new CommandError(
        "resource-exhausted",
        "Too many reports. Please try again later.",
      );
    }
    const now = FieldValue.serverTimestamp();
    transaction.create(reportRef, {
      id: reportId,
      reporterId,
      targetId: input.targetId,
      category: input.category,
      details: input.details,
      contextId: input.contextId ?? null,
      status: "open",
      createdAt: now,
    });
    transaction.set(rateRef, {
      reporterId,
      count: FieldValue.increment(1),
      expiresAt: Timestamp.fromMillis(Date.now() + 2 * 60 * 60 * 1000),
      updatedAt: now,
    }, {merge: true});
    return {reportId, idempotent: false};
  });
}

import {
  FieldValue,
  Firestore,
  Timestamp,
  Transaction,
} from "firebase-admin/firestore";
import {CommandError, optionalString, requireString} from "../shared/errors";
import {applicationId, transitionEventId} from "../shared/ids";
import {
  planExpireApplication,
  planSubmitApplication,
  planTransitionApplication,
} from "./commands";
import {parseStatus} from "./policy";
import {assertSeekerRole, computeTrustedMatch} from "./trusted_match";
import {
  ApplicationSnapshot,
  CommandMutation,
  CommandPlan,
  JobSnapshot,
  ProviderCapacitySnapshot,
  SeekerSnapshot,
  SubmitApplicationInput,
  TransitionApplicationInput,
} from "./types";

function parseSubmitInput(data: unknown): SubmitApplicationInput {
  const value = data as Record<string, unknown> | null;
  if (value?.matchScore != null || value?.matchReport != null) {
    throw new CommandError(
      "invalid-argument",
      "Match data is computed by the server.",
    );
  }
  return {
    jobId: requireString(value?.jobId, "jobId"),
  };
}

function requireVersion(value: unknown): number {
  if (!Number.isInteger(value) || (value as number) < 1) {
    throw new CommandError(
      "invalid-argument",
      "expectedVersion must be a positive integer.",
    );
  }
  return value as number;
}

function parseTransitionInput(data: unknown): TransitionApplicationInput {
  const value = data as Record<string, unknown> | null;
  return {
    applicationId: requireString(value?.applicationId, "applicationId"),
    commandId: requireString(value?.commandId, "commandId"),
    expectedVersion: requireVersion(value?.expectedVersion),
    toStatus: parseStatus(value?.toStatus),
    note: optionalString(value?.note, "note", 2000),
    receiptReference: optionalString(
      value?.receiptReference,
      "receiptReference",
      200,
    ),
  };
}

function applicationSnapshot(
  id: string,
  data: FirebaseFirestore.DocumentData,
): ApplicationSnapshot {
  return {
    id,
    jobId: requireString(data.jobId, "application.jobId"),
    seekerId: requireString(data.seekerId, "application.seekerId"),
    providerId: requireString(data.providerId, "application.providerId"),
    status: parseStatus(data.status),
    matchScore: typeof data.matchScore === "number" ? data.matchScore : 0,
    version: Number.isInteger(data.version) && data.version > 0 ?
      data.version :
      1,
  };
}

function materialize(value: unknown): unknown {
  if (value === "$serverTimestamp") return FieldValue.serverTimestamp();
  if (Array.isArray(value)) return value.map(materialize);
  if (value != null && typeof value === "object") {
    const record = value as Record<string, unknown>;
    if (
      Object.keys(record).length === 1 &&
      typeof record.$increment === "number"
    ) {
      return FieldValue.increment(record.$increment);
    }
    if (
      Object.keys(record).length === 1 &&
      typeof record.$timestampAfterHours === "number"
    ) {
      return Timestamp.fromMillis(
        Date.now() + record.$timestampAfterHours * 60 * 60 * 1000,
      );
    }
    return Object.fromEntries(
      Object.entries(record).map(([key, item]) => [key, materialize(item)]),
    );
  }
  return value;
}

function applyMutation(
  firestore: Firestore,
  transaction: Transaction,
  mutation: CommandMutation,
): void {
  const reference = firestore.doc(mutation.path);
  const data = materialize(mutation.data) as FirebaseFirestore.DocumentData;
  switch (mutation.mode) {
  case "create":
    transaction.create(reference, data);
    break;
  case "update":
    transaction.update(reference, data);
    break;
  case "set":
    transaction.set(reference, data, {merge: true});
    break;
  }
}

export function applyPlan(
  firestore: Firestore,
  transaction: Transaction,
  plan: CommandPlan,
): void {
  for (const mutation of plan.mutations) {
    applyMutation(firestore, transaction, mutation);
  }
}

export async function expireDueApplications(
  firestore: Firestore,
  now: Timestamp = Timestamp.now(),
): Promise<number> {
  const due = await firestore.collection("applications")
    .where("status", "in", ["pending", "strongMatch", "needsReview", "accepted"])
    .where("responseDueAt", "<=", now)
    .limit(200)
    .get();
  let expired = 0;
  for (const candidate of due.docs) {
    const changed = await firestore.runTransaction(async (transaction) => {
      const current = await transaction.get(candidate.ref);
      if (!current.exists) return false;
      const data = current.data() ?? {};
      const responseDueAt = data.responseDueAt as Timestamp | undefined;
      if (responseDueAt == null || responseDueAt.toMillis() > now.toMillis()) {
        return false;
      }
      const snapshot = applicationSnapshot(current.id, data);
      if (!["pending", "strongMatch", "needsReview", "accepted"]
        .includes(snapshot.status)) {
        return false;
      }
      applyPlan(firestore, transaction, planExpireApplication(snapshot));
      return true;
    });
    if (changed) expired += 1;
  }
  return expired;
}

export async function submitApplicationTransaction(
  firestore: Firestore,
  seekerId: string,
  rawInput: unknown,
): Promise<CommandPlan> {
  const input = parseSubmitInput(rawInput);
  return firestore.runTransaction(async (transaction) => {
    const id = applicationId(seekerId, input.jobId);
    const jobRef = firestore.doc(`jobs/${input.jobId}`);
    const seekerRef = firestore.doc(`users/${seekerId}`);
    const applicationRef = firestore.doc(`applications/${id}`);
    const [jobDocument, seekerDocument, applicationDocument] =
      await transaction.getAll(
      jobRef,
      seekerRef,
      applicationRef,
    );
    if (!jobDocument || !seekerDocument || !applicationDocument) {
      throw new CommandError("not-found", "Application resources not found.");
    }
    if (!jobDocument.exists) {
      throw new CommandError("not-found", "Job not found.");
    }
    if (!seekerDocument.exists) {
      throw new CommandError("not-found", "Seeker profile not found.");
    }
    const jobData = jobDocument.data() ?? {};
    const seekerData = seekerDocument.data() ?? {};
    const job: JobSnapshot = {
      id: jobDocument.id,
      providerId: requireString(jobData.providerId, "job.providerId"),
      status: typeof jobData.status === "string" ? jobData.status : "active",
      skills: Array.isArray(jobData.skills) ?
        jobData.skills.filter((value): value is string =>
          typeof value === "string") :
        [],
      minExp: typeof jobData.minExp === "number" ? jobData.minExp : 0,
      maxExp: typeof jobData.maxExp === "number" ? jobData.maxExp : 100,
      location: typeof jobData.location === "string" ? jobData.location : "",
      workMode: typeof jobData.workMode === "string" ? jobData.workMode : "",
    };
    const providerDocument = await transaction.get(
      firestore.doc(`users/${job.providerId}`),
    );
    if (!providerDocument.exists) {
      throw new CommandError("not-found", "Referrer profile not found.");
    }
    const providerData = providerDocument.data() ?? {};
    const provider: ProviderCapacitySnapshot = {
      id: providerDocument.id,
      role: typeof providerData.role === "string" ? providerData.role : "",
      availableForReferrals: providerData.availableForReferrals !== false,
      weeklyReferralCapacity:
        typeof providerData.weeklyReferralCapacity === "number" ?
          Math.max(0, providerData.weeklyReferralCapacity) :
          5,
      activeReferralRequests:
        typeof providerData.activeReferralRequests === "number" ?
          Math.max(0, providerData.activeReferralRequests) :
          0,
    };
    const seeker: SeekerSnapshot = {
      id: seekerId,
      role: typeof seekerData.role === "string" ? seekerData.role : "",
      skills: Array.isArray(seekerData.skills) ?
        seekerData.skills.filter((value): value is string =>
          typeof value === "string") :
        [],
      experience: typeof seekerData.experience === "number" ?
        seekerData.experience :
        0,
      location: typeof seekerData.location === "string" ?
        seekerData.location :
        "",
    };
    assertSeekerRole(seeker);
    const existing = applicationDocument.exists
      ? applicationSnapshot(id, applicationDocument.data() ?? {})
      : undefined;
    const trustedMatch = computeTrustedMatch(seeker, job);
    const plan = planSubmitApplication({
      seekerId,
      input,
      job,
      trustedMatch,
      provider,
      existing,
    });
    applyPlan(firestore, transaction, plan);
    return plan;
  });
}

export async function transitionApplicationTransaction(
  firestore: Firestore,
  actorId: string,
  rawInput: unknown,
): Promise<CommandPlan> {
  const input = parseTransitionInput(rawInput);
  return firestore.runTransaction(async (transaction) => {
    const applicationRef = firestore.doc(
      `applications/${input.applicationId}`,
    );
    const eventRef = firestore.doc(
      `applicationEvents/${transitionEventId(
        input.applicationId,
        input.commandId,
      )}`,
    );
    const [applicationDocument, eventDocument] = await transaction.getAll(
      applicationRef,
      eventRef,
    );
    if (!applicationDocument || !eventDocument) {
      throw new CommandError("not-found", "Application resources not found.");
    }
    if (!applicationDocument.exists) {
      throw new CommandError("not-found", "Application not found.");
    }
    const application = applicationSnapshot(
      applicationDocument.id,
      applicationDocument.data() ?? {},
    );
    const plan = planTransitionApplication({
      actorId,
      input,
      application,
      existingEvent: eventDocument.exists ? {
        toStatus: eventDocument.data()?.toStatus as string | undefined,
        expectedVersion:
          eventDocument.data()?.expectedVersion as number | undefined,
        resultVersion:
          eventDocument.data()?.resultVersion as number | undefined,
      } : undefined,
    });
    applyPlan(firestore, transaction, plan);
    return plan;
  });
}

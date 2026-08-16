import {FieldValue, Firestore} from "firebase-admin/firestore";
import {buildPublicProfile} from "../profiles/projection";
import {CommandError, optionalString, requireString} from "../shared/errors";
import {
  gratitudeEligibleStatuses,
  gratitudeId,
  planGratitude,
} from "./domain";

export async function sendGratitudeTransaction(
  firestore: Firestore,
  seekerId: string,
  rawInput: unknown,
): Promise<{gratitudeId: string; idempotent: boolean}> {
  const input = rawInput as Record<string, unknown> | null;
  const providerId = requireString(input?.providerId, "providerId");
  const message = optionalString(input?.message, "message", 500);
  if (!message) {
    throw new CommandError("invalid-argument", "message is required.");
  }
  const id = gratitudeId(seekerId, providerId);

  return firestore.runTransaction(async (transaction) => {
    const seekerRef = firestore.doc(`users/${seekerId}`);
    const providerRef = firestore.doc(`users/${providerId}`);
    const publicProviderRef = firestore.doc(`publicProfiles/${providerId}`);
    const gratitudeRef = firestore.doc(`gratitudes/${id}`);
    const eligibleApplications = firestore
      .collection("applications")
      .where("seekerId", "==", seekerId)
      .limit(100);
    const [
      seekerDocument,
      providerDocument,
      gratitudeDocument,
      applicationDocuments,
    ] = await Promise.all([
      transaction.get(seekerRef),
      transaction.get(providerRef),
      transaction.get(gratitudeRef),
      transaction.get(eligibleApplications),
    ]);
    if (!seekerDocument.exists || !providerDocument.exists) {
      throw new CommandError("not-found", "Gratitude participant not found.");
    }
    const seekerData = seekerDocument.data() ?? {};
    const providerData = providerDocument.data() ?? {};
    const eligibleRelationship = applicationDocuments.docs.some((document) => {
      const application = document.data();
      return application.providerId === providerId &&
        gratitudeEligibleStatuses.has(application.status);
    });
    const plan = planGratitude({
      seekerId,
      seekerRole: String(seekerData.role ?? ""),
      providerId,
      providerRole: String(providerData.role ?? ""),
      eligibleRelationship,
      existing: gratitudeDocument.exists
        ? gratitudeDocument.data()
        : undefined,
    });
    if (plan.idempotent) {
      return plan;
    }

    const updatedAt = FieldValue.serverTimestamp();
    const currentCount =
      typeof providerData.gratitudesReceived === "number"
        ? providerData.gratitudesReceived
        : 0;
    const projection = buildPublicProfile(
      providerId,
      {
        ...providerData,
        gratitudesReceived: currentCount + 1,
        updatedAt,
      },
      updatedAt,
    );
    transaction.create(gratitudeRef, {
      id,
      fromSeekerId: seekerId,
      fromSeekerName: String(seekerData.name ?? ""),
      toReferrerId: providerId,
      message,
      createdAt: updatedAt,
    });
    transaction.update(providerRef, {
      gratitudesReceived: FieldValue.increment(1),
      updatedAt,
    });
    transaction.set(publicProviderRef, projection);
    transaction.create(firestore.doc(`notifications/${id}`), {
      id,
      userId: providerId,
      type: "gratitude",
      text: `${String(seekerData.name ?? "A seeker")} sent you thanks.`,
      actionRoute: `/providers/${providerId}`,
      read: false,
      createdAt: updatedAt,
    });
    return plan;
  });
}

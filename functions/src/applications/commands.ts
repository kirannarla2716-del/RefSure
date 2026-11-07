import {CommandError} from "../shared/errors";
import {
  applicationId,
  submitEventId,
  transitionEventId,
} from "../shared/ids";
import {assertTransitionAllowed} from "./policy";
import {
  ApplicationSnapshot,
  CommandMutation,
  CommandPlan,
  JobSnapshot,
  ProviderCapacitySnapshot,
  SubmitApplicationInput,
  TrustedMatchSnapshot,
  TransitionApplicationInput,
} from "./types";

export function planSubmitApplication(params: {
  seekerId: string;
  input: SubmitApplicationInput;
  job: JobSnapshot;
  trustedMatch: TrustedMatchSnapshot;
  provider: ProviderCapacitySnapshot;
  existing?: ApplicationSnapshot;
}): CommandPlan {
  const {seekerId, input, job, trustedMatch, provider, existing} = params;
  if (job.status !== "active") {
    throw new CommandError("failed-precondition", "This job is not active.");
  }
  if (provider.role !== "provider" || !provider.availableForReferrals) {
    throw new CommandError(
      "failed-precondition",
      "This referrer is not accepting requests right now.",
    );
  }
  if (provider.activeReferralRequests >= provider.weeklyReferralCapacity) {
    throw new CommandError(
      "resource-exhausted",
      "This referrer has reached their current request capacity.",
    );
  }

  const id = applicationId(seekerId, job.id);
  if (existing) {
    if (
      existing.id !== id ||
      existing.seekerId !== seekerId ||
      existing.jobId !== job.id
    ) {
      throw new CommandError(
        "failed-precondition",
        "The deterministic application ID is already in use.",
      );
    }
    return {
      applicationId: id,
      status: existing.status,
      version: existing.version,
      idempotent: true,
      mutations: [],
    };
  }

  const status = trustedMatch.score >= 80 ? "strongMatch" : "pending";
  const eventId = submitEventId(id);
  return {
    applicationId: id,
    status,
    version: 1,
    idempotent: false,
    mutations: [
      {
        path: `applications/${id}`,
        mode: "create",
        data: {
          jobId: job.id,
          seekerId,
          providerId: job.providerId,
          status,
          version: 1,
          matchScore: trustedMatch.score,
          matchReport: trustedMatch,
          strongMatchFlag: trustedMatch.score >= 80,
          appliedAt: "$serverTimestamp",
          updatedAt: "$serverTimestamp",
          viewedAt: null,
          providerNote: null,
          declineReason: null,
          referralReceiptId: null,
          responseDueAt: {$timestampAfterHours: 48},
          respondedAt: null,
        },
      },
      {
        path: `applicationEvents/${eventId}`,
        mode: "create",
        data: {
          applicationId: id,
          type: "submitted",
          actorId: seekerId,
          fromStatus: null,
          toStatus: status,
          createdAt: "$serverTimestamp",
        },
      },
      {
        path: `notifications/${eventId}`,
        mode: "create",
        data: {
          userId: job.providerId,
          type: "application",
          text: "A candidate submitted a job application.",
          actionRoute: `/applications?applicationId=${id}`,
          read: false,
          createdAt: "$serverTimestamp",
        },
      },
      {
        path: `jobs/${job.id}`,
        mode: "update",
        data: {applicants: {$increment: 1}},
      },
      {
        path: `users/${seekerId}`,
        mode: "update",
        data: {applicationsSubmitted: {$increment: 1}},
      },
      {
        path: `users/${job.providerId}`,
        mode: "update",
        data: {
          applicationsReceived: {$increment: 1},
          activeReferralRequests: {$increment: 1},
          [`applicationStatusCounts.${status}`]: {$increment: 1},
        },
      },
      {
        path: "metrics/applications",
        mode: "set",
        data: {
          total: {$increment: 1},
          [`byStatus.${status}`]: {$increment: 1},
        },
      },
    ],
  };
}

export function planTransitionApplication(params: {
  actorId: string;
  input: TransitionApplicationInput;
  application: ApplicationSnapshot;
  existingEvent?: {
    toStatus?: string;
    expectedVersion?: number;
    resultVersion?: number;
  };
}): CommandPlan {
  const {actorId, input, application, existingEvent} = params;
  const seekerAction = input.toStatus === "withdrawn";
  const authorizedActor = seekerAction ?
    actorId === application.seekerId :
    actorId === application.providerId;
  if (!authorizedActor) {
    throw new CommandError(
      "permission-denied",
      seekerAction ?
        "Only the seeker can withdraw this request." :
        "Only the application owner can change its status.",
    );
  }
  if (input.toStatus === "expired") {
    throw new CommandError(
      "permission-denied",
      "Only the expiry scheduler can expire referral requests.",
    );
  }
  if (existingEvent != null) {
    if (
      existingEvent.toStatus !== input.toStatus ||
      existingEvent.expectedVersion !== input.expectedVersion
    ) {
      throw new CommandError(
        "failed-precondition",
        "commandId was already used for a different transition.",
      );
    }
    return {
      applicationId: application.id,
      status: input.toStatus,
      version: existingEvent.resultVersion ?? input.expectedVersion + 1,
      idempotent: true,
      mutations: [],
    };
  }
  if (input.toStatus === "referred" && !input.receiptReference) {
    throw new CommandError(
      "invalid-argument",
      "A referral receipt reference is required.",
    );
  }
  if (application.version !== input.expectedVersion) {
    throw new CommandError(
      "failed-precondition",
      "Application was updated by another command.",
      {
        reason: "version-conflict",
        expectedVersion: input.expectedVersion,
        actualVersion: application.version,
      },
    );
  }
  assertTransitionAllowed(application.status, input.toStatus);

  const eventId = transitionEventId(application.id, input.commandId);
  const resultVersion = application.version + 1;
  const responseStatus = ["accepted", "declined"].includes(input.toStatus);
  const receiptId = input.toStatus === "referred" ? application.id : null;
  const releasesCapacity = [
    "declined",
    "withdrawn",
    "referred",
    "notSelected",
    "closed",
  ].includes(input.toStatus);

  const receiptMutations: CommandMutation[] = receiptId == null ? [] : [
    {
      path: `referralReceipts/${receiptId}`,
      mode: "create",
      data: {
        applicationId: application.id,
        jobId: application.jobId,
        seekerId: application.seekerId,
        providerId: application.providerId,
        reference: input.receiptReference,
        submittedAt: "$serverTimestamp",
        createdAt: "$serverTimestamp",
      },
    },
  ];

  return {
    applicationId: application.id,
    status: input.toStatus,
    version: resultVersion,
    idempotent: false,
    mutations: [
      {
        path: `applications/${application.id}`,
        mode: "update",
        data: {
          status: input.toStatus,
          version: resultVersion,
          providerNote: input.note ?? null,
          declineReason: input.toStatus === "declined" ? input.note ?? null : null,
          referralReceiptId: receiptId,
          respondedAt: responseStatus ? "$serverTimestamp" : null,
          updatedAt: "$serverTimestamp",
          viewedAt: "$serverTimestamp",
        },
      },
      ...receiptMutations,
      {
        path: `applicationEvents/${eventId}`,
        mode: "create",
        data: {
          applicationId: application.id,
          type: "statusChanged",
          actorId,
          fromStatus: application.status,
          toStatus: input.toStatus,
          expectedVersion: input.expectedVersion,
          resultVersion,
          note: input.note ?? null,
          createdAt: "$serverTimestamp",
        },
      },
      {
        path: `notifications/${eventId}`,
        mode: "create",
        data: {
          userId: application.seekerId,
          type: "status",
          text: `Your application status changed to ${input.toStatus}.`,
          actionRoute: `/applications?applicationId=${application.id}`,
          read: false,
          createdAt: "$serverTimestamp",
        },
      },
      {
        path: `users/${application.providerId}`,
        mode: "update",
        data: {
          [`applicationStatusCounts.${application.status}`]: {$increment: -1},
          [`applicationStatusCounts.${input.toStatus}`]: {$increment: 1},
          ...(releasesCapacity ?
            {activeReferralRequests: {$increment: -1}} : {}),
        },
      },
      {
        path: "metrics/applications",
        mode: "set",
        data: {
          [`byStatus.${application.status}`]: {$increment: -1},
          [`byStatus.${input.toStatus}`]: {$increment: 1},
        },
      },
    ],
  };
}

export function planExpireApplication(
  application: ApplicationSnapshot,
): CommandPlan {
  assertTransitionAllowed(application.status, "expired");
  const resultVersion = application.version + 1;
  const eventId = `application-expired:${application.id}:${application.version}`;
  return {
    applicationId: application.id,
    status: "expired",
    version: resultVersion,
    idempotent: false,
    mutations: [
      {
        path: `applications/${application.id}`,
        mode: "update",
        data: {
          status: "expired",
          version: resultVersion,
          updatedAt: "$serverTimestamp",
        },
      },
      {
        path: `applicationEvents/${eventId}`,
        mode: "create",
        data: {
          applicationId: application.id,
          type: "expired",
          actorId: "system",
          fromStatus: application.status,
          toStatus: "expired",
          expectedVersion: application.version,
          resultVersion,
          createdAt: "$serverTimestamp",
        },
      },
      {
        path: `notifications/${eventId}`,
        mode: "create",
        data: {
          userId: application.seekerId,
          type: "status",
          text: "Your referral request expired without a response.",
          actionRoute: `/applications?applicationId=${application.id}`,
          read: false,
          createdAt: "$serverTimestamp",
        },
      },
      {
        path: `users/${application.providerId}`,
        mode: "update",
        data: {
          activeReferralRequests: {$increment: -1},
          [`applicationStatusCounts.${application.status}`]: {$increment: -1},
          "applicationStatusCounts.expired": {$increment: 1},
        },
      },
      {
        path: "metrics/applications",
        mode: "set",
        data: {
          [`byStatus.${application.status}`]: {$increment: -1},
          "byStatus.expired": {$increment: 1},
        },
      },
    ],
  };
}

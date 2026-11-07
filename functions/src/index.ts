import {initializeApp} from "firebase-admin/app";
import {randomUUID} from "node:crypto";
import {getFirestore} from "firebase-admin/firestore";
import {
  FunctionsErrorCode,
  HttpsError,
  onCall,
} from "firebase-functions/v2/https";
import {
  defineBoolean,
  defineSecret,
  defineString,
} from "firebase-functions/params";
import {
  expireDueApplications,
  submitApplicationTransaction,
  transitionApplicationTransaction,
} from "./applications/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {changeRoleTransaction} from "./account/firestore";
import {assertAdmin, parseAdminCommand} from "./admin/domain";
import {listAdminUsers, manageAdminUser} from "./admin/firestore";
import {sendGratitudeTransaction} from "./gratitude/firestore";
import {requestPrivacyAction} from "./privacy/requests";
import {CommandError, CommandErrorCode} from "./shared/errors";
import {projectPublicProfile} from "./profiles/trigger";
import {reportUserTransaction} from "./safety/report";
import {
  listSafetyReports,
  reviewSafetyReport,
} from "./safety/moderation";
import {
  FirestoreVerificationStore,
  MailConfigurationError,
  OrganizationVerificationService,
  requestOrganizationVerificationCommand,
  ResendVerificationMailer,
  VerificationError,
  verifyOrganizationVerificationCommand,
} from "./verification";

initializeApp();

const firestore = getFirestore();
const region = "us-central1";
const otpHmacSecret = defineSecret("OTP_HMAC_SECRET");
const verificationMailApiKey = defineSecret("VERIFICATION_MAIL_API_KEY");
const verificationMailFrom = defineString("VERIFICATION_MAIL_FROM", {
  default: "",
});
const enforceAppCheckParameter = defineBoolean("ENFORCE_APP_CHECK", {
  default: true,
  description: "Reject callable requests without valid Firebase App Check. " +
    "Set false only in the Firebase Functions emulator.",
});

export function resolveAppCheckEnforcement(
  functionsEmulator: string | undefined,
  configuredValue: boolean,
): boolean {
  return functionsEmulator === "true" ? false : configuredValue;
}

const enforceAppCheck = resolveAppCheckEnforcement(
  process.env.FUNCTIONS_EMULATOR,
  enforceAppCheckParameter.value(),
);

function asHttpsError(error: unknown): HttpsError {
  if (error instanceof CommandError) {
    return new HttpsError(
      error.code as CommandErrorCode,
      error.message,
      error.details,
    );
  }
  const supportReference = `RS-${randomUUID().slice(0, 8).toUpperCase()}`;
  console.error("Trusted command failed", {supportReference, error});
  return new HttpsError(
    "internal",
    `The request failed. Support reference: ${supportReference}.`,
    {supportReference},
  );
}

function asVerificationHttpsError(error: unknown): HttpsError {
  if (error instanceof VerificationError) {
    const code = {
      "unauthenticated": "unauthenticated",
      "invalid-email": "invalid-argument",
      "personal-email": "failed-precondition",
      "invalid-argument": "invalid-argument",
      "invalid-challenge": "failed-precondition",
      "invalid-code": "invalid-argument",
      "incorrect-code": "permission-denied",
      "expired": "deadline-exceeded",
      "exhausted": "resource-exhausted",
      "not-found": "not-found",
      "replayed": "already-exists",
      "delivery-failed": "unavailable",
    }[error.code] ?? "failed-precondition";
    return new HttpsError(code as FunctionsErrorCode, error.message);
  }
  const code = (error as {code?: unknown} | null)?.code;
  if (code === "rate-limited" || code === "cooldown") {
    return new HttpsError("resource-exhausted", "Try again later.");
  }
  if (error instanceof MailConfigurationError) {
    console.error("Organization verification mail transport is not configured.");
    return new HttpsError(
      "failed-precondition",
      "Organization verification email is not configured.",
    );
  }
  console.error("Trusted organization verification command failed.");
  return new HttpsError("internal", "Organization verification failed.");
}

function verificationService(): OrganizationVerificationService {
  return new OrganizationVerificationService(
    new FirestoreVerificationStore(firestore),
    new ResendVerificationMailer(
      verificationMailApiKey.value(),
      verificationMailFrom.value(),
    ),
    {hmacSecret: otpHmacSecret.value()},
  );
}

export const submitApplication = onCall(
  {region, enforceAppCheck},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in is required.");
    }
    try {
      const plan = await submitApplicationTransaction(
        firestore,
        request.auth.uid,
        request.data,
      );
      return {
        applicationId: plan.applicationId,
        status: plan.status,
        version: plan.version,
        idempotent: plan.idempotent,
      };
    } catch (error) {
      throw asHttpsError(error);
    }
  },
);

export const transitionApplication = onCall(
  {region, enforceAppCheck},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in is required.");
    }
    try {
      const plan = await transitionApplicationTransaction(
        firestore,
        request.auth.uid,
        request.data,
      );
      return {
        applicationId: plan.applicationId,
        status: plan.status,
        version: plan.version,
        idempotent: plan.idempotent,
      };
    } catch (error) {
      throw asHttpsError(error);
    }
  },
);

export const expireReferralRequests = onSchedule(
  {region, schedule: "every 15 minutes", timeZone: "UTC"},
  async () => {
    const expired = await expireDueApplications(firestore);
    console.info("Expired referral requests", {count: expired});
  },
);

export const changeRole = onCall(
  {region, enforceAppCheck},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in is required.");
    }
    try {
      return await changeRoleTransaction(
        firestore,
        request.auth.uid,
        request.data,
      );
    } catch (error) {
      throw asHttpsError(error);
    }
  },
);

export const requestPrivacy = onCall(
  {region, enforceAppCheck},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in is required.");
    }
    try {
      return await requestPrivacyAction(
        firestore,
        request.auth.uid,
        request.data,
      );
    } catch (error) {
      throw asHttpsError(error);
    }
  },
);

export const adminListUsers = onCall(
  {region, enforceAppCheck},
  async (request) => {
    try {
      assertAdmin(request.auth?.uid, request.auth?.token.admin);
      return {users: await listAdminUsers(firestore)};
    } catch (error) {
      throw asHttpsError(error);
    }
  },
);

export const adminManageUser = onCall(
  {region, enforceAppCheck},
  async (request) => {
    try {
      const actorId = assertAdmin(request.auth?.uid, request.auth?.token.admin);
      return await manageAdminUser(firestore, actorId, parseAdminCommand(request.data));
    } catch (error) {
      throw asHttpsError(error);
    }
  },
);

export const sendGratitude = onCall(
  {region, enforceAppCheck},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in is required.");
    }
    try {
      return await sendGratitudeTransaction(
        firestore,
        request.auth.uid,
        request.data,
      );
    } catch (error) {
      throw asHttpsError(error);
    }
  },
);

export const reportUser = onCall(
  {region, enforceAppCheck},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in is required.");
    }
    try {
      return await reportUserTransaction(
        firestore,
        request.auth.uid,
        request.data,
      );
    } catch (error) {
      throw asHttpsError(error);
    }
  },
);

export const adminListSafetyReports = onCall(
  {region, enforceAppCheck},
  async (request) => {
    try {
      assertAdmin(request.auth?.uid, request.auth?.token.admin);
      return {reports: await listSafetyReports(firestore, request.data?.status)};
    } catch (error) {
      throw asHttpsError(error);
    }
  },
);

export const adminReviewSafetyReport = onCall(
  {region, enforceAppCheck},
  async (request) => {
    try {
      const actorId = assertAdmin(
        request.auth?.uid,
        request.auth?.token.admin,
      );
      return await reviewSafetyReport(firestore, actorId, request.data);
    } catch (error) {
      throw asHttpsError(error);
    }
  },
);

const verificationCallableOptions = {
  region,
  enforceAppCheck,
  secrets: [otpHmacSecret, verificationMailApiKey],
};

export const requestOrganizationVerification = onCall(
  verificationCallableOptions,
  async (request) => {
    try {
      return await requestOrganizationVerificationCommand(
        verificationService(),
        request.auth?.uid,
        request.data,
      );
    } catch (error) {
      throw asVerificationHttpsError(error);
    }
  },
);

export const verifyOrganizationVerification = onCall(
  verificationCallableOptions,
  async (request) => {
    try {
      return await verifyOrganizationVerificationCommand(
        verificationService(),
        request.auth?.uid,
        request.data,
      );
    } catch (error) {
      throw asVerificationHttpsError(error);
    }
  },
);

export {projectPublicProfile};

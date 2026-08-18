import {
  DocumentData,
  DocumentReference,
  FieldValue,
  Firestore,
  Timestamp,
  Transaction,
} from "firebase-admin/firestore";
import {secureHashEquals} from "./otp_crypto";
import {
  Challenge,
  IssueLimits,
  VerificationStore,
  VerifiedOrganization,
  VerifyOutcome,
} from "./types";

function asDate(value: unknown): Date | null {
  if (value instanceof Date) return value;
  if (value instanceof Timestamp) return value.toDate();
  return null;
}

function numberValue(data: DocumentData, field: string): number {
  const value = data[field];
  return typeof value === "number" ? value : 0;
}

function computeTrustScore(data: DocumentData, organizationVerified: boolean): number {
  let score = organizationVerified ? 30 : 0;
  if (data.verified === true) score += 20;
  if (numberValue(data, "profileComplete") >= 80) score += 15;
  if (numberValue(data, "responseRate") >= 0.8) score += 10;
  const referrals = numberValue(data, "referralsMade");
  if (referrals >= 5) score += 5;
  if (referrals >= 10) score += 5;
  if (referrals >= 20) score += 5;
  if (referrals >= 30) score += 5;
  return Math.min(score, 100);
}

function publicProfileProjection(
  userId: string,
  user: DocumentData,
  organization: VerifiedOrganization,
  trustScore: number,
): DocumentData {
  return {
    id: userId,
    role: user.role ?? "seeker",
    name: user.name ?? "",
    headline: user.headline ?? "",
    title: user.title ?? "",
    location: user.location ?? "",
    skills: Array.isArray(user.skills) ? user.skills : [],
    bio: user.bio ?? "",
    company: organization.companyName,
    photoUrl: user.photoUrl ?? null,
    verified: user.verified === true,
    orgVerified: true,
    profileComplete: numberValue(user, "profileComplete"),
    referralsMade: numberValue(user, "referralsMade"),
    successfulReferrals: numberValue(user, "successfulReferrals"),
    successRate: numberValue(user, "successRate"),
    responseTime: user.responseTime ?? "",
    responseRate: numberValue(user, "responseRate"),
    trustScore,
    gratitudesReceived: numberValue(user, "gratitudesReceived"),
    updatedAt: FieldValue.serverTimestamp(),
  };
}

export class FirestoreVerificationStore implements VerificationStore {
  constructor(private readonly db: Firestore) {}

  async issue(challenge: Challenge, limits: IssueLimits, now: Date): Promise<void> {
    const window = Math.floor(now.getTime() / limits.windowMs);
    const userRateRef = this.db.collection("verification_rate_limits")
      .doc(`user_${challenge.userId}_${window}`);
    const emailKey = Buffer.from(challenge.email).toString("base64url");
    const emailRateRef = this.db.collection("verification_rate_limits")
      .doc(`email_${emailKey}_${window}`);
    const activeRef = this.db.collection("verification_active").doc(challenge.userId);
    const challengeRef = this.db.collection("verification_challenges")
      .doc(challenge.id);

    await this.db.runTransaction(async (transaction) => {
      const [userRate, emailRate, active] = await transaction.getAll(
        userRateRef,
        emailRateRef,
        activeRef,
      );
      if (!userRate || !emailRate || !active) {
        throw new Error("Verification rate-limit documents could not be read.");
      }
      const userCount = numberValue(userRate.data() ?? {}, "count");
      const emailCount = numberValue(emailRate.data() ?? {}, "count");
      if (userCount >= limits.perUserWindow || emailCount >= limits.perEmailWindow) {
        throw Object.assign(new Error("Too many verification requests."), {
          code: "rate-limited",
        });
      }
      const lastIssuedAt = asDate(active.data()?.issuedAt);
      if (
        lastIssuedAt &&
        now.getTime() - lastIssuedAt.getTime() < limits.resendCooldownMs
      ) {
        throw Object.assign(new Error("Wait before requesting another code."), {
          code: "cooldown",
        });
      }

      const previousId = active.data()?.challengeId;
      if (typeof previousId === "string") {
        transaction.update(
          this.db.collection("verification_challenges").doc(previousId),
          {revokedAt: now},
        );
      }
      transaction.set(userRateRef, {count: userCount + 1, window});
      transaction.set(emailRateRef, {count: emailCount + 1, window});
      transaction.set(challengeRef, challenge);
      transaction.set(activeRef, {
        challengeId: challenge.id,
        email: challenge.email,
        issuedAt: now,
      });
    });
  }

  async verify(input: {
    challengeId: string;
    userId: string;
    email: string;
    candidateHash: string;
    organization: VerifiedOrganization;
    now: Date;
  }): Promise<VerifyOutcome> {
    const challengeRef = this.db.collection("verification_challenges")
      .doc(input.challengeId);
    const userRef = this.db.collection("users").doc(input.userId);
    const publicProfileRef = this.db.collection("publicProfiles").doc(input.userId);

    return this.db.runTransaction(async (transaction) => {
      const [challengeSnapshot, userSnapshot] = await transaction.getAll(
        challengeRef,
        userRef,
      );
      if (!challengeSnapshot || !userSnapshot) {
        throw new Error("Verification documents could not be read.");
      }
      const data = challengeSnapshot.data();
      if (
        !challengeSnapshot.exists ||
        !data ||
        data.userId !== input.userId ||
        data.email !== input.email
      ) {
        return {status: "not-found"};
      }
      if (data.consumedAt != null || data.revokedAt != null) {
        return {status: "replayed"};
      }
      const expiresAt = asDate(data.expiresAt);
      if (!expiresAt || expiresAt.getTime() <= input.now.getTime()) {
        transaction.update(challengeRef, {revokedAt: input.now});
        return {status: "expired"};
      }
      const attempts = numberValue(data, "attemptsRemaining");
      if (attempts <= 0) return {status: "exhausted"};
      if (!secureHashEquals(String(data.otpHash), input.candidateHash)) {
        const remaining = attempts - 1;
        transaction.update(challengeRef, {
          attemptsRemaining: remaining,
          ...(remaining === 0 ? {revokedAt: input.now} : {}),
        });
        return remaining === 0 ?
          {status: "exhausted"} :
          {status: "incorrect", attemptsRemaining: remaining};
      }
      if (!userSnapshot.exists) return {status: "not-found"};

      const user = userSnapshot.data() ?? {};
      const trustScore = computeTrustScore(user, true);
      transaction.update(challengeRef, {
        consumedAt: input.now,
        attemptsRemaining: attempts,
      });
      transaction.update(userRef, {
        orgVerified: true,
        orgEmail: input.organization.email,
        company: input.organization.companyName,
        trustScore,
        updatedAt: FieldValue.serverTimestamp(),
      });
      transaction.set(
        publicProfileRef,
        publicProfileProjection(
          input.userId,
          user,
          input.organization,
          trustScore,
        ),
        {merge: true},
      );
      return {status: "verified"};
    });
  }

  async revoke(challengeId: string, now: Date): Promise<void> {
    const reference = this.db.collection("verification_challenges")
      .doc(challengeId);
    await this.db.runTransaction(async (transaction) => {
      const snapshot = await transaction.get(reference);
      if (snapshot.exists) transaction.update(reference, {revokedAt: now});
    });
  }
}

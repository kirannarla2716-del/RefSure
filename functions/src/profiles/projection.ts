export interface PublicProfileProjection {
  id: string;
  role: "seeker" | "provider";
  name: string;
  headline: string;
  company: string | null;
  verified: boolean;
  orgVerified: boolean;
  title: string;
  location: string;
  experience: number;
  skills: string[];
  preferredRoles: string[];
  bio: string;
  photoUrl: string | null;
  profileComplete: number;
  referralsReceived: number;
  referralsMade: number;
  successfulReferrals: number;
  totalJobsPosted: number;
  successRate: number;
  responseTime: string;
  avgResponseHours: number;
  responseRate: number;
  trustScore: number;
  gratitudesReceived: number;
  availableForReferrals: boolean;
  weeklyReferralCapacity: number;
  createdAt: unknown;
  updatedAt: unknown;
}

const stringValue = (value: unknown, fallback = ""): string =>
  typeof value === "string" ? value : fallback;

const nullableString = (value: unknown): string | null =>
  typeof value === "string" && value.length > 0 ? value : null;

const numberValue = (value: unknown, fallback = 0): number =>
  typeof value === "number" && Number.isFinite(value) ? value : fallback;

const stringList = (value: unknown): string[] =>
  Array.isArray(value)
    ? value.filter((item): item is string => typeof item === "string")
    : [];

/**
 * Creates the complete non-sensitive discovery projection from a private user.
 * Identity is always taken from the document path, never client-controlled data.
 */
export function buildPublicProfile(
  userId: string,
  source: Record<string, unknown>,
  projectionUpdatedAt: unknown,
): PublicProfileProjection {
  return {
    id: userId,
    role: source.role === "provider" ? "provider" : "seeker",
    name: stringValue(source.name),
    headline: stringValue(source.headline),
    company: nullableString(source.company),
    verified: source.verified === true,
    orgVerified: source.orgVerified === true,
    title: stringValue(source.title),
    location: stringValue(source.location),
    experience: numberValue(source.experience),
    skills: stringList(source.skills),
    preferredRoles: stringList(source.preferredRoles),
    bio: stringValue(source.bio),
    photoUrl: nullableString(source.photoUrl),
    profileComplete: numberValue(source.profileComplete),
    referralsReceived: numberValue(source.referralsReceived),
    referralsMade: numberValue(source.referralsMade),
    successfulReferrals: numberValue(source.successfulReferrals),
    totalJobsPosted: numberValue(source.totalJobsPosted),
    successRate: numberValue(source.successRate),
    responseTime: stringValue(source.responseTime, "< 48h"),
    avgResponseHours: numberValue(source.avgResponseHours, 48),
    responseRate: numberValue(source.responseRate, 1),
    trustScore: numberValue(source.trustScore),
    gratitudesReceived: numberValue(source.gratitudesReceived),
    availableForReferrals: source.availableForReferrals !== false,
    weeklyReferralCapacity: numberValue(source.weeklyReferralCapacity, 5),
    createdAt: source.createdAt ?? null,
    updatedAt:
      source.updatedAt ?? source.lastActiveAt ?? projectionUpdatedAt,
  };
}

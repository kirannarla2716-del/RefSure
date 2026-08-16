export const applicationStatuses = [
  "pending",
  "accepted",
  "declined",
  "withdrawn",
  "expired",
  "underReview",
  "strongMatch",
  "needsReview",
  "shortlisted",
  "referred",
  "interview",
  "hired",
  "notSelected",
  "closed",
] as const;

export type ApplicationStatus = (typeof applicationStatuses)[number];

export interface SubmitApplicationInput {
  jobId: string;
}

export interface TransitionApplicationInput {
  applicationId: string;
  commandId: string;
  expectedVersion: number;
  toStatus: ApplicationStatus;
  note?: string;
  receiptReference?: string;
}

export interface JobSnapshot {
  id: string;
  providerId: string;
  status: string;
  skills: string[];
  minExp: number;
  maxExp: number;
  location: string;
  workMode: string;
}

export interface SeekerSnapshot {
  id: string;
  role: string;
  skills: string[];
  experience: number;
  location: string;
}

export interface ProviderCapacitySnapshot {
  id: string;
  role: string;
  availableForReferrals: boolean;
  weeklyReferralCapacity: number;
  activeReferralRequests: number;
}

export interface TrustedMatchSnapshot {
  score: number;
  band: string;
  matchedSkills: string[];
  missingSkills: string[];
  skillScore: number;
  experienceScore: number;
  locationScore: number;
  computedAt: "$serverTimestamp";
  source: "server";
  algorithmVersion: 1;
}

export interface ApplicationSnapshot {
  id: string;
  jobId: string;
  seekerId: string;
  providerId: string;
  status: ApplicationStatus;
  matchScore: number;
  version: number;
}

export interface CommandMutation {
  path: string;
  mode: "create" | "set" | "update";
  data: Record<string, unknown>;
}

export interface CommandPlan {
  applicationId: string;
  status: ApplicationStatus;
  version: number;
  idempotent: boolean;
  mutations: CommandMutation[];
}

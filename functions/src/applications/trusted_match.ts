import {
  JobSnapshot,
  SeekerSnapshot,
  TrustedMatchSnapshot,
} from "./types";
import {CommandError} from "../shared/errors";

export function assertSeekerRole(seeker: SeekerSnapshot): void {
  if (seeker.role !== "seeker") {
    throw new CommandError(
      "permission-denied",
      "Only job seekers can request referrals.",
    );
  }
}

function normalized(values: readonly string[]): string[] {
  return [...new Set(
    values
      .map((value) => value.trim().toLowerCase())
      .filter((value) => value.length > 0),
  )];
}

function band(score: number): string {
  if (score >= 90) return "sureShotMatch";
  if (score >= 80) return "excellentMatch";
  if (score >= 70) return "goodToGo";
  if (score >= 60) return "needsReview";
  return "lowMatch";
}

export function computeTrustedMatch(
  seeker: SeekerSnapshot,
  job: JobSnapshot,
): TrustedMatchSnapshot {
  const seekerSkills = new Set(normalized(seeker.skills));
  const requiredSkills = normalized(job.skills);
  const matchedSkills = requiredSkills.filter((skill) => seekerSkills.has(skill));
  const missingSkills = requiredSkills.filter((skill) => !seekerSkills.has(skill));

  // Missing profile/job data is neutral rather than caller-controlled.
  const skillScore = requiredSkills.length === 0 ?
    35 :
    Math.round((matchedSkills.length / requiredSkills.length) * 70);
  const experienceScore = seeker.experience >= job.minExp &&
      seeker.experience <= job.maxExp ?
    20 :
    seeker.experience >= job.minExp - 1 ? 10 : 0;
  const sameLocation = seeker.location.trim().toLowerCase() ===
    job.location.trim().toLowerCase();
  const locationScore = job.workMode.toLowerCase() === "remote" ||
      (seeker.location.length > 0 && sameLocation) ?
    10 :
    0;
  const score = Math.max(
    0,
    Math.min(100, skillScore + experienceScore + locationScore),
  );

  return {
    score,
    band: band(score),
    matchedSkills,
    missingSkills,
    skillScore,
    experienceScore,
    locationScore,
    computedAt: "$serverTimestamp",
    source: "server",
    algorithmVersion: 1,
  };
}

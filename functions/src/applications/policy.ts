import {CommandError} from "../shared/errors";
import {
  ApplicationStatus,
  applicationStatuses,
} from "./types";

const transitions: Readonly<Record<ApplicationStatus, readonly ApplicationStatus[]>> = {
  pending: [
    "accepted",
    "declined",
    "withdrawn",
    "expired",
    "underReview",
    "strongMatch",
    "needsReview",
    "shortlisted",
    "notSelected",
    "closed",
  ],
  accepted: [
    "underReview",
    "shortlisted",
    "referred",
    "declined",
    "withdrawn",
    "expired",
  ],
  declined: [],
  withdrawn: [],
  expired: [],
  strongMatch: [
    "accepted",
    "declined",
    "withdrawn",
    "expired",
    "underReview",
    "shortlisted",
    "referred",
    "notSelected",
    "closed",
  ],
  needsReview: [
    "accepted",
    "declined",
    "withdrawn",
    "expired",
    "underReview",
    "shortlisted",
    "notSelected",
    "closed",
  ],
  underReview: [
    "declined",
    "withdrawn",
    "expired",
    "shortlisted",
    "referred",
    "interview",
    "notSelected",
    "closed",
  ],
  shortlisted: [
    "referred",
    "interview",
    "hired",
    "declined",
    "withdrawn",
    "expired",
    "notSelected",
    "closed",
  ],
  referred: ["interview", "hired", "notSelected", "closed"],
  interview: ["hired", "notSelected", "closed"],
  hired: [],
  notSelected: [],
  closed: [],
};

export function parseStatus(value: unknown): ApplicationStatus {
  if (
    typeof value !== "string" ||
    !applicationStatuses.includes(value as ApplicationStatus)
  ) {
    throw new CommandError("invalid-argument", "Unknown application status.");
  }
  return value as ApplicationStatus;
}

export function assertTransitionAllowed(
  from: ApplicationStatus,
  to: ApplicationStatus,
): void {
  if (!transitions[from].includes(to)) {
    throw new CommandError(
      "failed-precondition",
      `Application cannot transition from ${from} to ${to}.`,
      {from, to, allowed: transitions[from]},
    );
  }
}

export function allowedTransitions(
  status: ApplicationStatus,
): readonly ApplicationStatus[] {
  return transitions[status];
}

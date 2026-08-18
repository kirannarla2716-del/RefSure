export type CommandErrorCode =
  | "invalid-argument"
  | "unauthenticated"
  | "permission-denied"
  | "not-found"
  | "already-exists"
  | "resource-exhausted"
  | "failed-precondition";

export class CommandError extends Error {
  constructor(
    readonly code: CommandErrorCode,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = "CommandError";
  }
}

export function requireString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new CommandError("invalid-argument", `${field} is required.`);
  }
  return value.trim();
}

export function optionalString(
  value: unknown,
  field: string,
  maxLength: number,
): string | undefined {
  if (value == null) return undefined;
  if (typeof value !== "string") {
    throw new CommandError("invalid-argument", `${field} must be a string.`);
  }
  const normalized = value.trim();
  if (normalized.length > maxLength) {
    throw new CommandError(
      "invalid-argument",
      `${field} must be at most ${maxLength} characters.`,
    );
  }
  return normalized.length === 0 ? undefined : normalized;
}

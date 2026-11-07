import {createHash} from "node:crypto";

function digest(parts: readonly string[]): string {
  return createHash("sha256").update(parts.join("\u001f")).digest("hex");
}

export function applicationId(seekerId: string, jobId: string): string {
  return `app_${digest([seekerId, jobId]).slice(0, 32)}`;
}

export function submitEventId(id: string): string {
  return `${id}_submitted`;
}

export function transitionEventId(
  id: string,
  commandId: string,
): string {
  return `${id}_${digest([commandId]).slice(0, 20)}`;
}

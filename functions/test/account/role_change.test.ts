import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {
  parseAccountRole,
  planRoleChange,
  roleChangeEventId,
} from "../../src/account/domain";
import {CommandError} from "../../src/shared/errors";

describe("trusted role change", () => {
  it("validates the complete role enum", () => {
    assert.equal(parseAccountRole("seeker"), "seeker");
    assert.equal(parseAccountRole("provider"), "provider");
    for (const value of ["admin", "", null, 1]) {
      assert.throws(
        () => parseAccountRole(value),
        (error: unknown) =>
          error instanceof CommandError &&
          error.code === "invalid-argument",
      );
    }
  });

  it("creates deterministic audit IDs for stable retries", () => {
    assert.equal(
      roleChangeEventId("user-1", "command-1"),
      roleChangeEventId("user-1", "command-1"),
    );
    assert.notEqual(
      roleChangeEventId("user-1", "command-1"),
      roleChangeEventId("user-1", "command-2"),
    );
  });

  it("plans a role change and treats the same command as idempotent", () => {
    const first = planRoleChange({
      uid: "user-1",
      currentRole: "seeker",
      targetRole: "provider",
      commandId: "command-1",
    });
    assert.equal(first.idempotent, false);
    assert.equal(first.role, "provider");

    const retry = planRoleChange({
      uid: "user-1",
      currentRole: "provider",
      targetRole: "provider",
      commandId: "command-1",
      existingEventRole: "provider",
    });
    assert.equal(retry.idempotent, true);
  });

  it("rejects command reuse for another role", () => {
    assert.throws(
      () => planRoleChange({
        uid: "user-1",
        currentRole: "provider",
        targetRole: "seeker",
        commandId: "reused",
        existingEventRole: "provider",
      }),
      (error: unknown) =>
        error instanceof CommandError &&
        error.code === "failed-precondition",
    );
  });
});

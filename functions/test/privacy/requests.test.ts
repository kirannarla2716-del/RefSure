import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {parsePrivacyRequest} from "../../src/privacy/requests";
import {CommandError} from "../../src/shared/errors";

describe("privacy requests", () => {
  it("accepts supported privacy actions", () => {
    for (const type of ["data_export", "account_deletion"]) {
      assert.deepEqual(parsePrivacyRequest({type, commandId: `privacy-${type}`}), {
        type,
        commandId: `privacy-${type}`,
      });
    }
  });

  it("rejects unsupported actions and unsafe command IDs", () => {
    for (const input of [
      {type: "erase_messages", commandId: "privacy-1"},
      {type: "data_export", commandId: "privacy/1"},
    ]) {
      assert.throws(
        () => parsePrivacyRequest(input),
        (error: unknown) => error instanceof CommandError &&
          error.code === "invalid-argument",
      );
    }
  });
});

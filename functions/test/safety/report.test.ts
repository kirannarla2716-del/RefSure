import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {parseSafetyReport} from "../../src/safety/report";
import {CommandError} from "../../src/shared/errors";

describe("safety reports", () => {
  it("accepts a bounded canonical report", () => {
    assert.deepEqual(parseSafetyReport({
      targetId: "provider-1",
      category: "fraud",
      details: "Requested money in exchange for a referral.",
      contextId: "conversation:provider-1",
      commandId: "report-1",
    }), {
      targetId: "provider-1",
      category: "fraud",
      details: "Requested money in exchange for a referral.",
      contextId: "conversation:provider-1",
      commandId: "report-1",
    });
  });

  it("rejects unknown categories and empty details", () => {
    for (const input of [
      {targetId: "provider-1", category: "bad", details: "x", commandId: "1"},
      {targetId: "provider-1", category: "spam", details: "", commandId: "1"},
      {targetId: "provider/1", category: "spam", details: "x", commandId: "1"},
      {targetId: "provider-1", category: "spam", details: "x", commandId: "a/b"},
    ]) {
      assert.throws(
        () => parseSafetyReport(input),
        (error: unknown) => error instanceof CommandError &&
          error.code === "invalid-argument",
      );
    }
  });
});

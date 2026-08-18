import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {parseModerationInput} from "../../src/safety/moderation";
import {CommandError} from "../../src/shared/errors";

describe("safety moderation", () => {
  it("accepts a canonical moderation decision", () => {
    assert.deepEqual(parseModerationInput({
      reportId: "report-1",
      decision: "escalated",
      note: "Escalated for identity and payment review.",
      commandId: "moderation-1",
    }), {
      reportId: "report-1",
      decision: "escalated",
      note: "Escalated for identity and payment review.",
      commandId: "moderation-1",
    });
  });

  it("rejects unsupported decisions and missing notes", () => {
    for (const input of [
      {
        reportId: "report-1",
        decision: "deleted",
        note: "Invalid decision.",
        commandId: "moderation-1",
      },
      {
        reportId: "report-1",
        decision: "resolved",
        note: "",
        commandId: "moderation-1",
      },
      {
        reportId: "report-1",
        decision: "resolved",
        note: "Reviewed.",
        commandId: "moderation/1",
      },
    ]) {
      assert.throws(
        () => parseModerationInput(input),
        (error: unknown) => error instanceof CommandError &&
          error.code === "invalid-argument",
      );
    }
  });
});

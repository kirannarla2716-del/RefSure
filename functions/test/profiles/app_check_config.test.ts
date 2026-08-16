import assert from "node:assert/strict";
import {describe, it} from "node:test";
import {resolveAppCheckEnforcement} from "../../src/index";

describe("App Check deployment default", () => {
  it("enforces configured App Check outside the emulator", () => {
    assert.equal(resolveAppCheckEnforcement(undefined, true), true);
    assert.equal(resolveAppCheckEnforcement("false", true), true);
  });

  it("disables enforcement only for the explicit Functions emulator", () => {
    assert.equal(resolveAppCheckEnforcement("true", true), false);
  });
});

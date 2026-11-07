import assert from "node:assert/strict";
import test from "node:test";
import {assertAdmin, parseAdminCommand} from "../../src/admin/domain";

test("Given no admin claim, when access is checked, then permission is denied", () => {
  assert.throws(() => assertAdmin("user-1", false), /Administrator access/);
});

test("Given a valid onboarding exception, when parsed, then it is accepted", () => {
  const result = parseAdminCommand({
    userId: "user-1",
    action: "onboardingException",
    commandId: "command-1",
    exceptionReason: "Enterprise pilot",
    exceptionUntil: "2099-01-01T00:00:00.000Z",
  });
  assert.equal(result.action, "onboardingException");
  assert.equal(result.exceptionReason, "Enterprise pilot");
});

test("Given no exception reason, when parsed, then the command is rejected", () => {
  assert.throws(() => parseAdminCommand({
    userId: "user-1",
    action: "onboardingException",
    commandId: "command-1",
    exceptionUntil: "2099-01-01T00:00:00.000Z",
  }), /reason and future/);
});

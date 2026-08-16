import assert from "node:assert/strict";
import test from "node:test";
import {
  MailConfigurationError,
  ResendVerificationMailer,
} from "../../src/verification/mailer";

test("mailer fails explicitly when secrets or sender configuration are absent", () => {
  assert.throws(
    () => new ResendVerificationMailer("", "verify@refsure.app"),
    MailConfigurationError,
  );
  assert.throws(
    () => new ResendVerificationMailer("secret", ""),
    MailConfigurationError,
  );
});

test("mailer sends through configured provider without logging plaintext", async () => {
  let requestBody = "";
  const mailer = new ResendVerificationMailer(
    "mail-secret",
    "RefSure <verify@refsure.app>",
    async (_url, request) => {
      requestBody = request.body;
      return {ok: true, status: 200};
    },
  );
  await mailer.sendOrganizationOtp({
    email: "employee@acme.com",
    otp: "123456",
    expiresInMinutes: 10,
  });
  const payload = JSON.parse(requestBody) as Record<string, unknown>;
  assert.equal(payload.subject, "Your RefSure organization verification code");
  assert.match(String(payload.text), /123456/);
});

test("mailer surfaces provider failure without exposing response content", async () => {
  const mailer = new ResendVerificationMailer(
    "mail-secret",
    "verify@refsure.app",
    async () => ({ok: false, status: 503}),
  );
  await assert.rejects(
    () => mailer.sendOrganizationOtp({
      email: "employee@acme.com",
      otp: "123456",
      expiresInMinutes: 10,
    }),
    /returned 503/,
  );
});

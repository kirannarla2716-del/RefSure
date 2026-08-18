import {VerificationMailer} from "./types";

export type FetchLike = (
  input: string,
  init: {
    method: string;
    headers: Record<string, string>;
    body: string;
  },
) => Promise<{ok: boolean; status: number}>;

export class MailConfigurationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "MailConfigurationError";
  }
}

export class ResendVerificationMailer implements VerificationMailer {
  constructor(
    private readonly apiKey: string,
    private readonly from: string,
    private readonly fetcher: FetchLike = fetch,
  ) {
    if (!apiKey.trim()) {
      throw new MailConfigurationError(
        "VERIFICATION_MAIL_API_KEY is not configured.",
      );
    }
    if (!from.trim() || !from.includes("@")) {
      throw new MailConfigurationError(
        "VERIFICATION_MAIL_FROM is not configured.",
      );
    }
  }

  async sendOrganizationOtp(input: {
    email: string;
    otp: string;
    expiresInMinutes: number;
  }): Promise<void> {
    const response = await this.fetcher("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: this.from,
        to: [input.email],
        subject: "Your RefSure organization verification code",
        text:
          `Your RefSure verification code is ${input.otp}. ` +
          `It expires in ${input.expiresInMinutes} minutes. ` +
          "If you did not request this code, ignore this email.",
      }),
    });
    if (!response.ok) {
      throw new Error(`Verification email provider returned ${response.status}.`);
    }
  }
}

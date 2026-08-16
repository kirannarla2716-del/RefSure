const blockedDomains = new Set([
  'aol.com',
  'gmail.com',
  'hotmail.com',
  'icloud.com',
  'mail.com',
  'outlook.com',
  'proton.me',
  'protonmail.com',
  'yahoo.com',
]);

const emailPattern =
  /^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+@([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$/;

export type OrganizationEmail = {
  email: string;
  domain: string;
  companyName: string;
};

export class VerificationError extends Error {
  readonly code: string;

  constructor(
    code: string,
    message: string,
  ) {
    super(message);
    this.name = 'VerificationError';
    this.code = code;
  }
}

export function parseOrganizationEmail(rawEmail: string): OrganizationEmail {
  const email = rawEmail.trim().toLowerCase();
  if (email.length > 254 || !emailPattern.test(email)) {
    throw new VerificationError('invalid-email', 'Enter a valid work email address.');
  }

  const domain = email.slice(email.lastIndexOf('@') + 1);
  if (blockedDomains.has(domain)) {
    throw new VerificationError(
      'personal-email',
      'Please use your work or organisation email address.',
    );
  }

  const companyLabel = domain.split('.')[0] ?? domain;
  const companyName = companyLabel
    .split('-')
    .filter(Boolean)
    .map((part) => (part[0] ?? '').toUpperCase() + part.slice(1))
    .join(' ');

  return {email, domain, companyName};
}

export function isOrganizationEmail(email: string): boolean {
  try {
    parseOrganizationEmail(email);
    return true;
  } catch {
    return false;
  }
}

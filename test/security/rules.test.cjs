const fs = require('node:fs');
const path = require('node:path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  deleteDoc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} = require('firebase/firestore');
const {
  getDownloadURL,
  ref,
  uploadBytes,
} = require('firebase/storage');

const projectId = 'refsure-rules-test';
const root = path.resolve(__dirname, '../..');
let testEnv;

const user = (id) => ({
  id,
  role: 'seeker',
  name: id,
  headline: '',
  company: null,
  verified: false,
  orgVerified: false,
  title: '',
  location: '',
  experience: 0,
  skills: [],
  preferredRoles: [],
  bio: '',
  photoUrl: null,
  email: `${id}@example.com`,
  orgEmail: null,
  linkedinUrl: null,
  resumeUrl: null,
  createdAt: new Date('2026-01-01T00:00:00Z'),
  updatedAt: new Date('2026-01-02T00:00:00Z'),
  lastActiveAt: null,
  onboardingSource: 'manual',
  education: null,
  currentCompany: null,
  noticePeriod: null,
  expectedSalary: null,
  activelyLooking: false,
  profileComplete: 30,
  referralsReceived: 0,
  referralsMade: 0,
  successfulReferrals: 0,
  totalJobsPosted: 0,
  successRate: 0,
  responseTime: '< 48h',
  avgResponseHours: 48,
  responseRate: 1,
  trustScore: 0,
  gratitudesReceived: 0,
  applicationsSubmitted: 0,
  applicationsReceived: 0,
  applicationStatusCounts: {},
});

const provider = (id) => ({
  ...user(id),
  role: 'provider',
});

const job = (providerId, id = 'job-1') => ({
  id,
  providerId,
  company: 'Acme',
  companyLogo: 'A',
  title: 'Engineer',
  department: 'Engineering',
  location: 'Bengaluru',
  workMode: 'Hybrid',
  minExp: 1,
  maxExp: 5,
  salaryMin: 0,
  salaryMax: 0,
  skills: ['Dart'],
  preferredSkills: [],
  tags: [],
  description: 'Build reliable systems.',
  providerNote: null,
  status: 'active',
  applicants: 0,
  viewCount: 0,
  applicationCount: 0,
  deadline: '2026-12-31',
  postedAt: new Date('2026-01-01T00:00:00Z'),
  jobRefId: 'REF-1',
  isHot: false,
  source: 'manual',
  externalUrl: null,
});

const application = (seekerId, providerId, overrides = {}) => ({
  seekerId,
  providerId,
  jobId: 'job-1',
  status: 'pending',
  matchScore: 70,
  matchReport: { score: 70 },
  strongMatchFlag: false,
  appliedAt: new Date(),
  updatedAt: new Date(),
  viewedAt: null,
  providerNote: null,
  ...overrides,
});

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(path.join(root, 'firestore.rules'), 'utf8'),
    },
    storage: {
      rules: fs.readFileSync(path.join(root, 'storage.rules'), 'utf8'),
    },
  });
});

beforeEach(async () => testEnv.clearFirestore());
after(async () => {
  if (testEnv) {
    await testEnv.cleanup();
  }
});

async function seed(data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [collection, id, value] of data) {
      await setDoc(doc(db, collection, id), value);
    }
  });
}

describe('Firestore rules', () => {
  it('allows only self-owned safe profile creation', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(setDoc(doc(db, 'users/alice'), user('alice')));
    await assertFails(setDoc(doc(db, 'users/bob'), user('bob')));
    await assertFails(setDoc(
      doc(db, 'users/alice-verified'),
      {...user('alice-verified'), verified: true},
    ));
    await assertFails(setDoc(
      doc(db, 'users/alice-admin'),
      {...user('alice-admin'), admin: true},
    ));
  });

  it('protects verification and reputation fields', async () => {
    await seed([['users', 'alice', user('alice')]]);
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(updateDoc(doc(db, 'users/alice'), {name: 'Alice'}));
    await assertSucceeds(updateDoc(doc(db, 'users/alice'), {
      name: 'Alice Updated',
      email: 'alice.updated@example.com',
      company: 'Acme',
      currentCompany: 'Acme',
      bio: 'Updated profile',
      resumeUrl: 'https://storage.example/resume.pdf',
      updatedAt: serverTimestamp(),
      lastActiveAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(db, 'users/alice'), {orgVerified: true}));
    await assertFails(updateDoc(doc(db, 'users/alice'), {trustScore: 100}));
    await assertFails(updateDoc(doc(db, 'users/alice'), {role: 'provider'}));
    await assertFails(updateDoc(doc(db, 'users/alice'), {
      applicationsReceived: 100,
    }));
    await assertFails(updateDoc(doc(db, 'users/alice'), {
      applicationStatusCounts: {hired: 100},
    }));
  });

  it('allows provider availability settings but protects active capacity', async () => {
    await seed([['users', 'provider', {
      ...provider('provider'),
      availableForReferrals: true,
      weeklyReferralCapacity: 5,
      activeReferralRequests: 1,
    }]]);
    const db = testEnv.authenticatedContext('provider').firestore();
    await assertSucceeds(updateDoc(doc(db, 'users/provider'), {
      availableForReferrals: false,
      weeklyReferralCapacity: 10,
    }));
    await assertFails(updateDoc(doc(db, 'users/provider'), {
      activeReferralRequests: 0,
    }));
  });

  it('makes private users owner-readable and public profiles discoverable', async () => {
    await seed([
      ['users', 'alice', {...user('alice'), email: 'alice@example.com'}],
      ['publicProfiles', 'alice', {
        id: 'alice',
        role: 'seeker',
        name: 'Alice',
        updatedAt: new Date('2026-01-02T00:00:00Z'),
        referralsMade: 0,
        successfulReferrals: 0,
        totalJobsPosted: 0,
        trustScore: 0,
        gratitudesReceived: 0,
      }],
    ]);
    const alice = testEnv.authenticatedContext('alice').firestore();
    const bob = testEnv.authenticatedContext('bob').firestore();
    const anonymous = testEnv.unauthenticatedContext().firestore();

    await assertSucceeds(getDoc(doc(alice, 'users/alice')));
    await assertFails(getDoc(doc(bob, 'users/alice')));
    await assertFails(getDoc(doc(anonymous, 'users/alice')));
    await assertSucceeds(getDoc(doc(bob, 'publicProfiles/alice')));
    await assertFails(getDoc(doc(anonymous, 'publicProfiles/alice')));
    await assertFails(setDoc(doc(bob, 'publicProfiles/bob'), {
      id: 'bob',
      email: 'leak@example.com',
    }));
  });

  it('allows only providers to create and mutate their own jobs', async () => {
    await seed([
      ['users', 'alice', provider('alice')],
      ['users', 'bob', user('bob')],
    ]);
    const alice = testEnv.authenticatedContext('alice').firestore();
    const bob = testEnv.authenticatedContext('bob').firestore();
    await assertSucceeds(setDoc(doc(alice, 'jobs/job-1'), job('alice')));
    await assertFails(setDoc(doc(bob, 'jobs/job-2'), job('bob', 'job-2')));
    await assertFails(setDoc(
      doc(alice, 'jobs/job-3'),
      job('bob', 'job-3'),
    ));
    await assertFails(setDoc(
      doc(alice, 'jobs/job-4'),
      {...job('alice'), internalOverride: true},
    ));
    await assertFails(setDoc(
      doc(alice, 'jobs/job-5'),
      {...job('alice', 'job-5'), applicationCount: 1},
    ));
    await assertFails(updateDoc(
      doc(alice, 'jobs/job-1'),
      {providerId: 'bob'},
    ));
    await assertSucceeds(updateDoc(
      doc(alice, 'jobs/job-1'),
      {title: 'Senior Engineer'},
    ));
    await assertFails(updateDoc(
      doc(alice, 'jobs/job-1'),
      {applicationCount: 10},
    ));
  });

  it('denies client-created and client-mutated applications', async () => {
    await seed([['jobs', 'job-1', job('provider')]]);
    const seeker = testEnv.authenticatedContext('seeker').firestore();
    await assertFails(setDoc(
      doc(seeker, 'applications/app-1'),
      application('seeker', 'provider'),
    ));
    await assertFails(setDoc(
      doc(seeker, 'applications/app-2'),
      application('seeker', 'provider', {status: 'strongMatch'}),
    ));
    await assertFails(setDoc(
      doc(seeker, 'applications/app-3'),
      application('seeker', 'attacker'),
    ));
  });

  it('allows application participants to read but denies lifecycle forgery', async () => {
    await seed([
      ['jobs', 'job-1', job('provider')],
      ['applications', 'app-1', application('seeker', 'provider')],
    ]);
    const provider = testEnv.authenticatedContext('provider').firestore();
    const seeker = testEnv.authenticatedContext('seeker').firestore();
    const outsider = testEnv.authenticatedContext('outsider').firestore();
    await assertSucceeds(getDoc(doc(provider, 'applications/app-1')));
    await assertSucceeds(getDoc(doc(seeker, 'applications/app-1')));
    await assertFails(getDoc(doc(outsider, 'applications/app-1')));
    await assertFails(updateDoc(
      doc(provider, 'applications/app-1'),
      {status: 'underReview', providerNote: 'Reviewing'},
    ));
    await assertFails(updateDoc(
      doc(seeker, 'applications/app-1'),
      {status: 'hired'},
    ));
    await assertFails(updateDoc(
      doc(provider, 'applications/app-1'),
      {matchScore: 100},
    ));
  });

  it('limits referral receipts to participants and denies client writes', async () => {
    await seed([['referralReceipts', 'app-1', {
      applicationId: 'app-1',
      jobId: 'job-1',
      seekerId: 'seeker',
      providerId: 'provider',
      reference: 'REF-2026-001',
      submittedAt: new Date(),
      createdAt: new Date(),
    }]]);
    const seeker = testEnv.authenticatedContext('seeker').firestore();
    const providerDb = testEnv.authenticatedContext('provider').firestore();
    const outsider = testEnv.authenticatedContext('outsider').firestore();
    await assertSucceeds(getDoc(doc(seeker, 'referralReceipts/app-1')));
    await assertSucceeds(getDoc(doc(providerDb, 'referralReceipts/app-1')));
    await assertFails(getDoc(doc(outsider, 'referralReceipts/app-1')));
    await assertFails(setDoc(doc(providerDb, 'referralReceipts/forged'), {
      seekerId: 'seeker',
      providerId: 'provider',
      reference: 'FORGED',
    }));
    await assertFails(updateDoc(doc(providerDb, 'referralReceipts/app-1'), {
      reference: 'CHANGED',
    }));
  });

  it('denies client OTPs and notification creation', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'otp_verifications/otp-1'), {
      userId: 'alice',
      otp: '123456',
    }));
    await assertFails(setDoc(doc(db, 'notifications/notif-1'), {
      userId: 'alice',
      read: false,
      text: 'Forged',
    }));
  });

  it('accepts only bounded participant messages with the canonical schema', async () => {
    await seed([
      ['users', 'alice', user('alice')],
      ['users', 'bob', user('bob')],
    ]);
    const alice = testEnv.authenticatedContext('alice').firestore();
    const bob = testEnv.authenticatedContext('bob').firestore();
    const sentAt = new Date();
    await assertSucceeds(setDoc(doc(alice, 'messages/valid'), {
      fromId: 'alice', toId: 'bob', text: 'Hello', sentAt, read: false,
    }));
    await assertFails(setDoc(doc(bob, 'messages/forged'), {
      fromId: 'alice', toId: 'bob', text: 'Forged', sentAt, read: false,
    }));
    await assertFails(setDoc(doc(alice, 'messages/oversized'), {
      fromId: 'alice', toId: 'bob', text: 'x'.repeat(4001), sentAt, read: false,
    }));
    await assertFails(setDoc(doc(alice, 'messages/extra-field'), {
      fromId: 'alice', toId: 'bob', text: 'Hello', sentAt, read: false,
      admin: true,
    }));
    await assertFails(setDoc(doc(alice, 'messages/pre-read'), {
      fromId: 'alice', toId: 'bob', text: 'Hello', sentAt, read: true,
    }));
  });

  it('enforces owner-controlled blocks in both messaging directions', async () => {
    await seed([
      ['users', 'alice', user('alice')],
      ['users', 'bob', user('bob')],
    ]);
    const alice = testEnv.authenticatedContext('alice').firestore();
    const bob = testEnv.authenticatedContext('bob').firestore();
    const sentAt = new Date();
    await assertSucceeds(setDoc(doc(alice, 'users/alice/blocks/bob'), {
      ownerId: 'alice', blockedUserId: 'bob', createdAt: sentAt,
    }));
    await assertFails(setDoc(doc(bob, 'users/alice/blocks/bob-2'), {
      ownerId: 'alice', blockedUserId: 'bob-2', createdAt: sentAt,
    }));
    await assertFails(setDoc(doc(alice, 'messages/blocked-outbound'), {
      fromId: 'alice', toId: 'bob', text: 'Hello', sentAt, read: false,
    }));
    await assertFails(setDoc(doc(bob, 'messages/blocked-inbound'), {
      fromId: 'bob', toId: 'alice', text: 'Hello', sentAt, read: false,
    }));
    await assertSucceeds(deleteDoc(doc(alice, 'users/alice/blocks/bob')));
    await assertSucceeds(setDoc(doc(alice, 'messages/after-unblock'), {
      fromId: 'alice', toId: 'bob', text: 'Hello', sentAt, read: false,
    }));
  });

  it('denies all client access to safety records and moderation events', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'safetyReports/forged'), {
      reporterId: 'alice', targetId: 'bob', category: 'spam',
      details: 'Forged', status: 'open', createdAt: new Date(),
    }));
    await assertFails(getDoc(doc(db, 'safetyReports/existing')));
    await assertFails(setDoc(doc(db, 'safetyRateLimits/alice'), {count: 0}));
    await assertFails(setDoc(doc(db, 'moderationEvents/forged'), {
      reportId: 'existing', actorId: 'alice', decision: 'dismissed',
    }));
    await assertFails(getDoc(doc(db, 'moderationEvents/existing')));
  });

  it('denies all client access to privacy requests and events', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'privacyRequests/alice_data_export'), {
      userId: 'alice', type: 'data_export', status: 'pending',
    }));
    await assertFails(getDoc(doc(db, 'privacyRequests/alice_data_export')));
    await assertFails(setDoc(doc(db, 'privacyEvents/forged'), {
      userId: 'alice', type: 'data_export', action: 'completed',
    }));
  });

  it('limits gratitude reads to the sender and recipient', async () => {
    await seed([['gratitudes', 'thanks-1', {
      fromSeekerId: 'alice',
      toReferrerId: 'bob',
      message: 'Thank you',
    }]]);
    const alice = testEnv.authenticatedContext('alice').firestore();
    const bob = testEnv.authenticatedContext('bob').firestore();
    const eve = testEnv.authenticatedContext('eve').firestore();
    await assertSucceeds(getDoc(doc(alice, 'gratitudes/thanks-1')));
    await assertSucceeds(getDoc(doc(bob, 'gratitudes/thanks-1')));
    await assertFails(getDoc(doc(eve, 'gratitudes/thanks-1')));
  });

  it('denies client events, counters, gratitudes, and job counter abuse', async () => {
    await seed([
      ['users', 'provider', provider('provider')],
      ['jobs', 'job-1', job('provider')],
    ]);
    const db = testEnv.authenticatedContext('provider').firestore();
    await assertFails(setDoc(doc(db, 'events/event-1'), {
      type: 'applicationCreated',
    }));
    await assertFails(setDoc(doc(db, 'counters/global'), {applications: 999}));
    await assertFails(setDoc(doc(db, 'gratitudes/fake'), {
      fromSeekerId: 'provider',
      toReferrerId: 'provider',
    }));
    await assertFails(updateDoc(doc(db, 'jobs/job-1'), {applicants: 1000}));
    await assertFails(updateDoc(doc(db, 'jobs/job-1'), {viewCount: 1000}));
    await assertFails(updateDoc(doc(db, 'users/provider'), {
      referralsMade: 1000,
    }));
  });

  it('allows recipients to mark only their notification read', async () => {
    await seed([['notifications', 'notif-1', {
      userId: 'alice',
      read: false,
      text: 'Server event',
    }]]);
    const alice = testEnv.authenticatedContext('alice').firestore();
    const bob = testEnv.authenticatedContext('bob').firestore();
    await assertSucceeds(updateDoc(
      doc(alice, 'notifications/notif-1'),
      {read: true},
    ));
    await assertFails(updateDoc(
      doc(bob, 'notifications/notif-1'),
      {read: true},
    ));
  });
});

describe('Storage rules', () => {
  it('owner can upload a valid profile photo but another user cannot', async () => {
    const aliceStorage = testEnv.authenticatedContext('alice').storage();
    const bobStorage = testEnv.authenticatedContext('bob').storage();
    const data = new Uint8Array([1, 2, 3]);
    await assertSucceeds(uploadBytes(
      ref(aliceStorage, 'profile_photos/alice.jpg'),
      data,
      {contentType: 'image/jpeg'},
    ));
    await assertFails(uploadBytes(
      ref(bobStorage, 'profile_photos/alice.jpg'),
      data,
      {contentType: 'image/jpeg'},
    ));
    await assertFails(uploadBytes(
      ref(aliceStorage, 'profile_photos/alice.exe'),
      data,
      {contentType: 'application/octet-stream'},
    ));
    await assertFails(uploadBytes(
      ref(aliceStorage, 'profile_photos/alice.jpg'),
      new Uint8Array(5 * 1024 * 1024 + 1),
      {contentType: 'image/jpeg'},
    ));
  });

  it('resume upload and read are owner-only with an approved MIME type', async () => {
    const aliceStorage = testEnv.authenticatedContext('alice').storage();
    const bobStorage = testEnv.authenticatedContext('bob').storage();
    const resumeRef = ref(aliceStorage, 'resumes/alice/resume.pdf');
    await assertSucceeds(uploadBytes(
      resumeRef,
      new Uint8Array([1, 2, 3]),
      {contentType: 'application/pdf'},
    ));
    await assertSucceeds(getDownloadURL(resumeRef));
    await assertFails(getDownloadURL(
      ref(bobStorage, 'resumes/alice/resume.pdf'),
    ));
    await assertFails(uploadBytes(
      ref(aliceStorage, 'resumes/alice/resume.txt'),
      new Uint8Array([1]),
      {contentType: 'text/plain'},
    ));
    await assertFails(uploadBytes(
      ref(aliceStorage, 'resumes/alice/resume.pdf'),
      new Uint8Array(10 * 1024 * 1024 + 1),
      {contentType: 'application/pdf'},
    ));
  });
});

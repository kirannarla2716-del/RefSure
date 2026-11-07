#!/usr/bin/env node

'use strict';

const {applicationDefault, getApps, initializeApp} = require('firebase-admin/app');
const {FieldValue, getFirestore} = require('firebase-admin/firestore');

const backupCollection = '_migration_public_profiles_v2';
const publicCollection = 'publicProfiles';
const batchLimit = 400;

const publicFields = Object.freeze([
  'id',
  'role',
  'name',
  'headline',
  'company',
  'verified',
  'orgVerified',
  'title',
  'location',
  'experience',
  'skills',
  'preferredRoles',
  'bio',
  'photoUrl',
  'profileComplete',
  'referralsReceived',
  'referralsMade',
  'successfulReferrals',
  'totalJobsPosted',
  'successRate',
  'responseTime',
  'avgResponseHours',
  'responseRate',
  'trustScore',
  'gratitudesReceived',
  'availableForReferrals',
  'weeklyReferralCapacity',
  'createdAt',
  'updatedAt',
]);

const stringValue = (value, fallback = '') =>
  typeof value === 'string' ? value : fallback;
const nullableString = (value) =>
  typeof value === 'string' && value.length > 0 ? value : null;
const numberValue = (value, fallback = 0) =>
  typeof value === 'number' && Number.isFinite(value) ? value : fallback;
const stringList = (value) =>
  Array.isArray(value) ? value.filter((item) => typeof item === 'string') : [];

function buildPublicProfile(id, source, projectionUpdatedAt) {
  return {
    id,
    role: source.role === 'provider' ? 'provider' : 'seeker',
    name: stringValue(source.name),
    headline: stringValue(source.headline),
    company: nullableString(source.company),
    verified: source.verified === true,
    orgVerified: source.orgVerified === true,
    title: stringValue(source.title),
    location: stringValue(source.location),
    experience: numberValue(source.experience),
    skills: stringList(source.skills),
    preferredRoles: stringList(source.preferredRoles),
    bio: stringValue(source.bio),
    photoUrl: nullableString(source.photoUrl),
    profileComplete: numberValue(source.profileComplete),
    referralsReceived: numberValue(source.referralsReceived),
    referralsMade: numberValue(source.referralsMade),
    successfulReferrals: numberValue(source.successfulReferrals),
    totalJobsPosted: numberValue(source.totalJobsPosted),
    successRate: numberValue(source.successRate),
    responseTime: stringValue(source.responseTime, '< 48h'),
    avgResponseHours: numberValue(source.avgResponseHours, 48),
    responseRate: numberValue(source.responseRate, 1),
    trustScore: numberValue(source.trustScore),
    gratitudesReceived: numberValue(source.gratitudesReceived),
    availableForReferrals: source.availableForReferrals !== false,
    weeklyReferralCapacity: numberValue(source.weeklyReferralCapacity, 5),
    createdAt: source.createdAt ?? null,
    updatedAt: source.updatedAt ?? source.lastActiveAt ?? projectionUpdatedAt,
  };
}

function valueAfter(argv, name) {
  const index = argv.indexOf(name);
  if (index === -1) return undefined;
  const value = argv[index + 1];
  if (!value || value.startsWith('--')) {
    throw new Error(`${name} requires a value.`);
  }
  return value;
}

function parseOptions(argv) {
  const apply = argv.includes('--apply');
  const rollback = argv.includes('--rollback');
  if (apply && rollback) {
    throw new Error('Choose either --apply or --rollback, not both.');
  }
  const projectId = valueAfter(argv, '--project');
  const confirmation = valueAfter(argv, '--confirm-project');
  const runId = valueAfter(argv, '--run-id');
  if (!projectId) {
    throw new Error('--project is required; implicit ADC project selection is forbidden.');
  }
  if ((apply || rollback) && confirmation !== projectId) {
    throw new Error('--confirm-project must exactly match --project for writes.');
  }
  if ((apply || rollback) && !runId) {
    throw new Error('--run-id is required for apply and rollback.');
  }
  if (runId && !/^[A-Za-z0-9_-]{8,80}$/.test(runId)) {
    throw new Error('--run-id must be 8-80 letters, numbers, underscores, or hyphens.');
  }
  return {apply, rollback, projectId, runId};
}

function initializeDatabase(projectId) {
  if (!getApps().length) {
    initializeApp({credential: applicationDefault(), projectId});
  } else if (getApps()[0].options.projectId !== projectId) {
    throw new Error('Firebase Admin is already initialized for a different project.');
  }
  return getFirestore();
}

async function commitInChunks(db, operations) {
  for (let index = 0; index < operations.length; index += batchLimit) {
    const batch = db.batch();
    for (const operation of operations.slice(index, index + batchLimit)) {
      operation(batch);
    }
    await batch.commit();
  }
}

async function migrate(db, options) {
  const users = await db.collection('users').get();
  const operations = [];
  const runRef = options.runId
    ? db.collection(backupCollection).doc(options.runId)
    : null;

  for (const userDoc of users.docs) {
    const publicRef = db.collection(publicCollection).doc(userDoc.id);
    const backupRef = runRef?.collection('profiles').doc(userDoc.id);
    const existing = await publicRef.get();
    const projected = buildPublicProfile(
      userDoc.id,
      userDoc.data(),
      userDoc.updateTime ?? null,
    );

    operations.push((batch) => {
      if (backupRef) {
        batch.create(backupRef, {
          existed: existing.exists,
          previous: existing.exists ? existing.data() : null,
          migratedAt: FieldValue.serverTimestamp(),
        });
      }
      batch.set(publicRef, projected);
    });
  }

  console.log(
    `${options.apply ? 'Migrating' : 'Would migrate'} ${users.size} public profile(s).`,
  );
  if (options.apply) {
    await runRef.create({
      projectId: options.projectId,
      status: 'started',
      createdAt: FieldValue.serverTimestamp(),
    });
    await commitInChunks(db, operations);
    await runRef.update({status: 'complete', profileCount: users.size});
  }
}

async function restore(db, options) {
  const runRef = db.collection(backupCollection).doc(options.runId);
  const run = await runRef.get();
  if (!run.exists || run.data()?.projectId !== options.projectId) {
    throw new Error('The requested migration run does not exist for this project.');
  }
  const backups = await runRef.collection('profiles').get();
  const operations = [];

  for (const backupDoc of backups.docs) {
    const backup = backupDoc.data();
    const publicRef = db.collection(publicCollection).doc(backupDoc.id);
    operations.push((batch) => {
      if (backup.existed && backup.previous) {
        batch.set(publicRef, backup.previous);
      } else {
        batch.delete(publicRef);
      }
    });
  }

  console.log(
    `Restoring ${backups.size} public profile(s) from immutable run ${options.runId}.`,
  );
  await commitInChunks(db, operations);
  await runRef.update({
    status: 'rolled-back',
    rolledBackAt: FieldValue.serverTimestamp(),
  });
}

async function main(argv = process.argv.slice(2)) {
  const options = parseOptions(argv);
  const db = initializeDatabase(options.projectId);
  await (options.rollback ? restore(db, options) : migrate(db, options));
}

module.exports = {buildPublicProfile, main, parseOptions, publicFields};

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}

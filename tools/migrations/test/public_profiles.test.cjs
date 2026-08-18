'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {describe, it} = require('node:test');
const {
  buildPublicProfile,
  parseOptions,
  publicFields,
} = require('../public_profiles.cjs');

describe('public profile migration safety', () => {
  it('requires an explicit project and confirmation for writes', () => {
    assert.throws(() => parseOptions([]), /--project is required/);
    assert.throws(
      () => parseOptions(['--project', 'prod', '--apply', '--run-id', 'run-12345']),
      /--confirm-project must exactly match/,
    );
    assert.throws(
      () => parseOptions(['--project', 'prod', '--confirm-project', 'prod', '--apply']),
      /--run-id is required/,
    );
    assert.deepEqual(
      parseOptions([
        '--project', 'prod', '--confirm-project', 'prod',
        '--apply', '--run-id', 'run-12345',
      ]),
      {apply: true, rollback: false, projectId: 'prod', runId: 'run-12345'},
    );
  });

  it('matches and normalizes the canonical projection schema', () => {
    const canonicalSource = fs.readFileSync(
      path.resolve(__dirname, '../../../functions/src/profiles/projection.ts'),
      'utf8',
    );
    const interfaceBody = canonicalSource.match(
      /interface PublicProfileProjection \{([\s\S]*?)\n\}/,
    )?.[1];
    assert.ok(interfaceBody, 'canonical projection interface must be readable');
    const canonicalFields = [...interfaceBody.matchAll(/^\s+(\w+):/gm)]
      .map((match) => match[1]);
    assert.deepEqual(publicFields, canonicalFields);

    const projected = buildPublicProfile('user-1', {
      role: 'provider',
      name: 'Ada',
      company: '',
      skills: ['Dart', 7],
      preferredRoles: ['Engineer'],
      responseRate: Number.NaN,
      lastActiveAt: 'last-active',
    }, 'projection-time');

    assert.deepEqual(Object.keys(projected), publicFields);
    assert.equal(projected.role, 'provider');
    assert.equal(projected.company, null);
    assert.deepEqual(projected.skills, ['Dart']);
    assert.equal(projected.responseTime, '< 48h');
    assert.equal(projected.avgResponseHours, 48);
    assert.equal(projected.responseRate, 1);
    assert.equal(projected.updatedAt, 'last-active');
  });
});

# Public profile migration

This migration uses Firebase Admin SDK with Application Default Credentials or
the Firestore emulator. It contains no service-account keys or project secrets.

```sh
npm install
npm run public-profiles:dry-run -- --project refsure-d6e3a
npm run public-profiles:apply -- --project refsure-d6e3a \
  --confirm-project refsure-d6e3a --run-id 20260803-public-profiles
npm run public-profiles:rollback -- --project refsure-d6e3a \
  --confirm-project refsure-d6e3a --run-id 20260803-public-profiles
```

The explicit project is mandatory even when ADC already identifies a project.
Write operations additionally require an exact project confirmation and a
unique run ID. For local testing, set `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080`
and pass `--project refsure-rules-test`.

Dry-run is the default. `--apply` writes sanitized projections to
`publicProfiles` using the same normalized schema as the continuous projection.
Each apply stores create-only backups under
`_migration_public_profiles_v2/{runId}/profiles`; rerunning the same ID fails
instead of overwriting rollback data. Rollback retains the immutable backup and
marks the run as rolled back.

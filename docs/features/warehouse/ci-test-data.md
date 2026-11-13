---
sources:
  - .github/workflows/s3_test_data/action.yml
  - .github/workflows/rails_tests.yml
  - .github/workflows/lsa_integration_test.yml
  - .github/workflows/test_kit_fixpoints.yml
  - .github/workflows/scheduled_gh_cache_cleaning.yml
---

# CI Test Data from S3

Some test data is not ours to redistribute: it is provided to vendors through a private channel. It is gitignored and lives in a private S3 bucket. CI fetches it with the `s3_test_data` composite action, which keeps an encrypted copy in the GitHub Actions cache so most runs skip the S3 download.

**What this document answers**

- Which data sets CI fetches from S3, and where they land
- When CI downloads from S3 versus restoring from the cache
- How to set up or rotate `ACTION_ASSET_ENCRYPTION_KEY`
- How to update fixpoint files in S3

## Data sets

| Cache name | S3 prefix | Local destination | Used by |
|---|---|---|---|
| `testkit-source` | `vars.AWS_S3_ACTIONS_SOURCE_PATH_FY_2026` | `drivers/datalab_testkit/spec/fixtures/inputs/` | `rails_tests.yml`, `test_kit_fixpoints.yml` |
| `testkit-fixpoints` | `vars.AWS_S3_ACTIONS_FIXPOINT_PATH_FY_2026` | `drivers/datalab_testkit/spec/fixpoints/` | `rails_tests.yml` |
| `testkit-results` | `vars.AWS_S3_ACTIONS_RESULTS_PATH_FY_2026` | `drivers/datalab_testkit/spec/fixtures/results/` | `rails_tests.yml` |
| `lsa-sample` | `lsa-sample-09-2026/` | `drivers/hud_lsa/spec/fixtures/files/lsa/fy2027/` | `lsa_integration_test.yml` |

Every prefix is relative to the bucket in `secrets.AWS_S3_ACTION_BUCKET`. Files ending in `.gz` are decompressed into the destination with the suffix removed; other files are copied as-is.

## Caching

The cache key is `s3-test-data-<name>-<hash>`, where the hash covers the key and ETag of every object under the prefix plus a digest of the encryption key. Adding, removing, or replacing any object in S3 changes the hash, so the next run downloads from S3 and saves a new cache entry. Otherwise the run restores the cached copy.

A pull request run can restore caches saved on its base branch. The nightly `scheduled_gh_cache_cleaning.yml` job deletes every cache except the newest `s3-test-data-*` entry per data set on `main`.

## Cache encryption

This repository is public, and workflows run from fork pull requests can restore caches saved on the base branch. They never receive repository secrets. The action therefore caches only a tar of the data encrypted with `openssl enc -aes-256-cbc -pbkdf2`, using the `ACTION_ASSET_ENCRYPTION_KEY` repository secret. A fork run that restores the cache gets bytes it cannot decrypt.

If the secret is missing or empty, the action fails on its first step.

### Set up or rotate the key

Generate a new random key and store it as the repository secret. You never need the value again, so don't keep a copy.

```bash
openssl rand -base64 48 | gh secret set ACTION_ASSET_ENCRYPTION_KEY --repo greenriver/hmis-warehouse
```

**Rotation:** The cache key includes a digest of the encryption key, so after a rotation the next run on each branch misses the cache, downloads from S3, and saves a cache entry encrypted with the new key. Entries encrypted with the old key are no longer restored, and the nightly cleanup or GitHub's cache eviction removes them.

### If the key is exposed

Rotate the key as above, then delete the existing caches so the old ciphertext is gone:

```bash
gh cache list --repo greenriver/hmis-warehouse --key s3-test-data- --limit 1000 --json id --jq '.[].id' \
  | xargs -n1 gh cache delete --repo greenriver/hmis-warehouse
```

## Updating fixpoint files

The `test_kit_fixpoints.yml` workflow rebuilds the fixpoints. It runs on `workflow_dispatch`, or on a push whose head commit message contains `[gh:rebuild_fixpoints]` when the `CI_AUTO_RUN` variable is `true`. It copies the current fixpoints to `vars.AWS_S3_ACTIONS_PREVIOUS_FIXPOINT_PATH_FY_2026` under a dated folder, gzips the new `.sql` files, and syncs them to the current prefix with `--delete`.

To upload fixpoints by hand, gzip them first and replace the S3 contents with the `.gz` copies:

```bash
gzip -k -n warehouse_test.sql warehouse_app_test.sql
```

## Adding a data set

Call the action after the AWS credentials step, with a `name` not used by any other data set:

```yaml
- name: "Fetch example data"
  uses: ./.github/workflows/s3_test_data
  with:
    name: example-data
    source: ${{ secrets.AWS_S3_ACTION_BUCKET }}example-prefix/
    destination: ./path/to/fixtures/
    encryption_key: ${{ secrets.ACTION_ASSET_ENCRYPTION_KEY }}
```

Add the destination to `.gitignore` and add a row to the table above.

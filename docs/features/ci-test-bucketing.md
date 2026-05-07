# CI Test Bucketing & Routing System

The CI parallelizes the RSpec test suite by distributing tests into balanced groups ("buckets") based on their historical execution time, and routes system tests to specialized environments.

## Core Mechanics

### 1. Bucket Configuration (`.github/rspec_buckets.json`)
Test assignments are stored in `.github/rspec_buckets.json`. This file maps spec files to specific bucket IDs (e.g., `bucket-1`, `bucket-2`).

### 2. Tag Injection (`ci:update_spec_tags`)
Inside each parallel CI job, the `ci:update_spec_tags` rake task runs *before* the tests. It dynamically modifies the spec files on the runner's filesystem, injecting a `ci_bucket: 'bucket-id'` tag into the top-level `RSpec.describe` block. This ensures RSpec can filter tests using standard tags even though the tags aren't committed to the source repository.

### 3. Matrix Routing (`bin/ci_matrix_router.rb`)
A standalone Ruby script determines which test categories (Unit, HMIS System, Warehouse System) should run.
*   **Sharding**: It reads the buckets file and creates one job per bucket.
*   **Coverage**: It always adds a "default" job with the `~ci_bucket` tag to catch any tests not explicitly assigned to a bucket, ensuring no tests are skipped.
*   **Logic**: It determines the matrix based on the event type and commit message flags.

---

## Developer Workflows

### Standard CI Run
By default, every Pull Request triggers:
1.  **Unit/Functional Tests**: Sharded into parallel buckets.
2.  **HMIS System Tests**: A dedicated job that builds the React frontend.
3.  **Warehouse System Tests**: A dedicated job for Rails-side system tests.

### Targeted Test Execution (Focused Runs)
If you are debugging a specific test, you can bypass the full suite to save time. This triggers a "Focused Run" with exactly one job running only the requested tests.

#### Trigger via Commit Message
Add `ci-focus: <path>` to your commit message.
*   **Single file**: `git commit -m "debugging [ci-focus: spec/models/user_spec.rb]"`
*   **Directory**: `git commit -m "debugging [ci-focus: spec/requests]"`

#### Available Flags
Flags can be included anywhere in the commit message (**outside** of the `ci-focus` brackets):
*   `with-okta`: Runs Okta request specs (Omniauth/Sessions).
*   `with-logging`: Runs the 5-way logging configuration matrix.
*   `testkit-check-all-results`: Ignores the `skip` option in table comparisons, forcing all cells to be checked.
*   `ci-profile`: Enables RSpec profiling and outputs `rspec_results.json`.

**Example combining focus and flags:**
`git commit -m "debugging [ci-focus: drivers/hud_spm_report/spec/models/datalab_testkit/all_projects_spec.rb] testkit-check-all-results"`

#### Trigger via GitHub UI
1. Go to **Actions** -> **Rails Tests** -> **Run workflow**.
2. Enter the path in **test_path** and check any required flags.

---

## Maintenance: Rebalancing Buckets

To update the bucket distribution when test times change significantly:

### 1. Generate Profile Data in CI
Trigger a CI run with the profiling flag enabled. Profiling is done in CI to ensure timing data is consistent with the CI runner's hardware:
*   **Commit message**: `git commit --allow-empty -m "rebalance buckets [ci-profile]"`
*   **GitHub UI**: Check **Enable RSpec profiling** when running the workflow.

This will upload artifacts named `artifacts-unit-*` containing `rspec_results.json`.

### 2. Download and Analyze Data
1. Download the profiling artifacts from the GitHub Actions run summary.
2. Unzip them into a local directory (e.g., `tmp/rspec_profiles`).
3. (Optional) Run `bundle exec rails ci:profile_stats[tmp/rspec_profiles]` to see a statistical breakdown of your test runtimes.

### 3. Build New Assignments
Run the rebalancing task locally:
```bash
bundle exec rails ci:build_bucket_assignments[tmp/rspec_profiles]
```
This uses a bin-packing algorithm to generate a new `.github/rspec_buckets.json`.

### 4. Commit Changes
Commit the updated `.github/rspec_buckets.json` to the repository.

# CI Test Bucketing & Routing System

The CI parallelizes the RSpec test suite by distributing tests into balanced groups ("buckets") based on their historical execution time, and routes system tests to specialized environments.

## Core Mechanics

### 1. Bucket Configuration (`.github/rspec_buckets.json`)
Test assignments are stored in `.github/rspec_buckets.json`. This file maps spec files to specific bucket IDs (e.g., `bucket-1`, `bucket-2`).

### 2. Tag Injection (`ci:update_spec_tags`)
Inside each parallel CI job, the `ci:update_spec_tags` rake task runs *before* the tests. It dynamically modifies the spec files on the runner's filesystem, injecting a `ci_bucket: 'bucket-id'` tag into the top-level `RSpec.describe` block.

### 3. Matrix Routing (`bin/ci_matrix_router.rb`)
A standalone Ruby script determines which test categories (Unit, HMIS System, Warehouse System) should run based on the event type and commit message. This script is used by the `determine_matrix` job in `.github/workflows/rails_tests.yml`.

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
Flags can be included anywhere in the commit message (separate from `ci-focus`):
*   `with-okta`: Runs Okta request specs (Omniauth/Sessions).
*   `with-logging`: Runs the 5-way logging configuration matrix.
*   `ci-profile`: Enables RSpec profiling and outputs `rspec_results.json`.

#### Trigger via GitHub UI
1. Go to **Actions** -> **Rails Tests** -> **Run workflow**.
2. Enter the path in **test_path** and check any required flags.

---

## Maintenance: Rebalancing Buckets

To update the bucket distribution when test times change significantly:

### 1. Generate Profile Data in CI
Trigger a CI run with the profiling flag enabled:
*   **Commit message**: `git commit --allow-empty -m "rebalance buckets [ci-profile]"`
*   **GitHub UI**: Check **Enable RSpec profiling** when running the workflow.

This will upload an artifact named `artifacts-unit-*` containing `rspec_results.json`.

### 2. Download and Prepare Data
1. Download the profiling artifacts from the GitHub Actions run summary.
2. Unzip them into a local directory (e.g., `tmp/rspec_profiles`).
3. You should have one `.json` file per parallel job.

### 3. Build New Assignments
Run the rebalancing task locally:
```bash
bundle exec rails ci:build_bucket_assignments[tmp/rspec_profiles]
```
This uses a bin-packing algorithm to generate a new `.github/rspec_buckets.json`.

### 4. Commit Changes
Commit the updated `.github/rspec_buckets.json` to the repository.

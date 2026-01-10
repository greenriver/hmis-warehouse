# CI Test Bucketing System

The system parallelizes the RSpec test suite in Continuous Integration (CI) by distributing tests into balanced groups ("buckets") based on their historical execution time.

## Overview

The system uses a bin-packing algorithm to assign spec files to buckets, ensuring even distribution of test runtime across parallel CI jobs. This reduces the overall wall-clock time for the full test suite.

## Components

### 1. Bucket Configuration
The assignments are stored in `.github/rspec_buckets.json`. This file maps spec files to specific bucket IDs (e.g., `bucket-1`, `bucket-2`).

### 2. Rake Tasks (`lib/tasks/ci.rake`)
The `ci` namespace provides tools for managing buckets:

*   **`ci:build_bucket_assignments`**: Analyzes RSpec profile data (`rspec_results.json`) to create or update the bucket configuration. It uses a bin-packing algorithm with overhead multipliers (accounting for setup/teardown).
*   **`ci:update_spec_tags`**: Reads the bucket configuration and modifies the actual spec files in the codebase, adding or updating the `ci_bucket: 'bucket-id'` metadata tag to the top-level `RSpec.describe` block.
*   **`ci:profile_stats`**: Provides statistical analysis of RSpec profile data to help tune the bucketing strategy (optional)

### 3. CI Workflow (`.github/workflows/rails_tests.yml`)
The GitHub Actions workflow orchestrates the execution of unit tests, HMIS system tests, and warehouse system tests in a single unified pipeline.

The complex logic for determining which tests to run and how to shard them is encapsulated in `bin/ci_matrix_router.rb`.

1.  **Matrix & Routing Generation**: The `determine_matrix` job calls `bin/ci_matrix_router.rb` which decides which test jobs to spin up based on the presence of a "focused run" tag or whether it's a pull request.
    *   It creates a matrix for unit tests (bucketed or focused).
    *   It triggers `hmis_system_tests` and `warehouse_system_tests` as needed.
2.  **Tag Injection**: In parallel unit test jobs, the `ci:update_spec_tags` rake task runs *before* the tests.
3.  **Test Execution**: RSpec runs with the appropriate filters or targeted paths.

## Workflow

### Targeted Test Execution (Focused Runs)

If you are debugging a specific test and want to bypass the full suite to save time, you can trigger a "Focused Run". This will create a matrix with exactly one job running only the requested tests.

**Smart Routing:**
The CI automatically routes your focused path to the correct environment:
*   **Unit/Functional Tests**: Runs in the standard parallelizable environment.
*   **HMIS System Tests (`drivers/hmis/spec/system/hmis/`)**: Triggers the job that builds the React frontend.
*   **Warehouse System Tests (`spec/system/rails/`)**: Triggers the dedicated warehouse system test job.

When a focused run is active for a specific category, the other categories will automatically skip to save resources.

#### Trigger via Commit Message
Add `ci-focus: <path>` to your commit message (anywhere in the message).

**Format**: `ci-focus:` followed by the spec path (spaces after the colon are optional)

*   **Single file**: `git commit -m "debugging [ci-focus: spec/models/user_spec.rb]"`
*   **Directory**: `git commit -m "debugging [ci-focus: spec/requests]"`
*   **Multiple paths**: `git commit -m "debugging [ci-focus: spec/models/user_spec.rb spec/models/post_spec.rb]"`

Optional flags (can be included anywhere in the commit message, separate from ci-focus):
*   `with-okta`: Runs Okta request specs (Omniauth/Sessions). Use if debugging login or session logic.
*   `with-logging`: Runs the 5-way logging configuration matrix. Use if modifying environment log settings.

**Example combined usage:**
`git commit -m "fix session timeout [ci-focus: spec/requests/sessions_spec.rb] with-okta"`

#### Trigger via GitHub UI
1.  Go to the **Actions** tab in GitHub.
2.  Select the **Rails Tests** workflow.
3.  Click **Run workflow**.
4.  Enter the file or directory path in the **test_path** input.
5.  Check **Run Okta integration tests** or **Run logging configuration tests** if needed.

---

### Rebalancing Buckets

To update the bucket distribution (e.g., when test times change significantly):

1.  **Generate Profile Data in CI**:
    *   Modify `.github/workflows/rails_tests.yml` to enable RSpec profiling (uncomment the lines generating `rspec_results.json`).
    *   Commit and push this change to trigger a CI build.
    *   The workflow will capture profiling information and upload it as an artifact named `rspec_profiles`.
    *   *Note: Profiling is typically not done locally due to hardware differences and parallelization.*
2.  **Download Artifacts**:
    *   Go to the GitHub Actions run summary.
    *   Download the `rspec_profiles` artifact containing the `rspec_results.json` files.
    *   Unzip the artifacts into a local directory (e.g., `tmp/rspec_profiles`).
3.  **Generate Assignments**:
    *   Run `bundle exec rails ci:build_bucket_assignments[tmp/rspec_profiles]`.
4.  **Commit Changes**:
    *   Commit the updated `.github/rspec_buckets.json` file.

### Execution in CI

When CI runs:
1.  The workflow parses the buckets file.
2.  It spawns parallel jobs.
3.  **Source Modification**: Inside each job, the `ci:update_spec_tags` rake task runs and explicitly modifies the spec files on the runner's filesystem. It parses the source code, finds the `RSpec.describe` block, and injects the `ci_bucket: 'bucket-id'` tag directly into the file content.
4.  **Test Execution**: RSpec runs using the `--tag` filter (e.g., `--tag ci_bucket:bucket-1`), which matches the tags that were just injected into the source code.

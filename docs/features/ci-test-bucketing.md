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
The GitHub Actions workflow orchestrates the execution:

1.  **Matrix Generation**: The `determine_matrix` job reads `.github/rspec_buckets.json` and dynamically generates a build matrix.
    *   It creates a job for each defined bucket (tag: `ci_bucket:bucket-N`).
    *   It adds a "default" job for any tests *not* in a specific bucket (tag: `~ci_bucket`).
2.  **Tag Injection**: In each parallel job, the `ci:update_spec_tags` rake task runs *before* the tests. This ensures the source code on the runner has the correct tags for filtering, even if the source repository doesn't permanently store these tags.
3.  **Test Execution**: RSpec runs with `--tag ci_bucket:bucket-N` (or `~ci_bucket` for the default group), executing only the relevant tests for that shard.

## Workflow

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

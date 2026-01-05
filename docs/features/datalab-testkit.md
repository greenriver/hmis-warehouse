# Datalab Testkit

The Datalab Testkit verifies HUD report implementations against reference data provided by an external vendor. It ensures that the HMIS warehouse produces report results consistent with a reference implementation on real-world HUD data sets.

## Architecture & Integration

The testkit integrates with the HMIS report framework to compare generated report outputs with reference CSV files. It supports the following HUD reports:
- **APR** (Annual Progress Report)
- **CAPER** (Consolidated Annual Performance and Evaluation Report)
- **SPM** (System Performance Measures)
- **PATH** (Projects for Assistance in Transition from Homelessness)
- **CE-APR** (Coordinated Entry APR)

Tests leverage a shared RSpec context (`datalab testkit context`) that manages the test lifecycle, data isolation, and provides comparison utilities.

### Data Preparation
The testkit manages large HUD data sets through a two-tier system:
1. **Raw Fixtures**: Anonymized HUD CSV files located in `drivers/datalab_testkit/spec/fixtures/inputs`.
2. **Fixpoints**: Database snapshots (managed via `PgFixtures`) stored in `drivers/datalab_testkit/spec/fixpoints`.

During test `setup` (invoked in a `before(:all)` block):
- The database is cleared of existing HMIS and warehouse data.
- The testkit attempts to restore from fixpoints for performance.
- If fixpoints are missing, it performs a fresh import of the raw CSV fixtures and generates new fixpoints.

**Important Note on Transactionality**: These tests are **non-transactional**. Data is loaded once for the entire spec file in a `before(:all)` block using database restoration techniques that bypass standard RSpec transactions. This is necessary due to the volume of data required for HUD reporting. As a result, individual tests that modify data must be handled with care to avoid side effects on subsequent tests. A `cleanup` routine runs in `after(:all)` to reset the environment.

### Result Validation
Comparisons are performed cell-by-cell against reference CSVs using `DatalabTestkit::TableComparisons#compare_results`.

The validation process includes:
- **Normalization**: Values are normalized to handle formatting differences. This includes stripping currency/percent symbols, rounding floats to four decimal places, and treating blanks as zero where appropriate.
- **Internal Consistency**: Some tests validate report integrity by checking sums and cross-table references defined in `tup_validations.csv`.
- **Detail Logging**: When comparisons fail, the testkit can log underlying universe data for the discrepant cells to assist in debugging.

## Maintenance & Troubleshooting

### Handling Discrepancies
Discrepancies often arise from ambiguities in HUD specifications or issues in the reference data itself. These are managed by:
- **Skipping Cells**: Known issues can be bypassed by passing cell coordinates (e.g., `skip: ['B2', 'C5']`) to the `compare_results` method.
- **Investigation**: Developers can use the `detail_columns` parameter to inspect the specific records contributing to a discrepant cell value.

### Rebuilding Fixpoints

Fixpoints should be rebuilt when the underlying HUD data sets are updated or when systematic changes to the import process occur. This is done by including `[gh:rebuild_fixpoints]` in a commit message, which triggers the `test_kit_fixpoints.yml` workflow.

### Support Utilities

Several utilities assist in maintaining the testkit fixtures:

- **`DatalabTestkit::TestkitSpmXlsxToCsv`**: Translates SPM results from `.xlsx` files into the CSV format used for Warehouse tests.
  ```ruby
  DatalabTestkit::TestkitSpmXlsxToCsv.new(directory).convert("excel_filename.xlsx")
  ```

- **`DatalabTestkit::TestkitCsvMerge`**: Consolidates multiple HMIS zip export directories into a single source. This is used when updating the test kit with new raw data sets.
  ```ruby
  source_dirs = Dir.glob('var/csvs/*')
  destination_dir = 'drivers/datalab_testkit/spec/fixtures/inputs/merged/source'
  DatalabTestkit::TestkitCsvMerge.new(source_dirs, destination_dir).merge_dirs
  ```

### Updating Raw Data

When a new version of the test kit is released:

1. Extract all provided HMIS zip files into subdirectories of `var/csvs/`.
2. Run the `TestkitCsvMerge` utility (see above) to consolidate them into `drivers/datalab_testkit/spec/fixtures/inputs/merged/source`.
3. Ensure `skip_location_cleanup: true` is set during the import process.

#### Location Cleanup Note
By default, `GrdaWarehouse::Tasks::ProjectCleanup` (called in `HmisCsvImporter::Importer::Importer#post_process`) attempts to reconcile and "fix" CoC Codes. However, Test Kits often include intentional data anomalies, such as invalid CoC codes, to test report robustness. Setting `skip_location_cleanup: true` ensures these codes are preserved exactly as they appear in the source CSVs.

## Entry Points

Tests leveraging the Datalab Testkit are found in report-specific spec directories:
- `drivers/hud_apr/spec/models/fy2026/datalab_2_0_spec.rb`: Main entry point for APR, CAPER, and CE-APR tests.
- `drivers/hud_spm_report/spec/models/datalab_testkit/all_projects_spec.rb`: Entry point for SPM tests.
- `drivers/hud_path_report/spec/models/fy2026/datalab_2026_spec.rb`: Entry point for PATH tests.
- `drivers/datalab_testkit/spec/models/datalab_testkit_context.rb`: Shared RSpec context for setting up the test environment.

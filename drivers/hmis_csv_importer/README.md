# HMIS CSV Importer

This feature imports, normalizes, and validates HMIS CSV data in the HUD standard format into the data warehouse.

## Architecture

The importer operates in two distinct phases: Loading and Importing.

### Loader

The Loader (`HmisCsvImporter::Loader`) ingests raw CSV files from a directory. It normalizes file names and headers, detects the HUD CSV version, and loads the raw data into temporary staging tables. It handles:

- Version detection and auto-migration of older formats.
- Normalization of CSV headers (case-insensitive mapping).
- Bulk loading of raw string data via PostgreSQL `COPY`.

### Importer

The Importer (`HmisCsvImporter::Importer`) processes the staged data into the warehouse. It validates the data, transforms it into typed records, and merges it with existing warehouse data.

The import process follows these stages:

1. **Pre-processing**: Converts raw strings to typed values, calculates checksums for change detection, and runs row-level validations.
2. **Validation**: Executes complex, cross-record validations on the dataset.
3. **Aggregation**: (Optional) Combines records based on configured rules (e.g., merging split enrollments).
4. **Cleanup**: Runs data correction tasks to fix known data quality issues (e.g., broken relationships).
5. **Ingestion**: Merges the processed data into the warehouse.

## Ingestion Logic

The ingestion phase reconciles the imported data with the existing warehouse state:

- **Scope**: Operations are scoped to the projects and date range defined in the source files (`Export.csv` and `Project.csv`).
- **Change Detection**: Uses checksums and `DateUpdated` timestamps to identify changed records.
- **Updates**: Updates existing records if the incoming data is newer or if the source checksum differs.
- **Deletions**: Soft-deletes records that exist in the warehouse within the import scope but are missing from the import file.

## Integration

The importer connects with:

- **Data Sources**: Each import is associated with a `DataSource`, which defines configuration and thresholds for error reporting.
- **Jobs**: Background jobs handle the execution and cleanup of imports.
- **Notifications**: Specific thresholds (errors, record counts) trigger notifications to configured users.

## Validation

Data quality is enforced via `HmisCsvValidation`. Validators define rules that can either warn (log error but continue) or block (exclude row) depending on severity.

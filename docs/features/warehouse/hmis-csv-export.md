---
sources:
  - app/models/filters/hmis_export.rb
  - app/models/concerns/export/scopes.rb
  - app/models/export/restricted_client_pii_transform.rb
  - app/models/grda_warehouse/fake_data.rb
  - app/controllers/warehouse_reports/hmis_exports_controller.rb
  - drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/client.rb
  - drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/client/overrides.rb
  - drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/export_concern.rb
---

# HMIS CSV Export

The HMIS CSV Export feature produces HUD-compliant CSV datasets packaged as zip files. It extracts data from the warehouse database into the standardized HUD CSV format used for data exchange between HMIS systems.

## Architecture

The export system uses a multi-version driver architecture. Each HUD CSV version (2022, 2024, 2026) is implemented as a separate driver under `/drivers/hmis_csv_twenty_twenty_*`. The filter model (`Filters::HmisExport`) maintains a registry of available versions and routes export requests to the appropriate driver.

1. User creates export via `HmisExportsController`
2. Controller creates `Filters::HmisExport` configuration
3. Job queued to Delayed Job
4. Version-specific `ExportJob` executes
5. `Exporter::Base` instantiated
6. CSV files generated
7. Files packaged into zip archive
8. Zip uploaded to ActiveStorage
9. User downloads completed export

Only the 2024 and 2026 drivers are selectable. The 2022 driver's `register_version` line is commented out, and the 2020 driver has an importer but no exporter. `Filters::HmisExport` silently ignores a `version` that isn't registered. The 2022 and 2024 exporters are frozen near-copies of 2026, so a fix in 2026 doesn't propagate. To add a version, copy the newest driver and register it, rather than editing an older one.

## Export Configuration

Exports are configured through `Filters::HmisExport` with the following parameters:

- **Date range**: Start and end dates for the reporting period
- **Projects**: Selected projects, project groups, organizations, or data sources
- **CoC codes**: Limits export to projects operating in specified Continuum of Care codes
- **Period type**: Determines which records are included (operating period, update period, etc.)
- **Directive**: Controls data completeness (projects only, projects and related, etc.)
- **Hash status**: PII hashing level (see [De-identification Options](#de-identification-options) below)
- **Faked PII**: Replaces sensitive fields with realistic fake data (see [De-identification Options](#de-identification-options) below)
- **Include deleted**: Whether to export soft-deleted records
- **Custom files**: Optional custom CSV files defined via the custom files configuration

An empty project selection means every project the user can view. Confidential projects are excluded unless the user can view confidential project names. Period type 2 (effective) is not implemented and raises; the form offers only operating (3) and update (1). Choosing the update period forces `include_deleted`, because updated-period exports need deleted rows.

## Export Process

### Job Execution

The controller schedules a version-specific export job (e.g., `HmisCsvTwentyTwentySix::ExportJob`) via Delayed Job. The job instantiates the exporter and calls `export!`.

### CSV Generation

The exporter (`HmisCsvTwentyTwentySix::Exporter::Base`) generates CSV files using Kiba ETL:

1. **Setup**: Creates a temporary directory and initializes the `GrdaWarehouse::HmisExport` record
2. **Export.csv**: Generates the export metadata file
3. **Data files**: Iterates through `exportable_files` to produce each HUD CSV file:
   - Organization.csv, Project.csv, Inventory.csv, ProjectCoC.csv
   - Client.csv, Enrollment.csv, Exit.csv
   - Service.csv, Assessment.csv, Event.csv
   - Disability.csv, EmploymentEducation.csv, IncomeBenefit.csv, HealthAndDv.csv
   - CurrentLivingSituation.csv, YouthEducationStatus.csv
   - HMISParticipation.csv, CEParticipation.csv
   - User.csv (last, collected from referenced users in other files)
   - Custom*.csv (if configured)

Each file export:
- Queries data using scopes defined in the exporter class
- Loads results into a temporary PostgreSQL table within a `repeatable_read` transaction
- Transforms rows through the `ExportConcern` pipeline (assigns ExportID, enforces field lengths, applies rounding)
- Writes to CSV using `CsvDestination`

### Archive and Storage

After CSV generation completes:

1. `zip_archive` collects all CSV files and creates a zip file using the `Zip::File` library
2. `upload_zip` attaches the zip to the `GrdaWarehouse::HmisExport` record via ActiveStorage
3. The export record is marked complete with `completed_at`
4. The temporary directory and CSV files are removed

### Download

Users download exports through `HmisExportsController#show`, which serves the zip file via `send_data` from the ActiveStorage attachment.

`show`, `destroy`, `edit`, `update`, and `cancel` load the export through `export_scope`, the same scope as the export list: users with `can_view_all_reports` reach any export, and other users reach only exports they ran. Any other export returns 404. The hashed-only controller narrows `export_scope` to hashed exports, so its pages can't load an unhashed export.

## Data Scoping

The exporter includes three main scoping methods:

- **`project_scope`**: Returns projects, organizations, inventories, funders, and project-level records
- **`enrollment_scope`**: Returns enrollments and enrollment-related records (services, assessments, exits, etc.)
- **`client_scope`**: Returns clients associated with in-scope enrollments

Scopes apply the configured filters (date range, project selection, deleted records) and enforce CoC restrictions when specified.

`client_scope` and `enrollment_scope` also apply external data sharing exclusions when the
`:enable_external_data_sharing_exclusion` config flag is enabled — see
[external-data-sharing-exclusion.md](external-data-sharing-exclusion.md).

## Custom Files

The 2026 exporter supports custom CSV files defined through the custom files configuration system. Custom files follow the HUD CSV template structure but include additional fields. They are configured via YAML and implement:

- Custom importer class under `HmisCsvTwentyTwentySix::Importer::Custom`
- Custom exporter class under `HmisCsvTwentyTwentySix::Exporter::Custom`

Custom files are only exported when explicitly selected in the export configuration.

## De-identification Options

The export supports two distinct de-identification mechanisms intended for different use cases:

### SHA-256 Hashing (hash_status = 4)

Applies one-way SHA-256 hashing to name fields (FirstName, MiddleName, LastName) and SSN. Hashed values are deterministic — the same input always produces the same hash — enabling cross-system deduplication without exposing PII. This is the HUD-defined "SHA-256 (RHY)" approach. All other fields remain unchanged.

The "Hashed Only" export UI forces this setting and is available to users with fewer permissions than the full export.

### Faked PII

Replaces sensitive fields with realistic-looking fabricated data (names, SSN, DOB, addresses, project/organization names, contact info, and free-text fields). Fake values are consistent within an export and across exports in the same environment — the same real value always maps to the same fake value, persisted in `GrdaWarehouse::FakeData` — so referential integrity is preserved. This is intended for producing sample files safe for developers to use locally, or for use in staging environments. While the intention is to remove all PII, it is not guaranteed, and output should not be shared externally without detailed review. 

### When to use which

| Goal | Mechanism |
|------|-----------|
| Share sample data with a vendor for testing | Faked PII in conjunction with full review or fake source data |
| Produce a developer-friendly dataset | Faked PII |
| HUD-compliant de-identification for RHY | SHA-256 Hashing |

Only the hashed-only export UI prevents combining the two; the full form permits both. In a combined run, hashing runs first, so `MiddleName` is hashed (it isn't in the faked list) while first name, last name, and SSN are faked, and `Export.csv` still says `HashStatus` 4.

Name hashing is SHA-256 of the Soundex code, not the raw name, so two names with the same Soundex produce the same hash. The SSN hash is prefixed with its last four digits in the clear.

### Restricted clients

`Export::RestrictedClientPiiTransform` always runs last on `Client.csv`. It redacts names, nulls the SSN, and sets SSN data quality to 99 for hidden clients (restricted in HMIS or the warehouse, or retention-inactive) in the export. It is skipped entirely when either de-identification mode is on, so a faked export of a restricted client still carries their shifted `DOB` (by up to 600 days) and real enrollment history.

The faked-PII gate is view-only. The controller permits `faked_pii` from any user who can reach the form; only the checkbox requires `can_export_anonymous_hmis_data`.

**Important:** Neither option fully de-identifies the data. Hashing only covers a handful of fields, and faked PII does not obscure enrollment patterns, dates, or service history that could re-identify individuals. All exports should be treated as confidential regardless of which de-identification option is used.

## Gotchas

- Every exporter file class includes `ExportConcern` and defines only `adjust_keys`, `export_scope`, and `transforms`. ID assignment, string sanitizing, length limits, and rounding come from `ExportConcern#process`. Don't override `process`.
- Don't format money or integer columns by assigning strings to ActiveRecord attributes in a transform. Assignment re-casts the value. `CsvDestination#write` rounds again on the plain hash for that reason.
- `Client.csv` transform order matters: hash overrides, the client transform, fake data, then restricted-client redaction.
- Resolve the job class through `Filters::HmisExport#schedule_job`, not a hard-coded class name.
- Apply the external data sharing exclusion in `Export::Scopes`, not in an individual file's scope.
- Don't add a third de-identification switch. Extend `GrdaWarehouse::FakeData#fake_patterns` for faked output, or the hash override for hashed output.
- Faked PII covers a fixed list of columns. Dates other than `DOB`, enrollment and service structure, and custom assessment values pass through.
- The export forces ISO date formats process-wide until it finishes, so anything else in the same worker sees them.
- `User.csv` is exported last on purpose: it is built from the user ids referenced by earlier files, and adds an `op-system` row for records with no user.
- XML export is retired; no code path remains.

## Recurring Exports

For automated scheduling and S3 delivery, see [Recurring HMIS Exports](./recurring-hmis-exports.md).

## Related Code

- **Controller**: `app/controllers/warehouse_reports/hmis_exports_controller.rb`
- **Filter Model**: `app/models/filters/hmis_export.rb`
- **Export Model**: `app/models/grda_warehouse/hmis_export.rb`
- **Base Job**: `app/jobs/export_base_job.rb`
- **2026 Driver**:
  - Job: `drivers/hmis_csv_twenty_twenty_six/app/jobs/hmis_csv_twenty_twenty_six/export_job.rb`
  - Exporter: `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/base.rb`
  - Export Concern: `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/export_concern.rb`
- **Export Shared Logic**: `app/models/concerns/export/exporter.rb`

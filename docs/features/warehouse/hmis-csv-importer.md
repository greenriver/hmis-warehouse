# HMIS CSV Importer

This feature imports, normalizes, and validates HMIS CSV data in the HUD standard format into the data warehouse.

## Architecture

The importer operates in two distinct phases: Loading and Importing.

### Upload normalization

Before the Loader runs, the uploaded file is normalized into a plain, unencrypted zip. The rest of the importer reads uploads with rubyzip, which can open neither a `.7z` archive nor an encrypted zip.

- An encrypted zip is decrypted with `ZipCloak`.
- A `.7z` archive is extracted and rebuilt as a zip with the `7z` binary.
- A plain zip is left alone.

### Loader

The Loader (`HmisCsvImporter::Loader`) ingests raw CSV files from a directory. It normalizes file names and headers, detects the HUD CSV version, and loads the raw data into staging tables. It handles:

- Version detection and auto-migration of older formats.
- Normalization of CSV headers (case-insensitive mapping).
- Bulk loading of raw string data via PostgreSQL `COPY`.

### Importer

The Importer (`HmisCsvImporter::Importer::Importer`) processes the staged data into the warehouse. It validates the data, transforms it into typed records, and reconciles it with existing warehouse data.

## Key Concepts

### Staging vs Warehouse

Both live in the same PostgreSQL database but serve different purposes:

- **Staging tables** hold typed, validated rows from a single import run, identified by `importer_log_id`. Each HUD CSV version has its own set of staging models (e.g. `HmisCsvTwentySix::Importer::Client`).
- **Warehouse tables** (e.g. `GrdaWarehouse::Hud::Client`) hold the merged, authoritative state across all data sources and all imports.

Each staging model has a `warehouse_class` pointing to its warehouse counterpart. Both share the same `hud_key` column (e.g. `:PersonalID` for Client, `:EnrollmentID` for Enrollment). The `hud_key` is the HUD-defined record identifier used for matching — it is not the Rails primary key.

### Import Scope

Every import is scoped by three dimensions derived from the CSV files:

- **data_source_id** — the configured `DataSource` the import belongs to.
- **project_ids** — the `ProjectID` values present in `Project.csv`.
- **date_range** — `ExportStartDate..ExportEndDate` from `Export.csv`.

These define which warehouse rows the import is "authoritative" for. The `involved_warehouse_scope` class method on each staging model builds the base warehouse query for this scope. Each model overrides it to join through the appropriate association chain (e.g. Disability joins through Enrollment → Project).

### `pending_date_deleted` — The Central State Machine

The ingestion algorithm uses a "guilty until proven innocent" approach via the `pending_date_deleted` column on warehouse tables. At the start of ingestion, every in-scope warehouse row is flagged as pending deletion. Each subsequent step either **clears** that flag (proving the row should survive) or leaves it set. At the end, anything still flagged is soft-deleted.

### `source_hash` — Change Detection

Each staging row gets a SHA-256 hash of its HUD columns (excluding ExportID) during pre-processing. The warehouse stores this hash too. If the hashes match, the record is unchanged. A NULL warehouse `source_hash` forces re-evaluation.

## Import Lifecycle

```
import!
  ├── pre_process!              # Type conversion, source_hash calculation, row validations
  ├── validate_data_set!        # Cross-record validations (e.g. unique primary keys)
  ├── aggregate!                # Optional: merge split enrollments
  ├── cleanup_data_set!         # Optional: fix known data quality issues
  ├── precalculate_change_counts # Estimate adds/removes for threshold checks
  ├── should_pause? check       # Abort if thresholds exceeded
  ├── ingest!                   # Reconcile staging → warehouse
  └── post_process              # Service history rebuild, duplicate detection, etc.
```

### Ingestion

Ingestion reconciles staged data with the warehouse in four passes:

**Pass 0 — Mark all as pending deletion.** Every in-scope warehouse row gets `pending_date_deleted = today`.

**Pass 1 — Add new records.** Staging rows whose `hud_key` has no warehouse counterpart (within scope) are inserted. Records are upserted to handle cases where the key exists outside the scoped projects/date range.

**Pass 2 — Process existing records.** For rows present in both staging and warehouse, three checks run in sequence:
- **Unchanged**: If `source_hash` matches, clear `pending_date_deleted`. The warehouse row is kept as-is.
- **Incoming older**: If the staging `DateUpdated` is strictly older than the warehouse (day-level comparison), clear `pending_date_deleted`. The warehouse is trusted. Skipped when this is the most recent export for the data source.
- **Apply updates**: Everything still pending at this point has newer or changed data. The warehouse row is overwritten from staging. Side effects: client demographics and enrollment service history are flagged for rebuild.

**Pass 3 — Remove pending deletes.** Anything still carrying `pending_date_deleted` existed in the warehouse within scope but was absent from the import — it's soft-deleted. Clients are a special case: they are never hard-deleted, only flagged for re-evaluation.

**After ingest — Post-ingest hooks.** Staging models may implement `after_ingest!`; the importer calls them for all data sources. Hooks receive `data_source`, and `project_ids` (from `Project.csv`). The FY2026 enrollment importer populates `project_pk` when the data source is an Open Path HMIS installation, setting it on all enrollments in the imported projects regardless of export date range.

### Post-process

After `ingest!` finishes and the import is marked complete (`complete_import`), `import!` and `resume!` call `post_process`. This runs **once per data source** (not per file), **only on successful imports** (not dry runs or paused imports), and handles data-source-level follow-up work such as service history rebuild, duplicate detection, CH enrollment maintenance, and CSV monitors; as well as OP HMIS-specific post-import work, such as queueing `Hmis::MigrateAssessmentsJob`.

## Manual Upload Source Check

Manual uploads (`UploadsController#create`) are checked before any job is queued. Automated S3 imports (`Importing::HudZip::FetchAndImportJob`) never reach the controller and are unaffected.

Two independent checks:

- **Typed data source name.** The user types the data source `short_name`. Compared case-insensitively and stripped, before any file work. A mismatch re-renders the form.
- **`SourceID` in `Export.csv`.** `HmisCsvImporter::UploadValidityCheck` reads only the `Export.csv` entry out of the uploaded zip, without expanding the archive. Entry lookup is case-insensitive and tolerates a nested directory. It runs against the request's own tempfile, before the attachment is stored, so no part of the archive is fetched back from storage during the request.

Four outcomes:

| Source check result | Outcome |
|------------------|---------|
| `SourceID` matches `data_source.source_id` | Enqueued, as before |
| Malformed zip, missing `Export.csv`, unparseable row | No Upload created, form re-rendered |
| File's `SourceID` blank, data source's `source_id` blank, or the two differ | Confirmation screen |
| Unverifiable — the archive could not be read | Confirmation screen |

Manual uploads do not support password-protected archives; only the automated S3 path supplies a password (`HmisImportConfig#zip_file_password`).

The Upload record and its `hmis_zip` attachment are created on the first POST, because an HTTP file input cannot repopulate across a re-render. The confirmation form posts back only the upload id plus the acknowledgment. What the check observed is written to `uploads.export_source_check` on that first POST, so `#confirm` reads a stored server-side row rather than posted values or a second read of the archive. `dry_run` rides along as a hidden field — it is not a column on `uploads`. An upload with `delayed_job_id IS NULL` and no acknowledgment was never enqueued; the uploads index labels it *Not confirmed*. That same condition (`Upload#awaiting_confirmation?`) gates `#confirm`, so a confirmation cannot be re-posted to queue a second import of a file that was already acknowledged or already queued. Abandoning the confirmation screen leaves the record and its attachment in place; re-uploading the same file creates a second record rather than replacing the first.

### Overriding a `SourceID` mismatch

The `uploads.export_source_check` jsonb audit record (expected and observed `SourceID`, `SourceName`, export date range, typed short name, `check_error`) is written when the upload is created; acknowledging the confirmation screen adds the user and timestamp and enqueues with `source_id_override: true`. That kwarg threads down through `Importing::HudZip::HmisAutoMigrateJob` → `Importers::HmisAutoMigrate::UploadedZip` → `Importers::HmisAutoMigrate::Base` → `HmisCsvImporter::Loader::Loader`, where `export_file_valid?` skips its own comparison and logs both values. It defaults to `false` at every level, so automated imports and any in-flight serialized jobs keep the check.

No separate permission gates the override: anyone with `can_upload_hud_zips` can confirm past a mismatch. The file check is therefore advisory and the typed short name is the binding guard. The uploads index shows a *SourceID overridden* badge whose tooltip carries the expected and observed values; the rest of the audit record — typed short name, user, timestamp — is written to the column but not displayed anywhere.

An unverifiable archive does not set `source_id_override`. The check could not open it, but the Loader expands the archive before `export_file_valid?` runs and can read `Export.csv` itself, so its comparison is left in place. The acknowledgment records `check_error` alongside the rest of the audit row, which is how `Upload#source_id_overridden?` tells an unreadable archive from an `Export.csv` whose `SourceID` column is genuinely blank -- the latter does need the override, because the Loader rejects a blank value when the data source has a `source_id` configured.

A blank `SourceID` is a legitimate export, not an error. Per the FY2026 HMIS CSV spec, `SourceID` may be null when `SourceType <> 1`, in which case `SourceName` identifies the responsible organization.

## Validation

Data quality is enforced via `HmisCsvValidation`. Two severity tiers:

- **Error** (`skip_row? = true`): Row excluded from staging. Examples: missing required field, field too long, duplicate primary key.
- **Validation** (`skip_row? = false`): Row imported but issue logged. Examples: missing optional field, value not in expected set.

Cross-record validators (e.g. `UniqueHudKey`) run after pre-processing on the full staged dataset.

## Log Models

Each import run produces a chain of records that connect the UI to internal state:

- `GrdaWarehouse::Upload` — the user-submitted ZIP file. Belongs to a `DataSource`, holds the attached file (`hmis_zip`), and tracks upload progress. Visible in the UI at `/uploads`.
- `GrdaWarehouse::ImportLog` — top-level import record shown in the UI at `/imports/:id`. STI base class. Linked from `Upload` via `import_log`.
- `HmisCsvImporter::ImportLog` — STI subclass that links to the loader and importer logs via `loader_log` and `importer_log` associations.
- `HmisCsvImporter::Loader::LoaderLog` — tracks the loader phase: per-file row counts, timing, errors.
- `HmisCsvImporter::Importer::ImporterLog` — tracks the importer phase: `status` (including `paused` / `resuming`), `summary` (per-file add/remove/unchanged counts), and `phase_metrics` (per-phase timing and query diagnostics).

To trace a specific import from a Rails console: `GrdaWarehouse::ImportLog.find(1234).importer_log`.

## Jobs

Imports run asynchronously on the `long_running` Delayed Job queue.

- `Importing::HudZip::HmisAutoMigrateJob` — entry point for user-uploaded imports. Holds a per-data-source advisory lock and re-queues if the lock is held.
- `Importing::HudZip::FetchAndImportJob` — scheduled entry point that pulls zips from a data source's configured S3 bucket and imports them.
- `Importing::HudZip::ResumeHmisImportJob` — resumes an import that was paused at a threshold check.
- `HmisCsvImporter::Cleanup::Expire*Job` — periodic cleanup of expired staging data.

- `post_process` enqueues additional jobs onto the same `long_running` queue — for example service history rebuilds (`ServiceHistory::RebuildEnrollmentsByBatchJob`) and, for OP HMIS data sources, `Hmis::MigrateAssessmentsJob` (see [Post-process](#post-process)).

The importer does not wrap its run in a surrounding transaction. Import jobs acquire a
per-data-source advisory lock so that only one import runs at a time for a given data source.

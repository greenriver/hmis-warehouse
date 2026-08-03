# HMIS CSV Importer

This feature imports, normalizes, and validates HMIS CSV data in the HUD standard format into the data warehouse.

## Architecture

The importer operates in two distinct phases: Loading and Importing.

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

The importer does not wrap its run in a surrounding transaction. Import jobs acquire a
per-data-source advisory lock so that only one import runs at a time for a given data source.

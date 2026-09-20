---
title: HMIS CSV import pipeline
summary: "Two-phase import: the Loader reads HUD CSV files into per-version staging tables, the Importer reconciles staging into warehouse tables using source_hash change detection and the pending_date_deleted four-pass algorithm. Covers lifecycle hooks, per-data-source cleanups as importer extensions (ADR 0007), aggregators, import logs, auto-migration between CSV versions, and per-file monitoring thresholds."
area: hud-reporting
tags: [hmis-csv, import, HmisCsvImporter, Loader, Importer, staging, source_hash, pending_date_deleted, ImporterExtension, HmisCsvCleanup, PostIngestCleanup, aggregators, ImportLog, LoaderLog, ImporterLog, HmisAutoMigrateJob, FetchAndImportJob, ResumeHmisImportJob, HmisImportConfig, ImportThreshold, ImportCsvMonitor, CsvImportMonitorCollector, disable_nestloop, ADR-0007]
sources:
  - docs/adr/0007-hmis-hud-import-cleanups-via-importer-extensions.md
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/loader/loader.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/loader/loader_log.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/importer/importer.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/importer/importer_log.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/importer/import_concern.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/import_log.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/hmis_csv.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/hmis_csv_cleanup/base.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/hmis_csv_cleanup/fix_blank_household_ids.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/hmis_csv_cleanup/enforce_relationship_to_hoh.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/post_ingest_cleanup/base.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/aggregated/base.rb
  - drivers/hmis_csv_importer/app/models/hmis_csv_importer/aggregated/combine_enrollments.rb
  - app/models/importers/hmis_auto_migrate.rb
  - app/jobs/importing/hud_zip/hmis_auto_migrate_job.rb
  - app/jobs/importing/hud_zip/fetch_and_import_job.rb
  - app/jobs/importing/hud_zip/resume_hmis_import_job.rb
  - app/models/grda_warehouse/hmis_import_config.rb
  - app/models/grda_warehouse/import_threshold.rb
  - app/models/grda_warehouse/data_source.rb
  - app/models/grda_warehouse/import_csv_monitor.rb
  - app/models/grda_warehouse/monitoring/tasks/csv_import_monitor_collector.rb
  - drivers/hmis_csv_twenty_twenty_six/README.md
related:
  - hud-reporting/csv-export.md
  - hud-reporting/service-history.md
  - warehouse/data-sources-and-imports.md
---

## Purpose

HUD HMIS CSV exports from vendor systems land in the warehouse through a two-phase pipeline in
`drivers/hmis_csv_importer`. `HmisCsvImporter::Loader::Loader` copies raw CSV rows into
per-version string-typed data-lake tables. `HmisCsvImporter::Importer::Importer` pre-processes
those rows into typed staging tables, validates them, optionally aggregates and cleans them,
then reconciles them against the `GrdaWarehouse::Hud::*` tables. Every import is authoritative
for one data source, the `ProjectID`s in `Project.csv`, and the `ExportStartDate..ExportEndDate`
range in `Export.csv`; warehouse rows inside that scope that the CSV no longer contains are
soft-deleted.

The per-year column definitions, loader and importer models, and custom-file support live in
version drivers `hmis_csv_twenty_twenty`, `hmis_csv_twenty_twenty_two`,
`hmis_csv_twenty_twenty_four`, and `hmis_csv_twenty_twenty_six`, each registering itself in
`Rails.application.config.hmis_data_lakes[<year>]`. Older exports are transformed forward by
`Importers::HmisAutoMigrate` before loading.

This doc covers the code path only: entry jobs, the Loader, the Importer lifecycle and every
hook in order, change detection and soft deletion, cleanups and aggregators as per-data-source
importer extensions, the log models and pause/resume, and per-file row-count monitors. The HUD
CSV specification itself (file list, columns, allowed values) is out of scope; consult the HMIS
domain knowledge MCP server (`search_docs`) for spec content.

## Entry points

- Upload: `UploadsController#create` saves a `GrdaWarehouse::Upload` (attachment `hmis_zip`)
  and enqueues `Importing::HudZip::HmisAutoMigrateJob` with `upload_id`, `data_source_id`,
  `deidentified`, `allowed_projects`, `stop_version`, and `dry_run`. The job takes a
  per-data-source advisory lock (`GrdaWarehouse::DataSource.import_advisory_lock_name`) and
  re-queues itself 15 minutes out when the lock is held. It runs
  `Importers::HmisAutoMigrate::UploadedZip#import!`.
- Scheduled S3 pull: rake `grda_warehouse:import_data_sources_s3` iterates
  `Importers::HmisAutoMigrate::S3.available_connections` (active
  `GrdaWarehouse::HmisImportConfig` rows whose data source is not `import_paused`) and enqueues
  `Importing::HudZip::FetchAndImportJob` once per file from `HmisImportConfig#possible_files`.
  The job only accepts `Importers::HmisAutoMigrate::S3` as `klass` and uses the same advisory
  lock. The S3 importer creates an `Upload` and delegates to `UploadedZip`.
- Resume: `HmisCsvImporter::ImporterRestartsController#update` sets the importer log to
  `resuming` and enqueues `Importing::HudZip::ResumeHmisImportJob`, which rebuilds an
  `Importer` from `import.loader_log.id`, assigns the existing `importer_log`, and calls
  `resume!`. `max_attempts` is 1.
- `Importers::HmisAutoMigrate::Base#import!` creates `HmisCsvImporter::ImportLog`, builds
  `HmisCsvImporter::Loader::Loader` with the extracted directory, and calls `Loader#import!`,
  which loads then constructs and runs `HmisCsvImporter::Importer::Importer#import!`.
- Manual: `HmisCsvImporter::Loader::Loader.new(data_source_id:, file_path:).import!` from a
  console, or `Importer.new(loader_id:, data_source_id:).import!` against an existing
  `LoaderLog`.
- Configuration lives on `GrdaWarehouse::DataSource`: jsonb `import_cleanups` and
  `import_aggregators`, `has_one :import_threshold` (`GrdaWarehouse::ImportThreshold`),
  `has_one :hmis_import_config`, `has_many :import_csv_monitors`.

## How it works

### Loader

`HmisCsvImporter::Loader::Loader#initialize` requires an existing directory, creates a
`HmisCsvImporter::Loader::LoaderLog` (`status: :started`), and records the CSV version from
`Export.csv` via `Importers::HmisAutoMigrate.calculate_current_version` (missing `CSVVersion`
means `2020`). `load!` runs `ensure_file_naming` (case-normalizes file names), reads
`Export.csv`, and fails the log unless `Export.csv` is valid and its `SourceID` matches
`data_source.source_id` when one is set.

`load_source_files!` then calls `Importers::HmisAutoMigrate.apply_migrations`, which chains the
`CsvTransformer` classes registered through `add_migration` (one per `hud_twenty_twenty*_to_*`
driver) until the files reach the newest version or `stop_version`. Migration to 2024/2026 is
refused on production and staging before `HudHelper.production_cutoff` /
`HudHelper.staging_cutoff`. `Importers::HmisAutoMigrate.current_stop_version` supplies the
default `stop_version` for uploads and honors `HMIS_AUTOMIGRATE_STOP_VERSION` before the cutoff.

Three optional pre-load filters run on the files in a fixed order: `UnlinkedRecordFilter`
(drops rows that reference no client or project, logging discards, so it must see original
ids), `HudKeyRemapper` (hashes `PersonalID`/`ProjectID` with `Export.SourceID` when enabled on
the data source), then `ProjectFilter` when `limit_projects` is set. Each file is then encoding-
detected, line-ending-fixed, and streamed into the version's loader table with PostgreSQL
`COPY ... FROM STDIN`. `clean_header_row` accepts headers case-insensitively and in any order,
ignores extra columns, and fails the file when expected columns are missing. Rows with too many
or too few columns or a blank first column go to `load_errors` and are skipped. Per-file counts
(`total_lines`, `lines_loaded`, `total_errors`) are written to `loader_log.summary`.

`complete_load` sets `status` to `loaded` or `failed` and links the `LoaderLog` and the file
list onto the `ImportLog`. `Loader#import!` only continues to the Importer when
`loader_log.successfully_loaded?`. `remove_files` (default true) deletes the directory in an
`ensure`.

Which files a version handles comes from `HmisCsvImporter::HmisCsv`: `loadable_files` and
`importable_files` resolve through `Rails.application.config.hmis_data_lakes[version]`, and
for an HMIS data source (`data_source.hmis?`) `filter_hmis_owned` drops files the version
module lists in `hmis_owned_filenames`.

### Importer lifecycle

`HmisCsvImporter::Importer::Importer#initialize` loads the `LoaderLog`, creates an
`HmisCsvImporter::Importer::ImporterLog` with the same version, and seeds a per-file `summary`.
Every phase runs through `log_timing`, which records `started_at`, `duration`,
`cpu_percentage`, and `memory_delta` into `importer_log.phase_metrics`.

`import!` runs, in this order:

1. `start_import`: status `started`, links `loader_log.importer_log_id`.
2. `analyze_tables`: `ANALYZE` on each staging table.
3. `pre_process!`: status `pre_processing`; per file, `attrs_from` type-casts and optionally
   de-identifies each loaded row, computes `source_hash`, runs `hmis_validations` row checks,
   and bulk-inserts rows that have no error-severity failure.
4. `validate_data_set!`: `run_complex_validations!` per model (cross-row checks such as
   `UniqueHudKey`, `OneHeadOfHousehold`, `EntryAfterExit`).
5. `aggregate!`: status `aggregating`; runs configured aggregators.
6. `cleanup_data_set!`: status `cleaning`; runs configured pre-ingest cleanups.
7. `analyze_tables` again.
8. `precalculate_change_counts`, only when the data source has pause or notify thresholds:
   writes `added`, `removed`, `total_count` per file using `NOT EXISTS` anti-joins.
9. `notify_of_import_status` (no-op without an `ImportLog`).
10. `pause_import` and return when `should_pause?` or `dry_run`. `should_pause?` is true when
    the loader did not reach `loaded`, or an error threshold is met and
    `ever_pause_imports_with_errors?`, or a record-count threshold is met and
    `ever_pause_imports_with_record_changes?`.
11. `ingest!`: `reset_import_counts`, status `importing`, then `mark_tree_as_dead`,
    `analyze_warehouse_tables`, `add_export_row`, `add_new_data`, `process_existing`
    (`mark_unchanged`, `mark_incoming_older`, `apply_updates` per file), `update_export_ids`,
    `remove_pending_deletes`, `set_effective_export_end_date`, `after_ingest`.
12. `post_ingest_cleanup!`: configured post-ingest cleanups against warehouse data.
13. `invalidate_aggregated_enrollments!`: `rebuild_warehouse_data` on each aggregator.
14. `complete_import`: status `complete`, `data_source.last_imported_at`, links
    `import_log.importer_log`.
15. `post_process`: `project_cleanup`, `cleanup_dangling_enrollments`, `identify_duplicates`,
    `queue_enrollment_processing`, `maintain_ch_enrollments`, `check_csv_monitors`, then
    `hmis_post_process` (enqueues `Hmis::MigrateAssessmentsJob` for the involved enrollments
    when the data source is an HMIS and `HmisEnforcement.hmis_enabled?`).

`resume!` requires `importer_log.resuming?` and runs steps 11 through 15. There is no
surrounding transaction; `start_import` and `complete_import` each use a short one.

### Change detection and soft deletes

Each staging model includes `HmisCsvImporter::Importer::ImportConcern` and defines
`involved_warehouse_scope(data_source_id:, project_ids:, date_range:)`, the set of warehouse
rows this import owns, and `warehouse_class`. `hud_key` (`PersonalID`, `EnrollmentID`, ...)
is the match key; the Rails `id` is never compared across staging and warehouse. Staging
`default_scope` includes soft-deleted rows.

`calculate_source_hash` is SHA-256 of the row's HUD columns minus `ExportID`, stored on both
staging and warehouse rows. Cleanups that rewrite a staging row call `set_source_hash` again.
A `NULL` warehouse `source_hash` never matches, which forces re-evaluation on the next import.

`ingest!` passes, per file:

- `mark_tree_as_dead`: `UPDATE ... SET pending_date_deleted = today` over
  `involved_warehouse_scope.with_deleted`.
- `add_export_row`: upserts the warehouse `Export` by `ExportID`.
- `add_new_data`: snapshots existing hud keys into an indexed temp table
  (`with_new_records_scope`), streams staging rows whose key is absent, and inserts them in
  5,000-row batches. Upsert (`ON CONFLICT`) is used except for `Export` and `Client`, which have
  no usable uniqueness constraint. Augmentation custom files are skipped.
- `mark_unchanged`: clears `pending_date_deleted` where a staging row with the same key and
  equal `source_hash` exists; rows are materialized into a temp id table and updated in
  batches (`batch_clear_pending_deletion`).
- `mark_incoming_older`: clears `pending_date_deleted` where the staging `DateUpdated` (local
  date) is strictly earlier than the warehouse value. Skipped entirely when
  `most_recent_export_for_ds?`, because the newest export is trusted regardless of `DateUpdated`.
- `apply_updates`: everything still pending with a staging counterpart is overwritten from
  staging via `prepare_destination_for_update`: `pending_date_deleted` cleared, `Client` gets
  `demographic_dirty`, `Enrollment` gets `processed_as = nil`, `Exit` marks its enrollment
  dirty through `flush_dirty_enrollments_for_exit`. `Client` rows are updated one at a time.
- `update_export_ids`: sets `ExportID` on every in-scope warehouse row.
- `remove_pending_deletes`: `Export` is never deleted; `prevent_import_deletions?` models just
  clear the flag and null `source_hash`; `Client` clears the flag and nulls `source_hash` for
  clients with in-scope enrollments; everything else is batch soft-deleted (`DateDeleted` set,
  `source_hash` nulled).
- `set_effective_export_end_date`: latest `DateUpdated` across imported files.
- `after_ingest`: calls `after_ingest!(data_source:, project_ids:)` on any staging model that
  defines it (the 2026 `Enrollment` populates `project_pk` for HMIS data sources).

Batch failures in `process_batch!` fall back to row-by-row writes and record per-row failures
in `import_errors`.

### Cleanups as extensions

A cleanup is a subclass of `HmisCsvImporter::HmisCsvCleanup::Base` with `cleanup!`,
`self.enable` (a hash `{ import_cleanups: { '<StagingBasename>': ['<ClassName>'] } }`), and
`self.description`. It is enabled per data source by storing the class name in the
`import_cleanups` jsonb column under the staging model's basename; `Importer#cleanups_from_class`
constantizes those names and sorts by `self.run_order` (lower first, stored order on ties).
`Base.checked?(data_source)` backs the Importer Extensions UI. Instances receive
`importer_log`, `date_range`, and `version`, and address the version's staging table through
`importable_file_class('Enrollment')`, writing back with `activerecord-import` on
`conflict_target` (which includes `importer_log_id` when the table is partitioned).

Two pre-ingest examples: `FixBlankHouseholdIds` assigns an MD5 of
`EnrollmentID__PersonalID__ProjectID` to blank `HouseholdID`s. `EnforceRelationshipToHoh`
rewrites household ids reused across projects or within a project by one person, sets sole
members and blank-household rows to head of household, and applies an age-based decision tree
to multi-person households, demoting extra heads to `99`.

Post-ingest cleanups subclass `HmisCsvImporter::PostIngestCleanup::Base`, which inherits the
same configuration and UI class methods but returns `post_ingest?` true. `cleanup_data_set!`
skips them; `post_ingest_cleanup!` runs them after `ingest!` with `data_source`,
`project_ids` (the HUD `ProjectID`s from `Project.csv`), and `version`, so they operate on
warehouse rows. `FixIncorrectPersonalIdReferences` delegates to an `Hmis::Hud::DataIntegrity`
service.

ADR 0007 records why: HMIS-backed data sources need these fixes re-applied on every CSV drop,
and console runs of `HmisDataCleanup::Util` (`drivers/hmis/lib/hmis_data_cleanup/util.rb`)
are easy to skip and not project-scoped. Extensions default off, are configured on the data
source, and appear in the import log.

### Aggregators

Aggregators subclass `HmisCsvImporter::Aggregated::Base` and are enabled the same way as
cleanups but through the `import_aggregators` jsonb column. The one implementation,
`HmisCsvImporter::Aggregated::CombineEnrollments`, targets night-by-night emergency shelter
vendors that emit one entry/exit enrollment per stay. It only acts on projects flagged with
`enrollments_combined` (`GrdaWarehouse::Hud::Project#convert_to_aggregated!`); enabling it on
the data source alone does nothing.

During `aggregate!` the Importer calls three methods in order. `remove_deleted_overlapping_data!`
deletes rows from the persistent side tables `HmisCsvImporter::Aggregated::Enrollment` and
`Aggregated::Exit` that overlap the export range but are absent from the incoming file.
`copy_incoming_data!` copies the incoming staging enrollments and exits into those side tables,
so they accumulate across imports. `aggregate!` marks the incoming staging rows
`should_import: false`, then walks each client's enrollments in the project ordered by
`EntryDate`, merging runs where the next `EntryDate` equals the previous `ExitDate`, and writes
one enrollment (and one exit, from the last stay) per run back into staging with a fresh
`source_hash`. Open enrollments pass through. Only runs overlapping the export range are
emitted, which can make the `added` count exceed the file's row count.

After ingest, `invalidate_aggregated_enrollments!` calls `rebuild_warehouse_data`, which
invalidates service history for every destination client in the combined projects and runs
`GrdaWarehouse::Tasks::ServiceHistory::Add`. Assessment records tied to the merged-away
enrollments are still imported but are not reachable from the surviving enrollment in the UI.

### Logs and resume

One import produces a chain: `GrdaWarehouse::Upload` (the zip, `has_one :import_log`) ->
`GrdaWarehouse::ImportLog` (STI base, the row shown at `/imports/:id`; the driver's
`ImportLogExtension` is included into it) -> `HmisCsvImporter::ImportLog` (STI subclass with
`belongs_to :loader_log` and `belongs_to :importer_log`) -> `HmisCsvImporter::Loader::LoaderLog`
(`hmis_csv_loader_logs`; `status`, `version`, per-file `summary`, `load_errors`,
`row_processing_notes`) and `HmisCsvImporter::Importer::ImporterLog` (`hmis_csv_importer_logs`;
`status`, `version`, `summary`, `phase_metrics`, `import_errors`, `import_validations`).

`ImporterLog#summary` is keyed by file name with `pre_processed`, `added`, `updated`,
`unchanged`, `removed`, `total_errors`, plus `total_flags`, timing, and rate keys. `added` and
`removed` are first estimated by `precalculate_change_counts`, zeroed by `reset_import_counts`
at the start of `ingest!`, and re-accumulated as batches are written. `phase_metrics` holds
per-phase timing and, through `with_sql_log`, compressed slow queries whose capture threshold is
`HMIS_IMPORTER_SQL_LOG_MIN_DURATION_MS` (default 60,000 ms, floor 1, cap 500 queries). Use
`ImporterLog.without_phase_metrics` for listings and `#debug_phases` to read them.

Statuses on `ImporterLog`: `started`, `pre_processing`, `aggregating`, `cleaning`, `importing`,
`paused`, `resuming`, `complete`. `pause_import` sets `paused` and links the `ImportLog`;
nothing has touched warehouse tables at that point. Every dry run pauses. A user with
`can_view_imports` resumes from the uploads page: `ImporterRestartsController#update` sets
`resuming` and enqueues `ResumeHmisImportJob`; `Importer#resume!` returns immediately unless the
status is `resuming`. Staging rows from paused imports stay in place until the
`HmisCsvImporter::Cleanup::Expire*Job` jobs remove expired loader and importer data
(`Export` and `Project` rows are exempt via `expiring_models`).

Pause thresholds come from `GrdaWarehouse::ImportThreshold`: `error_count_threshold_reached?`
and `record_count_threshold_reached?` both require a minimum count and a minimum percent, and
`pause_on_error_threshold` / `pause_on_record_count_threshold` decide whether a met threshold
pauses or only notifies.

### Monitoring thresholds

`GrdaWarehouse::ImportCsvMonitor` (`acts_as_paranoid`, `belongs_to :data_source`) stores one
row per data source and CSV file name, with at least one of `count_increase_threshold`,
`count_decrease_threshold`, `min_additions_threshold`, `max_removals_threshold`. Allowed file
names come from the current version's `importable_files_map`.
`threshold_exceeded?(current:, previous:)` tries the delta calculator
(`ImportFileDeltaCalculator`, needs a previous value) then the addition/removal calculator
(`ImportFileAdditionRemovalDetectionCalculator`, does not).

`GrdaWarehouse::Monitoring::Tasks::CsvImportMonitorCollector.run!` is called from
`Importer#post_process` (`check_csv_monitors`), so it runs only after a completed, non-paused
import. It calls `MetricDefinition.maintain_csv_metrics!`, then for each active monitor whose
file appears in `importer_log.summary`: reads `current` (`pre_processed`, `added`, `removed`)
via `CsvRowCountCalculator.current_value`, takes `previous` from the latest `MetricSnapshot`
or from the prior `ImporterLog`, and evaluates the monitor. On a crossing it creates a new
`MetricSnapshot` unless one was already opened today; otherwise it updates today's snapshot or
creates the first one. Snapshots are entity `GrdaWarehouse::DataSource`, one metric definition
per file name (`subtype`).

The collector does not send mail. Recipients are `GrdaWarehouse::NotificationConfiguration`
rows with `notification_slug` `csv_import_threshold_exceeded` and `source` the monitor
(`ImportCsvMonitor#csv_import_notification_user_ids`); delivery belongs to the metric-tracking
framework's daily `MetricSnapshotCollector`, which enqueues `NotifyMetricThresholdCrossingsJob`.

## Key files

- `drivers/hmis_csv_importer/app/models/hmis_csv_importer/loader/loader.rb`: `load!`,
  `import!`, `load_source_files!` (filter order, `COPY`), `clean_header_row`,
  `export_file_valid?`.
- `drivers/hmis_csv_importer/app/models/hmis_csv_importer/importer/importer.rb`: `import!`,
  `resume!`, `should_pause?`, `ingest!` and its passes, `cleanup_data_set!`,
  `post_ingest_cleanup!`, `aggregate!`, `post_process`, `with_sql_log`, `process_batch!`.
- `drivers/hmis_csv_importer/app/models/hmis_csv_importer/importer/import_concern.rb`:
  `involved_warehouse_scope` contract, `existing_data`, `incoming_data`,
  `existing_destination_data`, `pending_deletions`, `calculate_source_hash`,
  `as_destination_record`.
- `drivers/hmis_csv_importer/app/models/hmis_csv_importer/hmis_csv.rb`: version resolution
  through `hmis_data_lakes`, `importable_file_class`, `filter_hmis_owned`, `log_timing`.
- `drivers/hmis_csv_importer/app/models/hmis_csv_importer/hmis_csv_cleanup/base.rb`,
  `post_ingest_cleanup/base.rb`: extension contract (`enable`, `checked?`, `run_order`,
  `post_ingest?`).
- `drivers/hmis_csv_importer/app/models/hmis_csv_importer/hmis_csv_cleanup/fix_blank_household_ids.rb`,
  `enforce_relationship_to_hoh.rb`: pre-ingest examples.
- `drivers/hmis_csv_importer/app/models/hmis_csv_importer/aggregated/base.rb`,
  `combine_enrollments.rb`: aggregator contract and the one implementation.
- `drivers/hmis_csv_importer/app/models/hmis_csv_importer/import_log.rb`,
  `loader/loader_log.rb`, `importer/importer_log.rb`: log chain, `paused?`, `resuming?`,
  `log_phase`, `debug_phases`.
- `app/models/importers/hmis_auto_migrate.rb`: `apply_migrations`,
  `calculate_current_version`, `current_stop_version`, cutover guards.
- `app/jobs/importing/hud_zip/hmis_auto_migrate_job.rb`, `fetch_and_import_job.rb`,
  `resume_hmis_import_job.rb`: queue entry points and advisory locking.
- `app/models/grda_warehouse/hmis_import_config.rb`: S3 credentials and `possible_files`.
- `app/models/grda_warehouse/import_threshold.rb`: `error_count_threshold_reached?`,
  `record_count_threshold_reached?`.
- `app/models/grda_warehouse/data_source.rb`: `import_cleanups`, `import_aggregators`,
  `import_threshold`, `import_csv_monitors`, `import_advisory_lock_name`,
  `ever_pause_imports_with_*`, `importable?`.
- `app/models/grda_warehouse/import_csv_monitor.rb`,
  `app/models/grda_warehouse/monitoring/tasks/csv_import_monitor_collector.rb`: per-file
  monitors and the post-import collector.
- `drivers/hmis_csv_twenty_twenty_six/README.md`: 2026 driver layout and the YAML-driven
  custom-file system.
- `docs/adr/0007-hmis-hud-import-cleanups-via-importer-extensions.md`: rationale for
  cleanups as extensions.

## Gotchas

- `HmisCsvImporter::Utility.clear!` truncates every loader, importer, aggregated, and log
  table and only refuses when `Rails.env.production?`. Never run it against a development
  database; only run it in the test environment.
- The set-based statements over `involved_warehouse_scope` (`mark_tree_as_dead`, the temp-table
  materializations in `with_new_records_scope` and `with_temp_id_table`, the `in_batches`
  pagination in `apply_updates`, the client updates in `remove_pending_deletes`) are wrapped in
  `GrdaWarehouseBase.disable_nestloop` because the planner otherwise picks a nested-loop join
  on the multi-table scope. `analyze_tables` and `analyze_warehouse_tables` exist for the same
  reason. Removing either changes run time by orders of magnitude on large sources.
- The four version drivers are near-copies (24 to 33 importer models each). A fix to a staging
  model's `involved_warehouse_scope`, validations, or `after_ingest!` usually needs the same
  edit in each driver that supports that file.
- `ever_pause_imports_with_record_changes?` on `GrdaWarehouse::DataSource` checks
  `pause_on_error_threshold`, not `pause_on_record_count_threshold`; a record-count pause needs
  the error pause flag set too.
- `precalculate_change_counts` runs only when thresholds are configured, so `added` and
  `removed` in a paused import's summary may be absent for other sources; after `ingest!`
  they are recomputed from actual batches.
- `mark_incoming_older` is skipped whenever the incoming `ExportDate` is the newest for the
  data source, so re-importing an old export can overwrite newer warehouse rows only when an
  even newer export has already been imported.
- `Client` rows are never deleted by an import and are updated one row at a time in
  `apply_updates`; large client changes are the slow path.
- `post_ingest_cleanup!` rescues `StandardError`, reports to Sentry, and lets the import
  complete; a failing post-ingest cleanup does not fail the import.
- `CombineEnrollments` needs `Project#enrollments_combined` on each project; the data-source
  toggle alone is a no-op. Its side tables persist across imports.
- `Loader#initialize` defaults `remove_files` to true and deletes the source directory in
  `ensure`, including on failure.
- `after_ingest!` hooks receive the HUD `ProjectID`s from `Project.csv`, not warehouse
  `Project.id`s, and run for every data source; each hook decides whether to act.
- `filter_hmis_owned` drops HMIS-owned files for `data_source.hmis?` sources, so a file listed
  in the zip may be silently ignored for an HMIS data source.
- `CsvImportMonitorCollector` opens at most one crossing snapshot per day per monitor; a
  second import the same day that also crosses is not recorded.

## Do not repeat

- Console cleanups through `HmisDataCleanup::Util`
  (`drivers/hmis/lib/hmis_data_cleanup/util.rb`) for data sources that receive HUD CSV imports.
  Write an `HmisCsvImporter::HmisCsvCleanup::Base` or `PostIngestCleanup::Base` subclass and
  enable it in `import_cleanups`; `FixBlankHouseholdIds` and `FixIncorrectPersonalIdReferences`
  are the templates.
- A cleanup or aggregator that works directly on `GrdaWarehouse::Hud::*` tables before
  `ingest!`. Pre-ingest extensions receive `importer_log` and must scope to
  `importable_file_class(...).where(importer_log_id:)`; warehouse-side work belongs in a
  `PostIngestCleanup` scoped to `data_source` and `project_ids`.
- Hard-coding a version module (`HmisCsvTwentyTwentySix::Importer::Enrollment`) inside
  `hmis_csv_importer`. Resolve through `importable_file_class` / `hmis_data_lakes` so the code
  works for every registered version.
- Comparing staging and warehouse rows by Rails `id`. Match on `hud_key` plus
  `data_source_id` within `involved_warehouse_scope`.
- `update_all` with a SQL string or interpolated dates in importer code. Repo-wide entries
  in `conventions/do-not-repeat.md`, enforced by `Queries/UnsafeBulkUpdateSql` and
  `Queries/DateInterpolationInSql`.
- Rewriting a staging row without calling `set_source_hash`; the warehouse row would then be
  treated as unchanged on the next import.

## Related

- `hud-reporting/csv-export.md`: the version-specific exporters that produce the files this
  pipeline consumes.
- `hud-reporting/service-history.md`: what `processed_as = nil` and `demographic_dirty`
  trigger after `post_process`.
- `warehouse/data-sources-and-imports.md`: `GrdaWarehouse::DataSource` configuration, uploads
  UI, and import thresholds from the operator side.
- `conventions/do-not-repeat.md`: repo-wide `update_all` and date-interpolation rules.
- Human-facing sources: `docs/features/warehouse/hmis-csv-importer.md`,
  `docs/features/warehouse/import-csv-monitoring.md`,
  `docs/adr/0007-hmis-hud-import-cleanups-via-importer-extensions.md`,
  `drivers/hmis_csv_twenty_twenty_six/README.md`.

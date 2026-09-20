---
title: HMIS CSV export
summary: "Version-specific Kiba exporters produce HUD CSV zips from warehouse data. Covers Filters::HmisExport routing to the right version driver, ExportConcern rules (ExportID, field lengths, rounding), the two de-identification modes (SHA-256 hashing versus faked PII) and when each is allowed, and recurring exports delivered to S3."
area: hud-reporting
tags: [hmis-csv, export, HmisExport, Filters::HmisExport, Exporter::Base, ExportConcern, Kiba, ExportID, de-identification, SHA-256, faked-pii, RecurringHmisExport, process_recurring_hmis_exports, S3, 7z]
sources:
  - app/controllers/warehouse_reports/hmis_exports_controller.rb
  - app/controllers/warehouse_reports/hashed_only_hmis_exports_controller.rb
  - app/models/filters/hmis_export.rb
  - app/models/grda_warehouse/hmis_export.rb
  - app/models/grda_warehouse/fake_data.rb
  - app/models/export/restricted_client_pii_transform.rb
  - app/jobs/export_base_job.rb
  - app/models/concerns/export/exporter.rb
  - app/models/concerns/export/scopes.rb
  - app/services/client_external_data_sharing.rb
  - drivers/hmis_csv_twenty_twenty_six/config/initializers/hmis_csv_twenty_twenty_six_feature.rb
  - drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/base.rb
  - drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/export_concern.rb
  - drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/export.rb
  - drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/client.rb
  - drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/client/overrides.rb
  - drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/fake_data.rb
  - drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/csv_destination.rb
  - drivers/hmis_csv_twenty_twenty_six/app/jobs/hmis_csv_twenty_twenty_six/export_job.rb
  - app/models/grda_warehouse/recurring_hmis_export.rb
  - app/models/grda_warehouse/tasks/process_recurring_hmis_exports.rb
  - lib/tasks/grda_warehouse.rake
  - config/schedule.rb
related:
  - hud-reporting/csv-import.md
  - warehouse/pii-and-restricted-clients.md
---

## Purpose

The HMIS CSV export turns warehouse data into a HUD CSV zip: one CSV per HUD file plus
`Export.csv`, optionally with custom files. The HUD CSV specification (file list, column
definitions, `HashStatus`, `ExportPeriodType`, `ExportDirective`) is out of scope here; use the
HMIS domain knowledge MCP server (`search_docs`) for spec content. This doc covers the
implementation only.

Each HUD CSV version is a driver: `drivers/hmis_csv_twenty_twenty_two`,
`drivers/hmis_csv_twenty_twenty_four`, `drivers/hmis_csv_twenty_twenty_six`.
`drivers/hmis_csv_twenty_twenty` has an importer but no exporter. Each driver registers a
version label and an `ExportJob` with `Filters::HmisExport` (`app/models/filters/hmis_export.rb`),
which is the routing table. The 2026 driver is the template; the 2022 and 2024 exporters are
near-copies with older column sets.

Three concerns are shared across versions and live outside the drivers:
`Export::Exporter` (`app/models/concerns/export/exporter.rb`) creates the
`GrdaWarehouse::HmisExport` record, zips, and uploads; `Export::Scopes`
(`app/models/concerns/export/scopes.rb`) builds the project, enrollment, and client scopes;
`Export::RestrictedClientPiiTransform` (`app/models/export/restricted_client_pii_transform.rb`)
redacts HMIS-restricted clients in `Client.csv`.

Two de-identification modes exist: `hash_status == 4` (SHA-256 of Soundex for names, SHA-256 of
SSN) and `faked_pii` (Faker-generated replacements persisted in `GrdaWarehouse::FakeData`).
They serve different purposes; the de-identification table in this doc lists what each
changes.

Recurring exports (`GrdaWarehouse::RecurringHmisExport`) rebuild the filter on a cadence,
re-run the same job, and optionally push a password-protected archive to S3.

## Entry points

- `WarehouseReports::HmisExportsController` (`app/controllers/warehouse_reports/hmis_exports_controller.rb`).
  `index` renders the filter form; `create` builds `Filters::HmisExport` from `report_params`,
  creates a `GrdaWarehouse::RecurringHmisExport` when `every_n_days` is positive, calls
  `adjust_reporting_period`, then `schedule_job`. `show` streams `hmis_zip` (ActiveStorage) or
  falls back to the legacy `content` column. `edit`, `update`, and `cancel` act on the
  recurring definition linked to an export. Access: `require_can_export_hmis_data!` plus
  report assignment through `WarehouseReportAuthorization`; users without
  `can_view_all_reports?` see only their own exports.
- `WarehouseReports::HashedOnlyHmisExportsController`
  (`app/controllers/warehouse_reports/hashed_only_hmis_exports_controller.rb`) subclasses
  `WarehouseReports::HmisExportsController`, forces `hash_status: '4'`, permits a reduced parameter set (no `hash_status`,
  `faked_pii`, `confidential`, `custom_file_types`, or recurrence keys), and lists only
  `hash_status == 4` exports. Same permission; a separate report definition so it can be
  assigned independently.
- `Filters::HmisExport#schedule_job(report_url:)` / `#execute_job` resolve the job class for
  `version` from `Rails.application.config.hmis_exporters` and call `perform_later` or
  `perform_now` with `options_for_job`.
- `HmisCsvTwentyTwentySix::ExportJob` (`drivers/hmis_csv_twenty_twenty_six/app/jobs/hmis_csv_twenty_twenty_six/export_job.rb`)
  is a two-line subclass of `ExportBaseJob` (`app/jobs/export_base_job.rb`) naming
  `HmisCsvTwentyTwentySix::Exporter::Base`. `ExportBaseJob#perform` instantiates the exporter,
  calls `export!`, links and stores a recurring result, and mails `NotifyUser.hmis_export_finished`
  when `report_url` is present. Queue: `DJ_LONG_QUEUE_NAME`, default `long_running`.
- `HmisCsvTwentyTwentySix::Exporter::Base#export!(cleanup:, zip:, upload:)` is the programmatic
  entry for specs and console use.
- `GrdaWarehouse::Tasks::ProcessRecurringHmisExports#run!`, wired to rake
  `grda_warehouse:process_recurring_hmis_exports` (`lib/tasks/grda_warehouse.rake`) and scheduled
  daily in `config/schedule.rb`.
- `GrdaWarehouse::HmisExport#unzip_to(path)` re-extracts a stored zip for downstream tools such
  as the LSA source-data download.

## How it works

### Routing by version

`Filters::HmisExport` (`app/models/filters/hmis_export.rb`) is a `FilterBase` subclass with
`attribute` declarations for every export option: dates, `version` (default
`HudHelper.current_version`), `source_type` (3, data warehouse), `hash_status` (1),
`period_type` (3), `directive` (2), `include_deleted`, `faked_pii`, `confidential`,
`enforce_project_date_scope`, `custom_file_types`, and the recurrence and S3 keys.

Version registry: each driver's feature initializer calls
`Filters::HmisExport.register_version(label, version_str, job_class_name)` inside
`Rails.application.reloader.to_prepare` (see
`drivers/hmis_csv_twenty_twenty_six/config/initializers/hmis_csv_twenty_twenty_six_feature.rb`).
Entries are `ExporterVersion` structs stored on `Rails.application.config.hmis_exporters`,
which survives code reloads. The 2020 and 2022 initializers have their `register_version` lines
commented out, so only 2024 and 2026 are selectable. `update` ignores a `version` that is not
registered.

`schedule_or_execute_job` indexes the registry by `version_str`, falls back to the first entry
when `version` is blank, and raises if nothing matches. `options_for_job` serializes dates as
ISO 8601, resolves `projects` through `effective_project_ids`, and passes the whole filter as
`options: to_h` so the exporter can persist it on the `GrdaWarehouse::HmisExport` row.

`effective_project_ids` unions ids from `project_ids`, `project_group_ids`,
`organization_ids`, and `data_source_ids`, each merged with `viewable_project_scope`
(`viewable_by(user, permission: :can_view_projects)`, excluding confidential projects unless
the user `can_view_confidential_project_names?`). An empty selection means every viewable
project. `enforce_project_date_scope` then keeps only projects `active_during` the range, and
`coc_codes` keeps only projects with a matching `ProjectCoc`.

`GrdaWarehouse::HmisExport.clean_params` forces `include_deleted = true` when
`period_type == 1` (updated-period exports need deleted rows). `Filters::HmisExport.job_classes`
returns registered job class names plus the string `'HmisTwentyTwentyExportJob'`, a class that
no longer exists, so the controller's `set_jobs` can still read old queued jobs.

### Exporter pipeline

`HmisCsvTwentyTwentySix::Exporter::Base#export!`
(`drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/base.rb`)
runs in order: `create_export_directory` (a fresh `var/hmis_export/<timestamp>` tree),
`set_time_format` (forces `%Y-%m-%d` and `%Y-%m-%d %H:%M:%S` as default formats for the
process), `setup_export` (creates the `GrdaWarehouse::HmisExport` row with `started_at` and an
`export_id` that is the first 32 hex chars of an MD5 of the options hash), `Export.csv`, then
every entry in `exportable_files`, then `zip_archive`, `upload_zip`, `save_fake_data`, and
`completed_at`. `ensure` removes the working directory and restores date formats.

Each file is a Kiba job assembled by `KibaExport.export!`: source `RailsSource` (wraps
`find_each`, batch 10,000, 1,000 in development), the file class's `transforms` list, and
`CsvDestination`. Data files run inside one `repeatable_read` transaction unless a transaction
is already open (transactional specs). For each file a throwaway `TempExport` table named
`te_<table>_<export.id>s` is created and passed as `opts[:temp_class]`, then dropped.

`class_mappings` is the ordered file list: exporter class to `hmis_class` and to one of
`project_scope`, `enrollment_scope`, `client_scope` from `Export::Scopes`. `User` is last on
purpose: `note_involved_user_ids` collects `user_ids` from earlier files, and
`Exporter::User#close` appends an `op-system` row for records with no user. With
`include_deleted`, `hmis_class` swaps each model for its `GrdaWarehouse::Hud::WithDeleted::*`
twin. Custom files are added from `custom_file_mappings` when `custom_file_types` names a
definition in `HmisCsvTwentyTwentySix.custom_files_config`; they receive all three scopes.

`ExportConcern#process` (`export_concern.rb`) is the per-row pipeline every file class shares:
`assign_export_id`, the class's `adjust_keys` (rewrites HUD IDs to warehouse `id`s, e.g.
`PersonalID = row.id`, `UserID = row.user&.id || 'op-system'`), `sanitize_string_fields`
(strips `< > [ ] { }`, collapses whitespace), `enforce_lengths` from `hmis_configuration`
limits (skipped for hashed name/SSN columns when `hash_status == 4`), `enforce_rounding`.
`CsvDestination#write` rounds money/integer columns again because assigning a formatted string
back onto an ActiveRecord attribute re-casts it; it writes with `force_quotes` and escapes
newlines as `\n`.

`Export.csv` is built by `Exporter::Export.export_scope` from the export row: `CSVVersion`
`'2026 v1.3'`, `SourceID` from `coc_codes` joined by `;` or a translated default, contact fields
from the requesting user, `HashStatus`, `ExportPeriodType`, `ExportDirective`.

Scopes (`Export::Scopes`): `project_scope` is `@projects` narrowed by `ProjectCoc` when
`coc_codes` are set; `enrollment_scope` requires a matching project, applies
`open_during_range` for `period_type == 3`, filters CoC through the head of household's
`EnrollmentCoC` with a `COALESCE` fallback, and raises `NotImplementedError` for
`period_type == 2`; `client_scope` is destination clients with a qualifying source enrollment.
Both client and enrollment scopes pass through `ClientExternalDataSharing.remove_excluded_*`,
which is a no-op unless `GrdaWarehouse::Config.get(:enable_external_data_sharing_exclusion)`.

### De-identification decision table

Every row in this table was verified against the exporter code.

| Goal | Mechanism | Where it happens | What is changed | Gate |
|------|-----------|------------------|-----------------|------|
| HUD "SHA-256 (RHY)" export for external match | `hash_status == 4` | `Exporter::Client::Overrides.apply_hash_status` (`client/overrides.rb`) | `FirstName`, `MiddleName`, `LastName` become `SHA256(Soundex(name))`; `SSN` becomes last four characters of the `x`-padded SSN followed by `SHA256(padded SSN)`; all other columns untouched | Selectable in the full form; forced by `HashedOnlyHmisExportsController` |
| Developer or staging sample data | `faked_pii == true` | `Exporter::FakeData#process` (`fake_data.rb`), in every file's `transforms` after `adjust_keys` | Each key in `GrdaWarehouse::FakeData#fake_patterns` (names, `SSN`, `DOB` shifted by up to 600 days, `PersonalID` MD5, `UserID`, `CoCCode`, project/organization names, addresses, contact fields, free-text "Other" fields, assessment text) is replaced by a Faker value | Checkbox rendered only for `can_export_anonymous_hmis_data?`; the controller permits the param regardless |
| Hide HMIS-restricted clients from ordinary exports | always on | `Export::RestrictedClientPiiTransform` (`app/models/export/restricted_client_pii_transform.rb`), last in `Client.transforms` | Names and `NameSuffix` set to `GrdaWarehouse::PiiProvider::REDACTED`, `SSN` nil, `SSNDataQuality` 99, when `RestrictedClientLoader#restricted?(row.id)` | Skipped entirely when `hash_status == 4` or `faked_pii` |
| Hide confidential project/organization names | `confidential == true` | `Project::Overrides` and `Organization::Overrides` `ensure_reasonable_name` | Replaces `ProjectName` / `OrganizationName` with the configured confidential name when the record is flagged confidential | Checkbox rendered only for `can_view_confidential_project_names?` |
| Exclude clients who opted out of external sharing | config flag | `ClientExternalDataSharing.remove_excluded_clients` / `remove_excluded_enrollments` in `Export::Scopes` | Drops flagged clients and clients inside a one-week embargo from `Client.csv` and enrollment-derived files | `enable_external_data_sharing_exclusion` |

Facts that follow from the code:

- Faked values are stable across exports, not only within one. `setup_export` loads or
  creates one `GrdaWarehouse::FakeData` row per `faked_environment` (default `:development`),
  `fetch` reuses any mapping already in its `map` JSON, and `save_fake_data` persists new
  mappings at the end of a faked run.
- `hash_status == 4` and `faked_pii` are not mutually exclusive in the full controller. Both
  parameters are permitted, `Overrides` runs before `FakeData`, so a faked run with
  `hash_status == 4` writes hashes for `MiddleName` (not in `fake_patterns`) and fake values
  for `FirstName`, `LastName`, `SSN`, and writes `HashStatus = 4` to `Export.csv`. Only
  `HashedOnlyHmisExportsController` prevents the combination, by not permitting `faked_pii`.
- Neither mode touches dates other than `DOB`, enrollment structure, or service history.

### Recurring exports

`GrdaWarehouse::RecurringHmisExport` (`app/models/grda_warehouse/recurring_hmis_export.rb`) is
created by `HmisExportsController#create` when `every_n_days` is positive. It stores the
filter's `to_h` in `options`, plus `reporting_range`, `reporting_range_days`, and encrypted S3
credentials and `zip_password` (`attr_encrypted`, key from `ENV['ENCRYPTION_KEY']`). It
`acts_as_paranoid`. Each completed run is linked through
`GrdaWarehouse::RecurringHmisExportLink` (`hmis_export_id`, `recurring_hmis_export_id`,
`exported_at`), created in `ExportBaseJob#perform` when `recurring_hmis_export_id` is non-zero.

Scheduling: `config/schedule.rb` registers rake `grda_warehouse:process_recurring_hmis_exports`
once a day. `GrdaWarehouse::Tasks::ProcessRecurringHmisExports#run!`
(`app/models/grda_warehouse/tasks/process_recurring_hmis_exports.rb`) iterates every
definition and calls `run` when `should_run?` is true. `should_run?` returns
`Date.current - max(exported_at) >= every_n_days` once at least one export exists; before the
first run it returns `!updated_at.today?`, so a definition created or edited today waits until
tomorrow.

`run` rebuilds `Filters::HmisExport.new(filter_hash)`, where `filter_hash` merges the saved
options with the recurrence's own `reporting_range`, `reporting_range_days`, its `id` as
`recurring_hmis_export_id`, `version` defaulting to `HudHelper.current_version`, and
`user_id`. It calls `adjust_reporting_period` (recomputes dates for `n_days`, `month`, `year`;
`fixed` leaves them) and `schedule_job(report_url: nil)`, so no completion email is sent.

Delivery: `ExportBaseJob` calls `recurring_hmis_export.store(report)` when `s3_valid?`
(an `AwsS3` client could be built from `s3_region` and `s3_bucket`, with or without access
keys). `store` downloads the ActiveStorage zip, runs `encrypt_zip`, and uploads under
`object_name`: `<s3_prefix>-<YYYYMMDD>-<export_id>.<zip|7z>`. `encrypt_zip` returns the raw
zip when `zip_password` is blank; otherwise `encryption_type` `'zip'` shells out to `zipcloak`
through a generated `expect` script, and `'7z'` extracts the CSVs and rebuilds a `.7z` with
`7z a -mx9 -p<password>`. Both need the binaries on the worker image. The `HmisExport` row keeps
the unencrypted zip; only the S3 copy is encrypted.

The controller rejects a submission with `flash[:error] = 'Invalid S3 Configuration'` when
`s3_present?` but not `s3_valid?`. `cancel` destroys the recurrence (soft delete) when the
requester owns it or `can_view_all_reports?`.

## Key files

- `app/controllers/warehouse_reports/hmis_exports_controller.rb:55` `create` (recurrence
  creation, `adjust_reporting_period`, S3 validation, `schedule_job`); `:85` `show` streams the
  zip; `:165` `report_params`.
- `app/controllers/warehouse_reports/hashed_only_hmis_exports_controller.rb:13` forces
  `hash_status: '4'`; `:29` `export_scope` limited to hashed exports; `:33` reduced params.
- `app/models/filters/hmis_export.rb:118` `register_version`; `:148`
  `schedule_or_execute_job`; `:187` `effective_project_ids`; `:239` `adjust_reporting_period`.
- `app/models/grda_warehouse/hmis_export.rb:19` `has_one_attached :hmis_zip`; `:72`
  `clean_params`; `:100` `unzip_to`.
- `app/jobs/export_base_job.rb:14` `perform`; `:32` recurring link and S3 store.
- `app/models/concerns/export/exporter.rb:14` `setup_export`; `:19` `options` and `export_id`
  MD5; `:67` `zip_archive`; `:101` `set_time_format`.
- `app/models/concerns/export/scopes.rb:13` `client_scope`; `:31` `enrollment_scope`; `:63`
  `project_scope`; `:116` `apply_hoh_coc_filter`.
- `app/services/client_external_data_sharing.rb`: `remove_excluded_clients`,
  `remove_excluded_enrollments`, `EXCLUSION_TARGETS`.
- `drivers/hmis_csv_twenty_twenty_six/config/initializers/hmis_csv_twenty_twenty_six_feature.rb:10`
  version registration.
- `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/base.rb:78`
  `export!`; `:163` `class_mappings`; `:261` `custom_file_mappings`; `:325` `hmis_class`
  (`WithDeleted` swap).
- `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/export_concern.rb:142`
  `process`; `:152` `enforce_lengths`; `:177` `sanitize_string_fields`; `:220` `hashed_column?`.
- `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/export.rb:11`
  the `Export.csv` row.
- `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/client.rb:37`
  `transforms` order (`Overrides`, `Client`, `FakeData`, `RestrictedClientPiiTransform`).
- `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/client/overrides.rb:39`
  `apply_hash_status`.
- `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/fake_data.rb:17`
  `process`.
- `drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/csv_destination.rb:30`
  `write` (second rounding pass, `force_quotes`).
- `drivers/hmis_csv_twenty_twenty_six/app/jobs/hmis_csv_twenty_twenty_six/export_job.rb:11`
  `exporter_base`.
- `app/models/export/restricted_client_pii_transform.rb:19` `process`.
- `app/models/grda_warehouse/fake_data.rb:17` `fetch`; `:42` `fake_patterns`.
- `app/models/grda_warehouse/recurring_hmis_export.rb:27` `should_run?`; `:36` `run`; `:50`
  `store`; `:57` `encrypt_zip`; `:161` `object_name`; `:226` `filter_hash`.
- `app/models/grda_warehouse/tasks/process_recurring_hmis_exports.rb:13` `run!`.
- `lib/tasks/grda_warehouse.rake:484` rake task; `config/schedule.rb:51` daily schedule entry.

## Gotchas

- Faked PII is not safe for external sharing. `fake_patterns` covers a fixed list of columns;
  anything else (dates other than `DOB`, enrollment and service structure, custom assessment
  values not in the list) is exported as-is. The permission that unlocks the checkbox is
  described in `app/models/role.rb` as "Fake data exports for developers".
- XML export is retired: a case-insensitive grep for `xml` under `app/models/concerns/export`
  and the 2026 `exporter` directory returns nothing, so no XML code path remains.
- Name hashing is SHA-256 of the Soundex code, not of the raw name. Two names with the same
  Soundex produce the same hash. The SSN hash is prefixed with the last four characters in
  clear.
- The `faked_pii` gate is view-only. `HmisExportsController#report_params` permits `faked_pii`
  for any user who can reach the form; only the rendered checkbox checks
  `can_export_anonymous_hmis_data?`.
- `RestrictedClientPiiTransform` is bypassed when either de-identification mode is on. A faked
  export of a restricted client still carries that client's real `DOB` shifted by at most 600
  days and their real enrollment history.
- Version registration lives in `Rails.application.config.hmis_exporters`, populated in each
  driver's `to_prepare` block. A driver whose `register_version` line is commented out (2020,
  2022) cannot be selected; the 2020 driver has no exporter classes at all; `Filters::HmisExport#update`
  silently ignores an unregistered `version`.
- `set_time_format` mutates `Date::DATE_FORMATS[:default]` and `Time::DATE_FORMATS[:default]`
  for the whole process until `reset_time_format` runs in `ensure`. Anything else in the same
  worker during an export sees ISO formats.
- `export!` opens a `repeatable_read` transaction for the data files, so a long export holds a
  snapshot for its whole duration. Inside an existing transaction (transactional specs) it
  skips the isolation level.
- `period_type == 2` raises `NotImplementedError` in `Export::Scopes#enrollment_scope`; the
  form offers only 3 and 1.
- `should_run?` on a recurrence with no completed exports returns `!updated_at.today?`, so
  editing an existing definition that has never run pushes its first run to the next day.
  Editing one that has run does not.
- `encrypt_zip` shells out to `zipcloak` (via `expect`) or `7z`. A worker image without those
  binaries produces an S3 upload that fails or is empty, while the in-app download still works.
- The 2022 and 2024 drivers each have their own `ExportConcern`, `Client::Overrides`, and
  `FakeData`; a fix in the 2026 copies does not propagate.

## Do not repeat

- Adding a third de-identification switch (a new flag, a new transform that partially masks
  columns) outside `hash_status == 4` and `faked_pii`. Replace with: extend
  `GrdaWarehouse::FakeData#fake_patterns` (`app/models/grda_warehouse/fake_data.rb`) for faked
  output, or change `Exporter::Client::Overrides.apply_hash_status` for hashed output, and
  update the decision table in this doc. `Export::RestrictedClientPiiTransform` is the one
  sanctioned exception and is deliberately last in `Client.transforms` and skipped when either
  mode is on.
- Writing an exporter file class that does not `include ExportConcern` or that overrides
  `process` without calling the shared pipeline. Every existing class
  (`drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/client.rb`
  and siblings) defines only `adjust_keys`, `export_scope`, and `transforms`; `ExportID`,
  string sanitizing, length limits, and rounding come from `ExportConcern#process`.
- Formatting money or integer columns by assigning strings to ActiveRecord attributes in a
  transform and expecting the string to survive. AR re-casts on assignment; the working
  pattern is `CsvDestination#write` rounding on the plain hash
  (`drivers/hmis_csv_twenty_twenty_six/app/models/hmis_csv_twenty_twenty_six/exporter/csv_destination.rb`).
- Hard-coding an export job class name in a controller or task. Replace with
  `Filters::HmisExport#schedule_job` / `#execute_job`, which resolve the class from the
  registry populated by `Filters::HmisExport.register_version` in each driver's feature
  initializer.
- Registering a new HUD CSV version by editing an older driver. Copy
  `drivers/hmis_csv_twenty_twenty_six` to a new driver and register it; the 2022 and 2024
  drivers are frozen near-copies.
- Applying the external-data-sharing exclusion inside an individual file's `export_scope`.
  It belongs in `Export::Scopes#client_scope` and `#enrollment_scope` via
  `ClientExternalDataSharing.remove_excluded_*`, which already gate on the config flag.

## Related

- `hud-reporting/csv-import.md`: the Loader and Importer that consume these files; the same
  `hmis_csv_twenty_twenty_*` drivers hold both halves.
- `warehouse/pii-and-restricted-clients.md`: `GrdaWarehouse::PiiProvider`, HMIS-restricted
  client loading, and the redaction rules `Export::RestrictedClientPiiTransform` applies.
- `docs/features/warehouse/hmis-csv-export.md`: human-facing overview of the export.
- `docs/features/warehouse/recurring-hmis-exports.md`: human-facing operations notes for
  recurring exports.
- `docs/features/warehouse/external-data-sharing-exclusion.md`: the opt-out flag and embargo
  that `Export::Scopes` honours.

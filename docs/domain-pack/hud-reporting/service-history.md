---
title: Service history generation
summary: "ServiceHistoryEnrollment and the year-partitioned ServiceHistoryService table are the derived data every report reads. Covers full rebuild versus incremental patch, the homelessness classification rules, partitioning and the materialized view, daily triggers from imports and ProjectCleanup, and the WarehouseClientsProcessed cache downstream."
area: hud-reporting
tags: [service-history, ServiceHistoryEnrollment, ServiceHistoryService, ServiceHistoryServiceMaterialized, rebuild_service_history!, partition, ProjectCleanup, RunDailyImportsJob, WarehouseClientsProcessed, homeless, literally_homeless, UpdateWarehouseClientsCachesJob]
sources:
  - app/models/grda_warehouse/service_history_enrollment.rb
  - app/models/grda_warehouse/service_history_service.rb
  - app/models/grda_warehouse/service_history_service_materialized.rb
  - app/models/concerns/service_history_service_concern.rb
  - app/models/concerns/service_history/builder.rb
  - app/models/grda_warehouse/tasks/service_history/enrollment.rb
  - app/models/grda_warehouse/tasks/service_history/purge_for_deleted_data_sources.rb
  - app/models/grda_warehouse/tasks/sanity_check_service_history.rb
  - app/models/grda_warehouse/warehouse_clients_processed.rb
  - app/models/grda_warehouse/tasks/project_cleanup.rb
  - app/jobs/importing/run_daily_imports_job.rb
  - app/jobs/service_history/rebuild_enrollments_by_batch_job.rb
  - app/jobs/update_warehouse_clients_caches_job.rb
related:
  - hud-reporting/report-framework.md
  - hud-reporting/csv-import.md
  - warehouse/client-identity.md
---

## Purpose

Service history is the warehouse's flattened, day-by-day copy of HUD enrollment data. Every
HUD enrollment (`GrdaWarehouse::Hud::Enrollment`) produces `GrdaWarehouse::ServiceHistoryEnrollment`
rows (`record_type` `entry`, and `exit` when exited) and one
`GrdaWarehouse::ServiceHistoryService` row per day the client was served. Reports, cohorts,
CAS eligibility, and client dashboards read these tables instead of walking `Enrollment`,
`Exit`, `Services`, and `CurrentLivingSituation`.

The rows are generated, never entered. `GrdaWarehouse::Tasks::ServiceHistory::Enrollment`
(a subclass of `GrdaWarehouse::Hud::Enrollment`) owns the only write path,
`rebuild_service_history!`, which decides between a full rebuild, an incremental patch, or
nothing based on a SHA-256 hash of the source rows stored in `Enrollment.processed_as`.

`service_history_services` is range-partitioned by `date` into one table per year (2000 to
2050) plus a default partition, and a materialized view
(`service_history_services_materialized`) exists for per-client aggregates.
`GrdaWarehouse::WarehouseClientsProcessed` caches per-client totals computed from that view.

HUD rules for what counts as a bed night, a homeless project type, or a chronic project type
are out of scope here; see the HMIS domain knowledge MCP server (`search_docs`). This doc
covers how the code applies them.

## Entry points

- `GrdaWarehouse::Tasks::ServiceHistory::Enrollment#rebuild_service_history!`: the one
  method to call for a single enrollment. Returns `:update` (full rebuild), `:patch`, or
  `false` (nothing done or refused).
- `GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_process_date_range!(range)` and
  `.batch_process_unprocessed!`: queue `ServiceHistory::RebuildEnrollmentsByBatchJob` jobs
  (400 enrollments each, long-running queue) via `ServiceHistory::Builder.queue_enrollments`.
  `batch_process_unprocessed!` also waits for the queue to drain (`wait_for_processing`,
  default 6 hours). `queue_batch_process_unprocessed!` queues without waiting.
- `ServiceHistory::Builder.queue_clients(client_ids)` / `.wait_for_clients`: per destination
  client; forces a full rebuild first when `Client#service_history_invalidated?`.
- Invalidation: `GrdaWarehouse::Tasks::ServiceHistory::Enrollment#invalidate_source_data!`
  (nulls `processed_as` for the whole household when `HouseholdID` is set),
  `GrdaWarehouse::Hud::Enrollment.invalidate_processing!` (relation) and
  `#invalidate_processing!` (instance, `update_columns` without optimistic locking),
  `GrdaWarehouse::Hud::Client#force_full_service_history_rebuild` (deletes the client's
  `ServiceHistoryEnrollment` rows, nulls `processed_as`, destroys the processed cache row).
- Nightly: `Importing::RunDailyImportsJob#_perform`, maintenance task
  `Generate service history and related records`.
- `GrdaWarehouse::Tasks::ProjectCleanup#run!`: invalidates enrollments whose project changed
  type, moved, or whose homeless flags disagree with the project type, then runs
  `batch_process_unprocessed!(max_wait_seconds: 1_800)`.
- `GrdaWarehouse::Tasks::ServiceHistory::PurgeForDeletedDataSources.call(retain_at:)`:
  removes service history for data sources soft-deleted more than 24 hours ago.
- `GrdaWarehouse::Tasks::SanityCheckServiceHistory#run!`: compares entry/exit counts between
  source and service history; invalidates mismatched clients.
- `GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!` / `.rebuild!`.
- `GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids:)` and
  `UpdateWarehouseClientsCachesJob.perform_later(client_ids:)`.

## How it works

### Rebuild vs patch

`rebuild_service_history!` first calls `reset_service_history_memos!`, then returns `false`
when `EntryDate` is before 1970, when `destination_client`, `project`, or `data_source` is
missing, or when `already_processed?` (an entry/exit-tracked enrollment with `processed_as`,
`history_generated_on`, and an `ExitDate` later than `history_generated_on`). It sets
`history_generated_on = Date.current` and picks an action.

`should_rebuild?` is `!service_history_valid?`: `processed_as` must be present, equal
`calculate_hash`, and a `service_history_enrollment` row must exist. The hash is
`Enrollment.calculate_hash_for(id, project.ProjectType)`: SHA-256 over a `CONCAT` of
enrollment columns (`id`, `data_source_id`, `EntryDate`, `ProjectID`, `DateDeleted`,
`HouseholdID`, `RelationshipToHoH`, `MoveInDate`, `DateUpdated`), exit columns (`ExitDate`,
`DateDeleted`, `data_source_id`, `Destination`, `DateUpdated`), service columns
(`DateProvided`, `DateDeleted`, `data_source_id`, `DateUpdated`), the destination client `id`,
and, only for Street Outreach project types, `CurrentLivingSituation` columns. Rows are
explicitly ordered so the hash is stable.

`create_service_history!` runs a transaction that deletes the enrollment's
`ServiceHistoryEnrollment` rows (`entry`, `exit`, `first`), which cascades to the service rows
through each partition's `ON DELETE CASCADE` foreign key; inserts the `entry` row with a raw
Arel `InsertStatement` to capture its id; builds the day hashes; inserts the `exit` row if
exited. Outside the transaction it bulk-inserts the days with `activerecord-import` in batches
of 1000, rescuing `ActiveRecord::InvalidForeignKey`. Then `update(processed_as: calculate_hash)`.

`should_patch?` is true for any open entry/exit enrollment and any open extrapolating
enrollment. Otherwise it compares `build_for_dates.keys` to the service dates already stored;
equal means nothing to do. If the enrollment is exited or has fewer dates to build than stored,
it calls `create_service_history!(true)` and returns `false`. `patch_service_history!` inserts
only the missing days (plus extrapolated days), rescuing `ActiveRecord::RecordNotUnique`
because `on_duplicate_key_update` is unavailable on the partitioned table, then updates
`processed_as`.

### Dates built per enrollment

`entry_exit_tracking?` is the negation of `nbn_tracking?`, which is true when `project.es_nbn?`
or when `street_outreach_acts_as_bednight?` (an SO project with any `CurrentLivingSituation`
on any of its enrollments).

Entry/exit tracked: `build_for_dates` is every day from `build_from` (the latest of `EntryDate`,
client DOB, and 2000-01-01) to `build_until`, each with `service_type` 200 (bed night) when the
project type is housing related (`service_type_from_project_type`), else `nil`.

Night-by-night: `build_for_dates` is the `Services` rows with `RecordType` 200 between
`EntryDate` and `build_until`, keyed by `DateProvided`. For SO projects the
`CurrentLivingSituation.InformationDate` values are merged in as 200s.

`build_until`: with an exit, `ExitDate - 1.day` for entry/exit tracking unless entry and exit
are the same day, `ExitDate` itself for night-by-night, capped at the end of next year. Open
enrollments build to `Date.current` when `data_source.hmis?` or there is no `Export`; otherwise
to the earliest of `export.effective_export_end_date`, `export.ExportEndDate`, and `Date.current`.

Extrapolation (`extrapolates_days?`): `street_outreach_acts_as_bednight?` with
`GrdaWarehouse::Config.get(:so_day_as_month)`, or `project.extrapolate_contacts`.
`add_extrapolated_days` expands each contact date to its whole calendar month, never past
`Date.current`, removes the contact dates and any dates already stored as `service` or
`extrapolated`, and writes the rest with `record_type` `extrapolated`. Scopes that read
`record_type` `service` include `extrapolated` only when `so_day_as_month` is on
(`ServiceHistoryServiceConcern.service_types`); `service_excluding_extrapolated` never does.

Age and household columns (`age`, `head_of_household_id`, `unaccompanied_youth`,
`parenting_youth`, `children_only`, `presented_as_individual`, `move_in_date`, and the rest)
are computed once per enrollment in `default_day` and copied onto the entry and exit rows.
`move_in_date` falls back to the head of household's `MoveInDate` (floored at `EntryDate`)
when the member has none.

### Classification truth table

Each `ServiceHistoryService` row carries `homeless` and `literally_homeless`, set in
`GrdaWarehouse::Tasks::ServiceHistory::Enrollment#build_service_days` from
`homeless_for_project_type` and `literally_homeless_for_project_type`, both keyed on
`HudHelper.util` type lists. `nil` means "not categorized": the day matches neither the
`homeless` nor the `non_homeless` scope of `ServiceHistoryServiceConcern`.

| Project type | `homeless` | `literally_homeless` |
|---|---|---|
| `HudHelper.util.chronic_project_types` | `true` | `true` |
| TH | `true` | `false` |
| PH with `MoveInDate`, day strictly after move-in | `false` | `false` |
| PH with `MoveInDate`, day on or before move-in | `nil` | `nil` |
| PH without `MoveInDate` | `nil` | `nil` |
| Services Only, Other, Day Shelter, HP, CE, anything else | `nil` | `nil` |

`homeless` is `true` for `HudHelper.util.homeless_project_types`, else `nil`.
`literally_homeless` is `true` for `chronic_project_types`, `false` for TH, else `nil`. The
membership of both lists is version-specific and lives in the HUD utility class. The PH flip uses `date > self.MoveInDate`, the enrollment's own `MoveInDate`, not
the household-derived `move_in_date` written to the `ServiceHistoryEnrollment` row. The
move-in day itself stays `nil`.

The `ServiceHistoryEnrollment` scopes `currently_homeless` and `hud_currently_homeless` do not
read these flags. They take ongoing `entry` rows in homeless types and exclude clients who also
have an ongoing PH (or PH and TH, for `chronic_types_only`) enrollment with `move_in_date`
before the date.

`GrdaWarehouse::Tasks::ProjectCleanup#homeless_mismatch?` checks the last two years of service
rows per project: a homeless-type project must have no rows with `homeless` not `true`; any
other project type must have no rows with `homeless: true`; likewise for
`literally_homeless` against `chronic_project_types`. A mismatch invalidates the project's
enrollments so the flags are regenerated.

### Partitioning and the materialized view

`service_history_services` is declared `PARTITION BY RANGE (date)` in
`db/warehouse_structure.sql`. Partitions `service_history_services_2000` through
`service_history_services_2050` are attached `FOR VALUES FROM ('YYYY-01-01') TO ('YYYY+1-01-01')`;
`service_history_services_remainder` is attached as the `DEFAULT` partition for dates outside
that range. `GrdaWarehouse::ServiceHistoryService.table_years` (`2000..2050`), `.sub_tables`,
`.remainder_table`, and `.parent_table` mirror this. Routing is PostgreSQL's declarative
partitioning; a `service_history_service_insert_trigger` function still exists but is attached
only to the legacy `service_history_services_was_for_inheritance` table.

Each partition has its own foreign key to `service_history_enrollments(id)` with
`ON DELETE CASCADE` and a unique index on `(date, service_history_enrollment_id)`. The
`belongs_to :service_history_enrollment` on `ServiceHistoryService` and the `has_many` on
`ServiceHistoryEnrollment` use the composite key `[id, client_id]` /
`[service_history_enrollment_id, client_id]`. The builder scopes lookups with a `date` range
(`date_range` in the task class) so PostgreSQL prunes partitions.

`GrdaWarehouse::ServiceHistoryServiceMaterialized` maps `service_history_services_materialized`,
defined as `SELECT * FROM service_history_services`. `refresh!` runs
`REFRESH MATERIALIZED VIEW` (not `CONCURRENTLY`). `rebuild!` drops, recreates, and adds a
unique index on `id` plus indexes on `(client_id, project_type, record_type)`,
`(homeless, project_type, client_id)`, `(literally_homeless, project_type, client_id)`,
`(client_id, date)`, and `service_history_enrollment_id`. `double_check_materialized_view`
compares the most recent homeless date per client between the view and the live table for a
sample and pings the notifier on a discrepancy. `WarehouseClientsProcessed::StatsCalculator`
reads the view, not the partitioned table; `ProjectCleanup` and the builder read the live table.

### Daily pipeline order

`Importing::RunDailyImportsJob#perform` takes the `run_daily_imports_job` advisory lock, waits
up to 20 minutes for active HMIS imports (`settle_imports`), then runs `_perform`. Maintenance
tasks in code order:

1. `Update Client ROIs`: `Hud::Client.revoke_expired_consent`; `HmisClient.maintain_client_consent`
   when `release_duration` is `Use Expiration Date`.
2. `Update HMIS forms`: ETO TouchPoint-derived fields; ends with a second, unguarded
   `HmisClient.maintain_client_consent`.
3. `Sync with CAS`.
4. `Identify Duplicates`: `IdentifyDuplicates#run!`, `#match_existing!`, `ClientMatch.auto_process!`.
   Runs after both consent tasks.
5. `Clean projects & clients`: `ProjectCleanup#run!` (which itself queues and waits on
   invalidated enrollments), then `ClientCleanup#run!`.
6. `Generate service history and related records`: `PurgeForDeletedDataSources.call`;
   `batch_process_date_range!` for enrollments open in the last year; `batch_process_unprocessed!`;
   `SanityCheckServiceHistory` over all destination clients; `EarliestResidentialService`;
   `ServiceHistoryServiceMaterialized.refresh!` and `double_check_materialized_view` on a
   500-client sample; `WarehouseClientsProcessed.update_cached_counts`.
7. `Maintain name search maintenance`, 8. `Import Census`.
9. `Chronically Homeless at Entry`: `ChEnrollment.maintain!`; the chronic calculators run only
   on the 1st and 15th.
10. `Finalize client history`: `ClientCleanup#run!` again, `SanityCheckServiceHistory` again,
    `warm_cache`.
11. `Legacy reporting setup`, 12. `Prune HUD report data`, 13. `System maintenance`.

There is no task named for client retention. `ClientCleanup` (unused destination clients)
runs before service history in task 5 and after it in task 10. `PurgeForDeletedDataSources`
has a `retain_at` of 24 hours and runs first inside task 6. Because `IdentifyDuplicates`
(task 4) precedes generation (task 6), a merge done tonight is reflected in tonight's service
history through the destination client id in the hash.

### Downstream caches

`GrdaWarehouse::WarehouseClientsProcessed` holds one row per destination client with
`routine: 'service_history'`. `update_cached_counts` with no `client_ids` selects destination
clients with an enrollment open in the last year, slices them by 5000, and enqueues
`UpdateWarehouseClientsCachesJob` per slice: the first slice with `include_cas_and_cohorts:
true`, later slices with `skip_expensive_calculations: true`. With `client_ids` it computes
inline.

`internal_update_cached_counts` splits ids into `limited_data` (dashboard fields:
`first_homeless_date`, `last_homeless_date`, `homeless_days`, `first_chronic_date`,
`last_chronic_date`, `chronic_days`, `first_date_served`, `last_date_served`, `days_served`,
`days_homeless_last_three_years`, `literally_homeless_last_three_years`,
`days_homeless_plus_overrides`, `last_intentional_contacts`, `last_exit_destination`) and
`extra_data` (clients on an active cohort or `cas_active`, who also get ongoing-enrollment
flags, household members, VI-SPDAT scores, CAS match fields, and per-type last visits). Rows
are upserted with `import` on `(client_id, routine)` under the `WarehouseClientsProcessed#upsert`
advisory lock, then `Hud::Client.destination.clear_view_cache(client_id)`.

`StatsCalculator` reads `ServiceHistoryServiceMaterialized`. Homeless-day counts exclude days
that overlap a `homeless: false` PH day (and TH for the literal variants);
`most_recent_homeless_dates` drops `extrapolated` rows unless
`Config.get(:ineligible_uses_extrapolated_days)` and includes projects with
`overrides_homeless_active_status`.

`UpdateWarehouseClientsCachesJob` takes the `UpdateWarehouseClientsCachesJob` advisory lock
(20 second timeout) and requeues itself four minutes out when another instance holds it.
`SanityCheckServiceHistory#sanity_check` and `Tasks::ServiceHistory::Add#run!` also call
the cache update for the clients they rebuilt.

## Key files

- `app/models/grda_warehouse/tasks/service_history/enrollment.rb`: `rebuild_service_history!`,
  `should_rebuild?`, `should_patch?`, `create_service_history!`, `patch_service_history!`,
  `build_service_days`, `homeless_for_project_type`, `literally_homeless_for_project_type`,
  `add_extrapolated_days`, `build_for_dates`, `build_from`, `build_until`,
  `calculate_hash_for`, `hash_columns`, `default_day`, `invalidate_source_data!`.
- `app/models/concerns/service_history/builder.rb`: `queue_enrollments`, `queue_clients`,
  `wait_for_processing`, `wait_for_clients`, `clients_still_processing?`, batch size 400.
- `app/jobs/service_history/rebuild_enrollments_by_batch_job.rb`: calls
  `rebuild_service_history!` per enrollment id; `max_attempts` 2.
- `app/models/grda_warehouse/service_history_enrollment.rb`: driver extensions, `entry`/`exit`/
  `first_date` scopes, `ongoing`, `open_between`, `currently_homeless`, `with_service_between`,
  `bed_nights`, `view_column_names`.
- `app/models/grda_warehouse/service_history_service.rb`: composite `belongs_to`, date and
  project-type scopes, `table_years`, `sub_tables`, `remainder_table`, `parent_table`.
- `app/models/concerns/service_history_service_concern.rb`: `service`, `extrapolated`,
  `service_excluding_extrapolated`, `homeless`, `literally_homeless`, `non_homeless`,
  `in_project_type`, `service_types`; shared by the table model and the view model.
- `app/models/grda_warehouse/service_history_service_materialized.rb`: `refresh!`, `rebuild!`,
  `view_sql`, `double_check_materialized_view`.
- `app/models/grda_warehouse/tasks/project_cleanup.rb`: `should_update_type?`,
  `fix_project_type`, `invalidate_service_for_moved_projects`, `homeless_mismatch?`,
  `fix_name`, `fix_client_locations`.
- `app/models/grda_warehouse/tasks/service_history/purge_for_deleted_data_sources.rb`:
  `call(retain_at:)`, services deleted before enrollments in 1000-enrollment batches.
- `app/models/grda_warehouse/tasks/sanity_check_service_history.rb`: `run!`, `sanity_check`,
  `MAX_ATTEMPTS`.
- `app/jobs/importing/run_daily_imports_job.rb`: `_perform` task order.
- `app/models/grda_warehouse/warehouse_clients_processed.rb`: `update_cached_counts`,
  `internal_update_cached_counts`, `StatsCalculator`.
- `app/jobs/update_warehouse_clients_caches_job.rb`: advisory lock and requeue.

## Gotchas

- Partition range is fixed at 2000 to 2050 in both the schema and
  `ServiceHistoryService.table_years`. Dates outside land in `service_history_services_remainder`
  (the `DEFAULT` partition). Adding a year means a schema change plus updating `table_years`.
- `on_duplicate_key_update` does not work on the partitioned table. The builder rescues
  `ActiveRecord::RecordNotUnique` on patch and `ActiveRecord::InvalidForeignKey` on create; a
  crash between the `ServiceHistoryEnrollment` transaction and the service-row import leaves
  entry rows with no days until the next hash mismatch or sanity check.
- Querying `service_history_services` without a `date` predicate scans every partition. Use
  `service_between`, `on_date`, `homeless_between`, or an explicit `date:` range.
- A `ProjectType` change does not change the hash directly (the hash covers `ProjectID`, not
  type). `ProjectCleanup#should_update_type?` detects it by comparing distinct
  `ServiceHistoryEnrollment.project_type` values to `project.ProjectType` and forces the
  rebuild; until the nightly job runs, flags reflect the old type.
- `calculate_hash` includes `CurrentLivingSituation` only for SO project types. A CLS change on
  a non-SO enrollment does not trigger a rebuild.
- `already_processed?` short-circuits `rebuild_service_history!` when an exited entry/exit
  enrollment's `ExitDate` is later than `history_generated_on`. Invalidate `processed_as` to
  force work on such an enrollment.
- `WarehouseClientsProcessed::StatsCalculator` reads the materialized view. An on-demand
  `UpdateWarehouseClientsCachesJob` after a rebuild reports stale numbers until
  `ServiceHistoryServiceMaterialized.refresh!` runs; the nightly job refreshes before
  `update_cached_counts`.
- `refresh!` is a plain `REFRESH MATERIALIZED VIEW`, which blocks readers of the view while it
  runs.
- `ServiceHistory::Builder.builder_create_enrollment_jobs` never writes
  `Enrollment.service_history_processing_job_id` (the `update_all` is commented out), so
  `clients_still_processing?` only finds enrollments that got the column set some other way.
  `wait_for_processing` polls the Delayed::Job table instead.
- In `Rails.env.test?`, `wait_for_processing` and `wait_for_clients` call
  `Delayed::Worker.new.work_off(2)` rather than polling; specs that queue more than two batches
  must drain the queue themselves.
- `ProjectCleanup#invalidate_service_for_moved_projects` deletes `ServiceHistoryEnrollment` rows
  whose project no longer resolves, so those enrollments disappear from the app until the
  rebuild finishes.
- `WarehouseClientsProcessed.update_cached_counts` without ids only covers clients with an
  enrollment open in the last year. Older clients keep stale cache rows until something passes
  their ids explicitly.

## Do not repeat

- Writing to `service_history_enrollments` or `service_history_services` from feature code.
  The only writer is `GrdaWarehouse::Tasks::ServiceHistory::Enrollment`
  (`create_service_history!`, `patch_service_history!`,
  `remove_existing_service_history_for_enrollment`). Invalidate with
  `invalidate_source_data!` or `Enrollment.invalidate_processing!` and let the builder run;
  existing example: `GrdaWarehouse::Tasks::ProjectCleanup#fix_project_type`.
- Deriving homelessness from project type inline (`project_type.in?([0, 1, 4, 8])`). Use the
  stored `homeless` / `literally_homeless` flags through the `ServiceHistoryServiceConcern`
  scopes, or `HudHelper.util.homeless_project_types` / `.chronic_project_types` when a type
  list is needed; existing example: `WarehouseClientsProcessed::StatsCalculator#first_homeless_dates`.
- Hard-coding HUD project type integers. `service_type_from_project_type` in
  `app/models/grda_warehouse/tasks/service_history/enrollment.rb` still carries a literal
  `[0, 1, 2, 3, 4, 8, 9, 10, 13]`; do not copy it. Use `HudHelper.util` lists.
- Adding a third scheduled call to `WarehouseClientsProcessed.update_cached_counts`. The nightly
  job, `SanityCheckServiceHistory`, and `Tasks::ServiceHistory::Add` already do; a feature that
  needs fresh numbers for specific clients enqueues
  `UpdateWarehouseClientsCachesJob.perform_later(client_ids:)`.
- Bypassing `ServiceHistory::Builder.queue_enrollments` to enqueue
  `ServiceHistory::RebuildEnrollmentsByBatchJob` directly. The builder holds the
  `rebuild_enrollments` advisory lock and skips enrollment ids already queued.
- Reading `ServiceHistoryService` for per-client totals in a request. Read
  `WarehouseClientsProcessed` (`Client#processed_service_history`) and enqueue a cache update
  if it is missing.

## Related

- `hud-reporting/report-framework.md`: the report generators that read
  `ServiceHistoryEnrollment` and `ServiceHistoryService`.
- `hud-reporting/csv-import.md`: the importer that changes the source rows whose hash drives
  rebuilds.
- `warehouse/client-identity.md`: destination clients and `IdentifyDuplicates`, whose merges
  change the destination client id in the hash.
- `roi/consent-from-external-sources.md`: the consent tasks that precede service history in
  `Importing::RunDailyImportsJob`.
- Human-facing source: `docs/features/warehouse/service-history.md`.

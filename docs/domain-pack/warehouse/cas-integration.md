---
title: CAS integration
summary: "How the warehouse feeds the separate CAS (Coordinated Access System) database. PushClientsToCas builds the outbound project_clients payload including release status, CasBase is the connection to the CAS database (a stub without DATABASE_CAS_DB) that only the push task writes through, project client calculators decide per-installation values, and the cas_access and cas_ce_data drivers read CAS models and turn CAS assessments and referrals into synthetic HUD records."
area: warehouse
tags: [cas, PushClientsToCas, SyncToCasJob, CasBase, db_exists?, CasClientData, cas_active, active_in_cas?, cas_project_client_calculator, ManageCasFlags, cas_readiness, cas_access, cas_ce_data, release_status_for_cas, CasAvailability, CasHoused, synthetic-events]
sources:
  - app/models/grda_warehouse/tasks/push_clients_to_cas.rb
  - app/jobs/cas/sync_to_cas_job.rb
  - app/models/cas_base.rb
  - app/models/concerns/cas_client_data.rb
  - app/models/grda_warehouse/cas_project_client_calculator/default.rb
  - app/models/grda_warehouse/cas_availability.rb
  - app/models/grda_warehouse/cas_housed.rb
  - app/controllers/warehouse_reports/manage_cas_flags_controller.rb
  - app/controllers/clients/cas_readiness_controller.rb
  - drivers/cas_access/README.md
  - drivers/cas_access/app/models/cas_access/project_client.rb
  - drivers/cas_access/app/models/cas_access/extensions/user_extension.rb
  - drivers/cas_ce_data/README.md
  - drivers/cas_ce_data/config/initializers/cas_ce_data_feature.rb
  - drivers/cas_ce_data/app/models/cas_ce_data/synthetic/assessment.rb
  - drivers/cas_ce_data/app/models/cas_ce_data/synthetic/event.rb
related:
  - roi/roi-authorizations-and-visibility.md
  - hmis/coordinated-entry.md
---

## Purpose

CAS is the Coordinated Access System, a separate Rails application (`boston-cas`, its own
repository) with its own PostgreSQL database. It matches clients to housing vacancies. The
warehouse does not run matching; it decides which destination clients are available for
matching and pushes a flattened per-client row into the CAS `project_clients` table. CAS in
turn writes match outcomes back into warehouse tables (`cas_reports`, `cas_houseds`,
`cas_ce_assessments`, `cas_referral_events`) that warehouse code only reads.

This doc covers the warehouse side of that coupling:

- `GrdaWarehouse::Tasks::PushClientsToCas`, the outbound sync, and `Cas::SyncToCasJob`,
  the job that wraps it.
- `CasClientData`, the concern on `GrdaWarehouse::Hud::Client` that decides who is active for
  CAS and computes most payload values.
- `GrdaWarehouse::CasProjectClientCalculator::*`, per-installation strategies that override how
  individual payload columns are computed.
- `CasBase`, the connection class for CAS tables, and why it is a no-op stub when
  `DATABASE_CAS_DB` is unset.
- The `cas_access` driver (read models over CAS tables) and the `cas_ce_data` driver (CAS
  assessments and referral events reflected as synthetic HUD CE records).

CAS is distinct from HMIS coordinated entry. The HMIS CE match engine, workflows, and referrals
live in `drivers/hmis` and are documented in `hmis/coordinated-entry.md`; nothing there goes
through `CasBase`. Consent and release status, which gate a client's usefulness in CAS, are
documented in `roi/roi-authorizations-and-visibility.md`; this doc only describes how the
release status value is mapped into the payload.

Use this doc when a client is missing from CAS, when adding or changing a `project_clients`
column, when adding a new installation-specific calculator, or when a spec touches any
`CasAccess::*` model.

## Entry points

- `GrdaWarehouse::Tasks::PushClientsToCas#sync!`
  (`app/models/grda_warehouse/tasks/push_clients_to_cas.rb`): the sync. Returns immediately
  unless `CasBase.db_exists?`. Takes the `push-clients-to-cas` advisory lock on the warehouse
  connection and exits with a notifier ping if another sync holds it.
- `Cas::SyncToCasJob` (`app/jobs/cas/sync_to_cas_job.rb`): `perform_later` wrapper on the long
  queue. Enqueued by `Clients::CasReadinessController#update`, `Clients::ChronicController`,
  and `WarehouseReports::ManageCasFlagsController#bulk_update`.
- `Importing::RunDailyImportsJob#sync_with_cas`: the nightly call. Runs
  `GrdaWarehouse::CasHoused.inactivate_clients` first (clears `sync_with_cas` for clients CAS
  reports as housed), then `PushClientsToCas.new.sync!`. The same job enqueues
  `SyncSyntheticDataJob` when `CasBase.db_exists?`, which is what runs the `cas_ce_data`
  synthetic sync.
- `rake cas:sync` (`lib/tasks/cas.rake`): manual trigger of the same task.
- `GrdaWarehouse::Hud::Client.cas_active` and `#active_in_cas?` (`app/models/concerns/cas_client_data.rb`):
  the scope and the per-client predicate that decide availability. Both switch on
  `GrdaWarehouse::Config.get(:cas_available_method)`.
- `PushClientsToCas#attributes_for_display(user, client)`: the same column map rendered for one
  client on the CAS Readiness page (`app/views/clients/cas_readiness/_attributes_table.haml`,
  rendered through `BackgroundRender::CasReadinessJob`). Display only; not used by the sync.
- `Clients::CasReadinessController` (`clients/:id/cas_readiness`): edits the per-client CAS
  flags, calls `sync_cas_attributes_with_files`, enqueues the job.
- `WarehouseReports::ManageCasFlagsController` (`warehouse_reports/manage_cas_flags`): bulk
  set or clear one flag column for a pasted list of client ids.
- `GrdaWarehouse::Config.cas_enabled?`: alias for `CasBase.db_exists?`; use it in views and
  reports to hide CAS-only UI.
- `User#cas_user` (`drivers/cas_access/app/models/cas_access/extensions/user_extension.rb`):
  the `CasAccess::User` whose email matches the warehouse user, used by the CAS warehouse
  reports under `app/controllers/warehouse_reports/cas/`.

## How it works

### Eligibility and payload

`PushClientsToCas#sync!` selects `GrdaWarehouse::Hud::Client.cas_active` and plucks the ids.
`cas_active` is a scope in `CasClientData` that switches on
`GrdaWarehouse::Config.get(:cas_available_method)`; the option list is
`GrdaWarehouse::Config.available_cas_methods`: `cas_flag`, `chronic`, `hud_chronic`,
`release_present`, `active_clients`, `project_group`, `boston`, `ce_with_assessment`. Every
method except `cas_flag` is OR'd with `where(sync_with_cas: true)`, so the manual checkbox
always adds a client. `active_in_cas?` is the per-client mirror of the scope and additionally
returns false for `deceased?` or `moved_in_with_ph?`; it is what fills the `sync_with_cas`
column of the payload, so a client can be in the pushed set yet marked unavailable. The
`active_clients` method uses `active_clients_project_ids_for_cas_sync`: the configured project
group's `effective_project_ids` if one is set, otherwise all homeless project types plus CE plus
projects with `active_homeless_status_override`.

Inside one CAS transaction the task first runs `CasAccess::ProjectClient.update_all(sync_with_cas: false)`,
then processes ids in slices of 150. For each slice it loads existing `project_clients` rows
for the warehouse `CasAccess::DataSource` (`name: 'DND Warehouse'`, created on demand), preloads
the client associations the column methods need, and builds one row per client from
`project_client_columns`, a hash of CAS column name to client method name. Each value is
fetched through the configured calculator's `value_for_cas_project_client(client:, column:)`.
The `Default` calculator calls `client.send(column)`; installation calculators override
specific columns. Enrollment-derived flags (`enrolled_in_es`, `enrolled_in_rrh_pre_move_in`,
`enrolled_project_ids`, `file_tags`, `days_homeless` unless the calculator
`handles_days_homeless?`) are set after the column map. Rows are written with
`activerecord-import`: `import!` with `on_duplicate_key_update` for existing rows, plain
`import!` for new ones.

After all slices, `maintain_cas_availability_table` updates `GrdaWarehouse::CasAvailability`
(a warehouse table): closes rows for clients no longer in the set and opens rows for new ones,
recording family status and age at the time. That table feeds availability reporting, not CAS.

### Release status mapping

The payload carries two consent-derived columns. `housing_release_status` is filled from
`GrdaWarehouse::Hud::Client#release_status_for_cas` and
`housing_assistance_network_released_on` from `consent_form_signed_on`. Both live in
`app/models/concerns/cas_client_data.rb` and read the destination client's consent columns;
they do not consult `GrdaWarehouse::ClientRoiAuthorization`.

`release_status_for_cas` returns `'None on file'` when `housing_release_status` is blank. When
`release_duration` is `One Year` or `Use Expiration Date` and the client is not both
`consent_form_valid?` and `consent_confirmed?`, it returns `'Expired'`. Otherwise it returns
`Translation.translate(housing_release_status)`, so CAS receives the installation's translated
label for the full or partial release string, not the raw stored value. How
`housing_release_status`, `release_duration`, and the consent dates get onto the client is
covered in `roi/roi-authorizations-and-visibility.md` and `roi/consent-records.md`; the
mapping here is the only CAS-specific consent logic and matches what that doc states.

Two CAS availability methods depend on release status directly: `release_present` selects any
client whose `housing_release_status` is the full or partial release string, and `boston`
requires a release plus an ongoing enrollment in the configured project group (the former
Pathways-assessment requirement is commented out in both `cas_active` and `active_in_cas?`).
`WarehouseReports::ManageCasFlagsController` exposes `full_housing_release` and
`limited_cas_release` as bulk flags; both write the `housing_release_status` column and the
controller never unflags them (`unflag` returns 0 for those two), because clearing a release
is a consent decision, not a CAS flag.

`contact_info_for_rrh_assessment` also gates on `consent_form_valid?`: assessment contact
details are omitted from the payload when consent is not valid.

### Read-only CAS connection

`app/models/cas_base.rb` defines `CasBase` two different ways depending on
`ENV['DATABASE_CAS_DB']` at load time. When it is present, `CasBase < ActiveRecord::Base` is
an abstract class with `connects_to database: { writing: :cas, reading: :cas }` and
`db_exists?` returns true; `config/database.yml` only defines the `cas` entry under the same
guard (test uses `CAS_DATABASE_DB_TEST` for the database name). When it is unset, `CasBase` is
a plain Ruby class: `db_exists?` returns false, `has_many` returns `[]`, `has_one` and
`belongs_to` return nil, and `method_missing` on both the class and instances returns nil.
Every `CasAccess::*` model inherits from `CasBase`, so `CasAccess::Tag.where(...)` evaluates
to nil rather than raising when no CAS database is configured.

The stub is environment-agnostic: a test run without `DATABASE_CAS_DB` gets the stub, and a
production deploy without it disables CAS entirely. Code that needs CAS must check
`CasBase.db_exists?` (or `GrdaWarehouse::Config.cas_enabled?`) before assuming a result, and
must tolerate nil from any `CasAccess` call. `PushClientsToCas#sync!`, `SyncSyntheticDataJob#perform`,
and `RunDailyImportsJob` all guard this way.

The connection is technically read-write; "read-only" is a convention. The only code that
writes through `CasBase` is `PushClientsToCas` (`update_all`, `import!` on
`CasAccess::ProjectClient`, and `first_or_create` on `CasAccess::DataSource`). All other users
of `CasAccess::*` models are reports and the `cas_tags` lookup. Warehouse-side tables that CAS
populates (`GrdaWarehouse::CasReport`, which declares `readonly?` true, `GrdaWarehouse::CasHoused`,
and the `cas_ce_data` source tables) are on the warehouse connection, not `CasBase`.

`Dba::DatabaseBloat` does not subclass `CasBase`; it is a maintenance utility that lists
`CasBase` among the connection base classes it inspects.

### Drivers

**`cas_access`** (`drivers/cas_access`) is a set of read models over CAS tables, each
`< CasBase` with an explicit `self.table_name` because `CasAccess.table_name_prefix` is
`cas_access_`: `ProjectClient`, `Client`, `DataSource`, `User`, `Role`, `Agency`, `Program`,
`SubProgram`, `Opportunity`, `Voucher`, `ClientOpportunityMatch`, `Contact`, `Tag`,
`Neighborhood`, `NonHmisClient`, `ActivityLog`, and reporting helpers under
`CasAccess::Reporting`. Its one extension, `CasAccess::UserExtension`, is included in `User`
and adds `cas_user`, the `CasAccess::User` with the same email. The CAS warehouse reports
(`app/controllers/warehouse_reports/cas/*`) use `cas_user` to scope programs to the user's CAS
agency unless that user is a CAS match admin. The access-logs user summary reads
`CasAccess::ActivityLog` and `CasAccess::User` when `cas_enabled?`. The driver has no routes,
controllers, or views of its own; its README is one line.

**`cas_ce_data`** (`drivers/cas_ce_data`) turns CAS-generated CE assessments and referral
events into HUD CE records. CAS writes to three warehouse tables: `cas_ce_assessments`,
`cas_referral_events`, and `cas_programs_to_projects` (CAS program id to warehouse project id).
The driver's `CasCeData::GrdaWarehouse::CasCeAssessment` and `CasReferralEvent` models read
them and join to projects through `ProgramToProject`. The feature initializer registers
`CasCeData::Synthetic::Assessment` and `CasCeData::Synthetic::Event` in
`Rails.application.config.synthetic_assessment_types` and `synthetic_event_types`, which
`GrdaWarehouse::Synthetic` exposes and `SyncSyntheticDataJob` iterates. Each synthetic class
implements `sync` as `remove_orphans` then `add_new`: `add_new` finds source rows with no
synthetic row, locates the client's open, CoC-funded, CE-participating enrollment on the
assessment date (or within 90 days before the referral date for events, preferring an
enrollment that already has an assessment), narrows to the mapped projects when any exist,
and creates the synthetic record. The synthetic records report `data_source` as `'CAS'`;
per the README, a warehouse data source with short name `CAS` distinguishes them. The
assessment model's header notes the fixed HUD assumptions: prioritization status "on the
list", assessment level housing needs, assessment type virtual.

## Key files

- `app/models/grda_warehouse/tasks/push_clients_to_cas.rb:22` `sync!`; `:151`
  `maintain_cas_availability_table`; `:176` `project_client_columns` (the CAS column to client
  method map); `:311` `attributes_for_cas_project_client`; `:324` `attributes_for_display`;
  `:433` `skip_for_display` (PII and permission-gated columns hidden on the readiness page);
  `:460` `calculator_instance`.
- `app/jobs/cas/sync_to_cas_job.rb:10`: `Cas::SyncToCasJob`.
- `app/models/cas_base.rb:9`: the `ENV['DATABASE_CAS_DB']` branch that picks the real
  abstract class or the stub.
- `app/models/concerns/cas_client_data.rb:12` `cas_active`; `:80`
  `active_clients_project_ids_for_cas_sync`; `:364` `cas_columns_data` (titles and
  descriptions for flags); `:416` `ignored_for_batch_maintenance`; `:498` `active_in_cas?`;
  `:569` `force_remove_unavailable_fors`; `:577` `release_status_for_cas`; `:613`
  `cohort_ids_for_cas`; `:623` `cas_tags`; `:657` `sync_cas_attributes_with_files`; `:888`
  `attr_accessor` list of non-persisted payload columns.
- `app/models/grda_warehouse/cas_project_client_calculator/default.rb:16`
  `value_for_cas_project_client`; `:21` `handles_days_homeless?`; `:33` `unrelated_columns`.
  Sibling calculators in the same directory: `boston.rb`, `mdha.rb`, `springfield.rb`,
  `tc_hat.rb`, `tc_hmis_hat.rb`, all `< Default`.
- `app/models/grda_warehouse/cas_availability.rb`: warehouse-side availability history.
- `app/models/grda_warehouse/cas_housed.rb:16` `inactivate_clients`.
- `app/controllers/warehouse_reports/manage_cas_flags_controller.rb:73` `bulk_update`;
  `:127` `unflag` (no-op for release types); `:137` `flag`.
- `app/controllers/clients/cas_readiness_controller.rb:29` `update`.
- `drivers/cas_access/app/models/cas_access/project_client.rb`: `table_name :project_clients`.
- `drivers/cas_access/app/models/cas_access/extensions/user_extension.rb:15` `cas_user`.
- `drivers/cas_ce_data/config/initializers/cas_ce_data_feature.rb`: synthetic type
  registration.
- `drivers/cas_ce_data/app/models/cas_ce_data/synthetic/assessment.rb:26` `sync`; `:38`
  `add_new`; `:49` `find_enrollment`.
- `drivers/cas_ce_data/app/models/cas_ce_data/synthetic/event.rb:35` `sync`; `:63`
  `find_enrollment`.
- `drivers/cas_access/README.md`, `drivers/cas_ce_data/README.md`.

## Gotchas

- Without `DATABASE_CAS_DB`, every `CasAccess::*` call returns nil, not an empty relation.
  `CasAccess::Tag.where(rrh_assessment_trigger: true)&.each` in `cas_tags` uses `&.` for this
  reason. A spec that exercises `cas_tags`, `cas_project_client`, or any CAS report runs
  against the stub unless the test environment sets `DATABASE_CAS_DB` and
  `CAS_DATABASE_DB_TEST` together; `config/database.yml` guards the `cas` entry on each.
- `CasBase` is chosen at class-load time from `ENV`. Stubbing `CasBase.db_exists?` in a spec
  does not make `CasAccess::ProjectClient` a real model.
- `sync!` sets `sync_with_cas: false` on every CAS `project_clients` row before re-pushing, so
  a client absent from `cas_active` becomes unavailable in CAS on the next run even if no
  warehouse row changed. The set of pushed columns is `CasAccess::ProjectClient.column_names - ['id']`,
  taken from the CAS schema; a column added in CAS but missing from `project_client_columns`
  is pushed as nil.
- `active_in_cas?` (payload `sync_with_cas`) and `cas_active` (who gets pushed) are parallel
  implementations of the same `case`. A new availability method must be added to both and to
  `GrdaWarehouse::Config.available_cas_methods`. `active_in_cas?` also excludes `deceased?` and
  `moved_in_with_ph?`, which the scope does not.
- `force_remove_unavailable_fors` is true when the method is not `cas_flag` and the client is
  manually flagged; `RunDailyImportsJob#sync_with_cas` documents a race where such a client,
  housed through CAS, can be made available again before the warehouse learns of the housing.
- `cohort_ids_for_cas` filters to `GrdaWarehouse::Cohort.visible_in_cas` so membership in a
  confidential cohort does not leak into CAS. Tags come from cohort `tag_id` plus any CAS tag
  with `rrh_assessment_trigger`.
- `attributes_for_display` reuses the sync column map but drops identifying columns and hides
  HIV, DMH, and VI-SPDAT columns per user permission and `pii_restricted?`.
- `sync_cas_attributes_with_files` only runs when `cas_flag_method` is `file`; it sets
  `ha_eligible` and `disability_verified_on` from tagged client files. When the method is not
  `file`, `CasReadinessController#update` sets `disability_verified_on` from the checkbox.
- The `cas_ce_data` synthetic sync only runs when `CasBase.db_exists?`, even though its source
  tables are on the warehouse connection.

## Do not repeat

- Writing through `CasBase` from anywhere other than `GrdaWarehouse::Tasks::PushClientsToCas`.
  CAS owns its schema and its own writes; the warehouse contributes one table. A report that
  needs to change CAS state should raise the requirement against `boston-cas`. The single
  existing writer: `app/models/grda_warehouse/tasks/push_clients_to_cas.rb:37`.
- Duplicating consent or release logic in the push task or a calculator. Release status is
  read once through `release_status_for_cas` (`app/models/concerns/cas_client_data.rb:577`),
  which defers to `consent_form_valid?` and `consent_confirmed?` on the client. Calculators
  override how a column is sourced, not what a release means.
- Adding a payload column by editing the `attr_accessor` list in `CasClientData` without also
  adding it to `project_client_columns` and to `ignored_for_batch_maintenance`; a column in
  `cas_columns_data` but not in `ignored_for_batch_maintenance` appears as a bulk-editable flag
  in `ManageCasFlagsController`. Existing pattern: `majority_sheltered` appears in all three.
- Gating CAS UI on `ENV['DATABASE_CAS_DB']` or a `CasAccess` query. Use
  `GrdaWarehouse::Config.cas_enabled?`; existing example
  `drivers/access_logs/app/models/access_logs/warehouse_reports/user_summary.rb:87`.
- Calling `GrdaWarehouse::Tasks::PushClientsToCas.new.sync!` inline from a controller. Enqueue
  `Cas::SyncToCasJob.perform_later` as `app/controllers/warehouse_reports/manage_cas_flags_controller.rb:85`
  does; the task holds an advisory lock and iterates every active client.
- Instantiating a calculator with a hard-coded class. Read
  `GrdaWarehouse::Config.get(:cas_calculator).constantize.new`, as
  `app/models/grda_warehouse/tasks/push_clients_to_cas.rb:461` and
  `app/models/concerns/cas_client_data.rb:357` do; the option list is
  `GrdaWarehouse::Config.available_cas_calculators`.

## Related

- `roi/roi-authorizations-and-visibility.md`: how `housing_release_status`, `release_duration`,
  and the consent dates that `release_status_for_cas` reads are produced and enforced.
- `roi/consent-records.md`: the client files and columns that record consent.
- `hmis/coordinated-entry.md`: the HMIS-native CE match engine and referrals, separate from
  CAS.
- `warehouse/cohorts.md`: `visible_in_cas` and cohort `tag_id`, the inputs to `cas_tags`.
- `warehouse/jobs-and-configuration.md`: `RunDailyImportsJob` ordering and
  `GrdaWarehouse::Config` keys (`cas_available_method`, `cas_calculator`, `cas_flag_method`,
  `cas_sync_months`, `cas_sync_project_group_id`, `cas_days_homeless_source`).
- `docs/features/warehouse/cas-sync-active-clients.md`: human doc for the `active_clients`
  method and project group selection.
- `docs/architecture/05-building-blocks/05-2-2-cas.md`: CAS component overview.

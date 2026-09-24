---
title: Data sources and non-CSV imports
summary: "GrdaWarehouse::DataSource is the root of provenance and visibility for every HUD record. Covers its flags (obey_consent, visible_in_window, authoritative, hmis, import_paused, disable_imports) and the code that reads each one, the ETO API and Eccovia API fetches, Boston custom S3 imports, manually entered project associations, HMIS supplemental data sets and their five visibility conditions, and data source deletion."
area: warehouse
tags: [data-source, DataSource, obey_consent, visible_in_window, authoritative, authoritative_type, hmis, hmis_go_live_at, import_paused, disable_imports, HmisEnforcement, EtoApiConfig, EtoApi, UpdateEtoData, EtoUpdateEverythingJob, custom-imports, CustomImports::Config, CustomImports::ImportFile, custom_imports_boston_service, eccovia_data, EccoviaData::Fetch, manual_hmis_data, manual_entry, hmis_supplemental, HmisSupplemental::DataSet, HmisSupplemental::ImportJob, can_view_supplemental_client_data, DeleteItemJob, PurgeForDeletedDataSources]
sources:
  - app/models/grda_warehouse/data_source.rb
  - app/models/hmis_enforcement.rb
  - app/controllers/data_sources_controller.rb
  - app/models/grda_warehouse/auth_policies/source_client_policy.rb
  - drivers/client_access_control/app/models/client_access_control/enrollment_arbiter.rb
  - app/jobs/delete_item_job.rb
  - app/models/grda_warehouse/tasks/service_history/purge_for_deleted_data_sources.rb
  - app/models/grda_warehouse/eto_api_config.rb
  - app/models/eto_api/tasks/update_eto_data.rb
  - app/jobs/importing/eto_update_everything_job.rb
  - lib/tasks/eto.rake
  - lib/tasks/grda_warehouse.rake
  - app/models/grda_warehouse/custom_imports/config.rb
  - app/models/grda_warehouse/custom_imports/import_file.rb
  - app/controllers/data_sources/custom_imports_controller.rb
  - drivers/custom_imports_boston_service/README.md
  - drivers/custom_imports_boston_service/app/models/custom_imports_boston_service/import_file.rb
  - drivers/eccovia_data/README.md
  - drivers/eccovia_data/app/models/eccovia_data/fetch.rb
  - drivers/manual_hmis_data/README.md
  - drivers/manual_hmis_data/app/models/manual_hmis_data.rb
  - drivers/manual_hmis_data/app/controllers/manual_hmis_data/funders_controller.rb
  - drivers/hmis_supplemental/README.md
  - drivers/hmis_supplemental/app/models/hmis_supplemental/data_set.rb
  - drivers/hmis_supplemental/app/jobs/hmis_supplemental/import_job.rb
  - drivers/hmis_supplemental/app/controllers/hmis_supplemental/client_data_sets_controller.rb
related:
  - hud-reporting/csv-import.md
  - roi/consent-from-external-sources.md
  - roi/roi-authorizations-and-visibility.md
  - warehouse/client-identity.md
  - authorization/warehouse-access-controls.md
  - hmis/restricted-records-and-multi-hmis.md
---

## Purpose

`GrdaWarehouse::DataSource` (`app/models/grda_warehouse/data_source.rb`) is one origin of
client and project data. Every `GrdaWarehouse::Hud::*` row carries `data_source_id`, and a HUD
id (`PersonalID`, `ProjectID`, `EnrollmentID`) identifies a row only together with it. One row
is the destination (`source_type` nil, `authoritative` false); every other row is a source: a
vendor HMIS fed by HUD CSV, an Open Path HMIS (the `hmis` hostname column is set), or an
authoritative source whose records are entered directly in the warehouse. Source clients link
to the destination client through `GrdaWarehouse::WarehouseClient`.

Boolean and string columns on the row decide two things. Visibility: `obey_consent`,
`visible_in_window`, `authoritative`, `hmis`, `hmis_go_live_at`. Import behavior:
`import_paused`, `disable_imports`, `source_id`, and the jsonb columns `import_cleanups`,
`import_aggregators`, `pre_process_hooks`.

This doc covers the model, each flag and the code that reads it, the ways data enters a data
source other than HUD CSV (ETO API, Eccovia API, Boston custom S3 imports, manually entered
project associations, HMIS supplemental data sets), and what happens when a data source is
deleted. The HUD CSV import pipeline is documented in `hud-reporting/csv-import.md` and is not
restated here. Consent arriving through ETO is in `roi/consent-from-external-sources.md`.

## Entry points

- Admin UI: `DataSourcesController` (`app/controllers/data_sources_controller.rb`). Every
  action loads through `GrdaWarehouse::DataSource.viewable_by(current_user)`;
  `data_source_params` and `new_data_source_params` list the editable columns, and `hmis` is
  dropped from the update params once set. `destroy` enqueues `DeleteItemJob`.
- HMIS gate: `HmisEnforcement.hmis_enabled?` (`app/models/hmis_enforcement.rb`) returns
  `ENV['ENABLE_HMIS_API'] == 'true'`. `HmisEnforcement.configured_hmis_hostnames` parses
  `HMIS_HOSTNAME`.
- ETO: rake `eto:import:demographics_and_touch_points[start_date]` (`lib/tasks/eto.rake`)
  enqueues `Importing::EtoUpdateEverythingJob` once per active `GrdaWarehouse::EtoApiConfig`,
  then calls `EccoviaData::Fetch.all.each(&:fetch_updated)`. `GrdaWarehouse::Hud::Client`
  `fetch_updated_source_hmis_clients` and `fetch_updated_source_hmis_forms` run the same
  `EtoApi::Tasks::UpdateEtoData` methods for one client on demand.
- Custom imports: rake `grda_warehouse:hourly` (`lib/tasks/grda_warehouse.rake`) delays
  `GrdaWarehouse::CustomImports::Config#import!` for every active config on the long-running
  queue. Configuration UI is `DataSources::CustomImportsController` at
  `/data_sources/:data_source_id/custom_imports`.
- Manual project associations: `ManualHmisData::FundersController`, `InventoriesController`,
  `ProjectCocsController` at `/manual_hmis_data/projects/:project_id/{funders,inventories,project_cocs}`.
- Supplemental data: `grda_warehouse:hourly` at hour 4 enqueues `HmisSupplemental::ImportJob`
  for every `HmisSupplemental::DataSet` with `sync_enabled`. Admin UI is
  `HmisSupplemental::DataSetsController` at `/data_sources/:data_source_id/hmis_supplemental/data_sets`,
  with `DataSetUploadsController` for a one-off CSV upload. The client dashboard tab is
  `HmisSupplemental::ClientDataSetsController#show`.
- Deletion: `DeleteItemJob` soft-deletes the row; the nightly `Importing::RunDailyImportsJob`
  runs `GrdaWarehouse::Tasks::ServiceHistory::PurgeForDeletedDataSources.call` before
  regenerating service history.

## How it works

### Scopes and identity

`destination` is `where(source_type: nil, authoritative: false)`; `warehouse_id` memoizes
`destination.first.id`. `source` is `source_type` not null or `authoritative` true.
`importable` is `source` with `disable_imports: false` and either `authoritative` false or
`hmis` not null, so an authoritative data source only accepts HUD CSV when it is an Open Path
HMIS. `importable_via_samba`, `_sftp`, `_s3` narrow by `source_type`. `hmis(user = nil)` is
`where.not(hmis: nil)`, optionally limited to `user.hmis_data_source_id`; `not_hmis` is the
complement. `authoritative`, `visible_in_window`, `obeys_consent`, `scannable` match the
column of the same name. `available_for_new_clients` is `authoritative.not_hmis`. Typed scopes
`youth`, `health`, `vispdat`, `coordinated_assessment` filter on `authoritative_type`; no
callers of those four scopes were found, and `health_authoritative_id` matches
`short_name == 'Health'` rather than the type.

Id lists `source_data_source_ids`, `destination_data_source_ids`,
`authoritative_data_source_ids`, `window_data_source_ids` are `Rails.cache` entries with a
one-hour expiry. `clear_ds_id_cache` runs `after_create` only; an update to
`visible_in_window` reaches `window_data_source_ids` when the cache expires.

Access scopes: `viewable_by(user, permission: :can_view_projects)` is inclusive, matching a
data source the user can see directly or through any of its organizations, projects, project
access groups, or CoC codes (ACL users; legacy users get a raw SQL `EXISTS` union over
`GroupViewableEntity`). `directly_viewable_by` checks the data source entity only.
`editable_by` needs `can_edit_data_sources`. `importable_by?(user)` requires `importable?`,
`can_upload_hud_zips?`, and `directly_viewable_by?` with that permission. `policy_class` is
`GrdaWarehouse::AuthPolicies::DataSourcePolicy`.

Creation: `after_create :maintain_system_group` schedules `AccessGroup` and `Collection`
system-group maintenance so the `:data_sources` system collections include the new row.
`has_paper_trail` ignores `last_imported_at` and `updated_at`. `acts_as_paranoid` makes
`destroy` a soft delete.

### Flags and their readers

Each flag is a `data_sources` column; every reader named for it was confirmed in code.

- `obey_consent` (default true). `GrdaWarehouse::AuthPolicies::SourceClientPolicy#roi_authorized?`
  returns false unless `client.data_source&.obey_consent?`, so an ROI never exposes a source
  client from a data source with the flag off. `ClientAccessControl::EnrollmentArbiter#potentially_viewable_data_source_ids`
  unions `DataSource.source.obeys_consent` with `viewable_by(user)`.
- `visible_in_window` (default false). `Collection.maintain_system_groups` copies
  `visible_in_window.pluck(:id)` into the `:window_data_sources` system collection.
  `EnrollmentArbiter#project_ids` adds every project in `window_data_source_ids` unless
  `GrdaWarehouse::Config.get(:window_access_requires_release)`. `GrdaWarehouse::Cohort` and a
  `GrdaWarehouse::Config` option also read the scope. `visible_in_window_for_cohorts_to` is a
  legacy scope marked for removal after the ACL migration.
- `authoritative` (default false). Excluded from `importable` unless `hmis` is set.
  `available_for_new_clients` drives warehouse client creation in `ClientsController#create`
  and `app/views/clients/_new_client.haml`. `GrdaWarehouse::AuthPolicies::UserAclContext#preload_collection_ids_by_client`
  gives clients in `authoritative.not_hmis` data sources collection-based direct permissions.
- `hmis` (hostname string). `hmis?` is `hmis.present?`. Validated unique among undeleted rows
  and, outside the test environment, included in `HmisEnforcement.configured_hmis_hostnames`.
  `hmis_hostname_immutable` rejects a change once set. `before_validation :enforce_op_hmis_defaults`
  forces `authoritative: true` and clears `authoritative_type`, `source_type`,
  `munged_personal_id`, `after_create_path`, `service_scannable`. `hmis_url_for` deep-links
  only when `hmis? && HmisEnforcement.hmis_enabled?`; `enabled_hmis_data_sources` returns `[]`
  unless enabled.
- `hmis_go_live_at`. `hmis_live?` is nil-or-past; `Hmis::User` reads it to block everyone but
  HMIS administrators before go-live.
- `import_paused` (default false). `Importers::HmisAutoMigrate::S3.available_connections`
  skips paused data sources; `stalled_dates_by_id` excludes them from stalled-import detection.
  Manual HUD CSV uploads are still allowed.
- `disable_imports` (default false). Removes the row from `importable`, so `importable?` and
  `importable_by?` return false and the upload UI hides.
- `source_id`, `import_cleanups`, `import_aggregators`, `pre_process_hooks`. Read only by the
  HUD CSV loader and importer (`pre_process_hooks` by `HmisCsvImporter::Loader::HudKeyRemapper`
  and `UnlinkedRecordFilter`); see `hud-reporting/csv-import.md`.
- `munged_personal_id`. `GrdaWarehouse::Hud::Client#uuid` inserts UUID dashes on display.
- `service_scannable`. `DataSource.scannable`, read by `drivers/service_scanning` when creating
  clients.
- `after_create_path`. `ClientsController#create` appends it to the redirect after creating a
  client in an authoritative source.

### ETO API

`GrdaWarehouse::EtoApiConfig` (`app/models/grda_warehouse/eto_api_config.rb`) is one row per
ETO-connected data source: `active`, encrypted `password`, and JSON columns
`demographic_fields`, `demographic_fields_with_attributes`, `additional_fields`,
`touchpoint_fields` that map ETO labels or CDIDs onto `GrdaWarehouse::HmisClient` and
`GrdaWarehouse::HmisForm` columns. `EtoApi::Base.api_configs` turns the active rows into the
connection map keyed by `identifier`.

`Importing::EtoUpdateEverythingJob#perform(start_date:, data_source_id:)` runs on the
long-running queue with `max_attempts` 1. It calls `GrdaWarehouse::Hmis::Assessment.update_touch_points`,
then `Bo::ClientIdLookup.new(data_source_id:, start_time:).update_all!`, which rebuilds the
QaaWS lookup tables `GrdaWarehouse::EtoQaaws::ClientLookup` and `TouchPointLookup`. It then
slices the distinct client ids from each lookup table into groups of 500 and enqueues
`Importing::EtoDemographicsJob` and `Importing::EtoTouchPointsJob`, and finally runs
`GrdaWarehouse::HmisForm.maintain_location_histories`.

Those jobs call `EtoApi::Tasks::UpdateEtoData#update_demographics!` and `#update_touch_points!`
(`app/models/eto_api/tasks/update_eto_data.rb`). Each iterates every active config, compares
the lookup row's `last_updated` to `eto_last_updated` on the existing `HmisClient` (keyed by
`client_id` and `subject_id`) or `HmisForm` (keyed by client, site, assessment, subject,
response) by date only, and fetches rows that are missing or older. `fetch_demographics`
stores the raw JSON in `response`, assigns mapped columns from the config, snapshots them into
`processed_fields`, and sets `eto_last_updated` from `AuditDate`. `fetch_touch_point` builds an
`answers` hash of sections and questions from the touch point structure, records staff and
`collected_at`, and sets `eto_last_updated` to the later of the QaaWS and API dates.

`UpdateEtoData#run!` is gated by `GrdaWarehouse::Config.get(:eto_api_available)`, but the jobs
call `update_demographics!` and `update_touch_points!` directly and skip that gate. The API
call in `fetch_demographics` is wrapped in `rescue StandardError` returning nil, and
`save_touch_point` rescues `Exception` on save and returns false; a Slack ping is sent only
when more than 10 rows are fetched.

### Custom imports (S3)

`GrdaWarehouse::CustomImports::Config` (`custom_imports_config`, paranoid) belongs to a data
source and a user and holds encrypted S3 credentials, `s3_region`, `s3_bucket`, `s3_prefix`,
an `import_type` class name, `import_hour`, and `active`. `available_import_types` reads
`Rails.application.config.custom_imports`, an array seeded empty in `config/application.rb`
that each `drivers/custom_imports_boston_*` feature initializer appends its `ImportFile` class
name to (service, contacts, community_of_origin, assessment_lookups). `Config#import!(force)`
instantiates `import_type.constantize.new(config_id:, data_source_id:, status: 'queued')`,
calls `import!(force)`, and stamps `last_import_attempted_at`. `Config#s3` falls back to
instance-role credentials when `s3_access_key_id` is blank or `'unknown'`.

`GrdaWarehouse::CustomImports::ImportFile` (`custom_imports_files`, paranoid) is the base for
every import type; the concrete class name is the row's type. `check_hour` returns true only
when `config.import_hour` is the current hour and no file for the config started in the last
23 hours, and always true in development and test. `fetch_and_load` takes the last key listed
under `s3_prefix` (`most_recent_on_s3` uses list order, not etag), downloads it, converts a
non-CSV workbook to CSV with RubyXL, stores the full text in `content`, and calls `load_csv`.
The base `load_csv` renames headers via `clean_headers`, drops `do_not_import` columns, appends
`import_file_id` and `data_source_id`, and bulk-inserts into `rows` in batches of 10,000.

`CustomImportsBostonService::ImportFile` overrides `load_csv` to translate vendor headers
(`Client ID` to `personal_id`, `Service ID` to `service_id`, ...) and upsert on `service_id`.
`post_process` reads the reporting period from the first row, deletes every
`GrdaWarehouse::Generic::Service` for the data source in that period, and re-creates one per
row whose `personal_id` matches a source client, storing the destination client id. The
driver also registers `CustomImportsBostonService::Synthetic::Event` in
`config.synthetic_event_types`. `DataSources::CustomImportsController` requires
`can_edit_data_sources` and `can_manage_config`, and `download` streams an S3 object by key.

### Eccovia and manual data

Eccovia. `EccoviaData::Fetch` (`eccovia_fetches`: `data_source_id`, `credentials_id`,
`active`, `last_fetched_at`) belongs to `EccoviaData::Credential`, an STI subclass of
`GrdaWarehouse::RemoteCredential` that keeps the subscription key in `username` and the API key
in the encrypted `password`, and runs CRQL queries paginated at 25. `Fetch#fetch_updated` calls
`EccoviaData::Assessment`, `ClientContact`, and `CaseManager` `.fetch_updated(data_source_id:,
credentials:)` then stamps `last_fetched_at`. Each model fetches rows updated since
`max_fetch_time` (default lookback three years), upserts on `[client_id, data_source_id,
<remote id>]`, and `remove_deleted` destroys local rows absent from the remote. Rows join
`GrdaWarehouse::Hud::Client` on `[PersonalID, data_source_id]`.
`EccoviaData::GrdaWarehouse::Hud::ClientExtension` adds `eccovia_*` and `source_eccovia_*`
associations, read by the client rollup partials under `app/views/clients/rollup/` and by
`GrdaWarehouse::Tasks::PushClientsToCas` when `EccoviaData::Fetch.exists?`. The only schedule
is the last line of `eto:import:demographics_and_touch_points`, which iterates
`EccoviaData::Fetch.all`, not `.active`. The driver has no controllers; its routes file is a
stub.

Manual. `drivers/manual_hmis_data` has no model of its own; `manual_hmis_data.rb` only sets a
`table_name_prefix`. Its three controllers create `GrdaWarehouse::Hud::Funder`, `Inventory`,
and `ProjectCoc` rows on an existing project with `manual_entry: true`, HUD id and `ExportID`
set to `"m-#{id}"`, and `UserID` set to the current user's email. Form fields come from the
model's `hmis_structure` minus id and audit keys, with `select_two` and `date_picker`
overrides. `new`, `create`, `edit`, `update`, `destroy` require `can_edit_projects`. The three
HUD models declare `replace_scope :importable, -> { where(manual_entry: false) }`, and the CSV
importer models build `involved_warehouse_scope` on `warehouse_class.importable`, so an import
neither overwrites nor soft-deletes manual rows.

### Supplemental data sets

`HmisSupplemental::DataSet` (`hmis_supplemental_data_sets`, paper trail) belongs to a data
source and to a `GrdaWarehouse::RemoteCredentials::S3`, and has `owner_type` (`client` or
`enrollment`), `name`, `object_key`, `sync_enabled`, and `field_config`, a JSON array
validated against `drivers/hmis_supplemental/schemas/data_set_fields.json` with unique keys.
`fields` returns `HmisSupplemental::Field` structs (`key`, `label`, `type` in string, id, int,
float, boolean, date, and `multi_valued`). `HmisSupplemental::FieldValue`
(`hmis_supplemental_field_values`) stores `owner_key` (`client/<PersonalID>` or
`enrollment/<EnrollmentID>`), `field_key`, and `data`; `for_owner(entity)` also requires the
data set's `data_source_id` to equal the entity's.

`HmisSupplemental::ImportJob#_perform(data_set_id:, csv_string: nil)` reads the S3 object at
`full_object_key` unless a CSV string is passed (the upload controller passes one), parses with
lower-cased trimmed headers, maps each row to `{owner_key, field_key, data}` per field,
`deduplicate_rows` (first value wins unless the field is `multi_valued`, which concatenates),
then inside a transaction `delete_all` on the data set's values and `import!` the new ones.
The whole run holds a `GrdaWarehouse` advisory lock named after the data set. Parse errors are
logged and sent to Sentry, not raised; a CSV that maps to no values returns before the delete.

Five conditions gate a data set on a destination client (`ClientDataSetsController`):

1. `DataSet.viewable_by(user)` returns none unless `user.using_acls?`.
2. The data set must be in a collection whose role has `can_view_supplemental_client_data`.
3. The data set's data source must be in `DataSource.viewable_by(user, permission:
   :can_view_supplemental_client_data)`, directly or through its organizations, projects,
   project access groups, or CoC codes.
4. Only source clients (or enrollments) whose `data_source_id` equals the data set's are
   listed, after `source_visible_to` / `visible_to`.
5. Each source client must pass `SourceClientPolicy#can_view_supplemental_data?`: ACL user,
   `can_view_supplemental_client_data` among `resource_permissions`, and `roi_authorized?`,
   which needs `obey_consent` on the data source and an active ROI on the destination client.

Admin controllers require `can_manage_config` and `can_edit_data_sources` and load the data
source through `viewable_by`.

### Deleting a data source

`DataSourcesController#destroy` enqueues `DeleteItemJob.perform_later(item_class:
'GrdaWarehouse::DataSource', item_id:)` (long-running queue, `max_attempts` 1, allow-list of
three classes). The job calls `destroy_dependents!`, which runs each organization's
`destroy_dependents!`, then `organizations.update_all(DateDeleted: Time.current, source_hash:
nil)` (no callbacks), then `remove_system_collections!` from `EntityAccess`. It then calls
`destroy!`, a paranoid soft delete that sets `deleted_at`.

Service history is not touched by the job. `GrdaWarehouse::Tasks::ServiceHistory::PurgeForDeletedDataSources.call(retain_at: 24.hours.ago)`
runs inside `Importing::RunDailyImportsJob`'s service history task, selects `with_deleted`
data sources whose `deleted_at` is at or before `retain_at`, and `delete_all`s their
`GrdaWarehouse::ServiceHistoryService` rows in batches of 1,000 enrollments, then their
`GrdaWarehouse::ServiceHistoryEnrollment` rows. Rows for a data source deleted today are purged
the following night.

## Key files

- `app/models/grda_warehouse/data_source.rb:62` `importable`, `:68` `source`, `:72`
  `destination`, `:88` `obeys_consent`, `:107` `viewable_by`, `:184` `hmis`, `:194`
  `enabled_hmis_data_sources`, `:204` `visible_in_window`, `:208` `available_for_new_clients`,
  `:760` `destroy_dependents!`, `:876` `hmis?`, `:883` `hmis_live?`, `:892` `importable_by?`,
  `:914` `hmis_url_for`, `:939` `enforce_op_hmis_defaults`, `:1059` `health_authoritative_id`.
- `app/models/hmis_enforcement.rb:10` `hmis_enabled?`, `:24` `configured_hmis_hostnames`.
- `app/controllers/data_sources_controller.rb:85` `destroy`, `:99` `data_source_params`.
- `app/models/grda_warehouse/auth_policies/source_client_policy.rb:38`
  `can_view_supplemental_data?`, `:77` `roi_authorized?`.
- `drivers/client_access_control/app/models/client_access_control/enrollment_arbiter.rb:303`
  `window_data_source_ids`, `:307` `potentially_viewable_data_source_ids`, `:312` `project_ids`.
- `app/jobs/delete_item_job.rb:18` `perform`.
- `app/models/grda_warehouse/tasks/service_history/purge_for_deleted_data_sources.rb:27`
  `call`, `:57` `find_deleted_data_sources`.
- `app/models/grda_warehouse/eto_api_config.rb`: the JSON mapping columns.
- `app/models/eto_api/tasks/update_eto_data.rb:37` `run!`, `:44` `update_demographics!`,
  `:133` `update_touch_points!`, `:243` `fetch_demographics`, `:328` `fetch_touch_point`.
- `app/jobs/importing/eto_update_everything_job.rb`: per-data-source fan-out.
- `lib/tasks/eto.rake:33` `demographics_and_touch_points`, `:45` Eccovia fetch.
- `lib/tasks/grda_warehouse.rake:313` `hourly`, `:330` custom imports, `:377` supplemental sync.
- `app/models/grda_warehouse/custom_imports/config.rb:28` `available_import_types`, `:42` `s3`,
  `:70` `import!`.
- `app/models/grda_warehouse/custom_imports/import_file.rb:21` `check_hour`, `:51`
  `fetch_and_load`, `:101` `most_recent_on_s3`, `:116` `load_csv`.
- `app/controllers/data_sources/custom_imports_controller.rb`: config CRUD and `download`.
- `drivers/custom_imports_boston_service/app/models/custom_imports_boston_service/import_file.rb:25`
  `import!`, `:35` `load_csv`, `:86` `post_process`.
- `drivers/eccovia_data/app/models/eccovia_data/fetch.rb:14` `fetch_updated`.
- `drivers/manual_hmis_data/app/models/manual_hmis_data.rb`: `table_name_prefix` only.
- `drivers/manual_hmis_data/app/controllers/manual_hmis_data/funders_controller.rb:23` `create`.
- `drivers/hmis_supplemental/app/models/hmis_supplemental/data_set.rb:32` `viewable_by`, `:58`
  `field_config_validation`, `:75` `fields`.
- `drivers/hmis_supplemental/app/jobs/hmis_supplemental/import_job.rb:20` `_perform`, `:74`
  `deduplicate_rows`, `:117` `with_lock`.
- `drivers/hmis_supplemental/app/controllers/hmis_supplemental/client_data_sets_controller.rb:28`
  `authorized_groups`, `:49` `source_clients`, `:60` `source_enrollments`.
- READMEs: `drivers/custom_imports_boston_service/README.md`, `drivers/eccovia_data/README.md`,
  `drivers/manual_hmis_data/README.md`, `drivers/hmis_supplemental/README.md` (each a few lines).

## Gotchas

- A data source is the unit of identity scoping. `PersonalID`, `ProjectID`, and every other
  HUD id repeat across data sources; always pair them with `data_source_id`. Client identity
  across sources is `warehouse/client-identity.md`.
- `obey_consent` off disables every ROI-based path for that source's clients, including
  supplemental data sets, even when the destination client has a valid ROI.
- The cached id lists (`window_data_source_ids` and friends) expire hourly and are cleared only
  on create. Toggling `visible_in_window` also waits for `Collection.maintain_system_groups`
  before the `:window_data_sources` system collection changes.
- `hmis` cannot be changed after save, and `enforce_op_hmis_defaults` silently rewrites six
  other columns on every validation of an HMIS data source. The hostname inclusion validation
  is skipped in the test environment.
- `HmisEnforcement.hmis_enabled?` is an environment variable, not a data source property. A
  deployment can hold data sources with `hmis` set while HMIS is off; `enabled_hmis_data_sources`
  is then empty.
- `UpdateEtoData#run!` checks `eto_api_available`, but the scheduled jobs bypass `run!`.
  Disabling ETO means deactivating the `EtoApiConfig` rows or unscheduling the rake task.
- Eccovia fetches run only from the ETO rake task and iterate `EccoviaData::Fetch.all`; the
  `active` column is not consulted.
- Custom import `check_hour` is always true in development and test, and `most_recent_on_s3`
  re-imports the same newest key every day. Boston service `post_process` is delete-then-insert
  for the file's reporting period, so a partial file removes services it does not contain.
- Supplemental import is a full replace per data set inside one transaction; the S3 object
  must contain every row, not a delta.
- Deleting a data source is asynchronous and soft. Organizations are marked with
  `update_all(DateDeleted:)` (no callbacks or paper trail), and service history is purged the
  following night by `PurgeForDeletedDataSources`. `with_deleted` queries still see the row.
- `health_authoritative_id` matches `short_name == 'Health'`, not `authoritative_type: 'health'`.

## Do not repeat

- Gating HMIS behavior on `GrdaWarehouse::DataSource.hmis.exists?` or `hmis?` alone. Replace
  with `HmisEnforcement.hmis_enabled?`, combined with `hmis?` when the check is per data source
  (existing examples: `DataSource.enabled_hmis_data_sources`, `DataSource#hmis_url_for`). The
  hostname can be set on a deployment where the HMIS API is off.
- Querying a `GrdaWarehouse::Hud::*` table by HUD id without `data_source_id`. Replace with a
  composite condition or the model's composite-key association (existing example:
  `EccoviaData::Assessment` `belongs_to :client, foreign_key: [:client_id, :data_source_id],
  primary_key: [:PersonalID, :data_source_id]`).
- A new S3 import type that bypasses `GrdaWarehouse::CustomImports::ImportFile` and
  `Rails.application.config.custom_imports`. Replace with a `drivers/custom_imports_<name>`
  driver whose feature initializer appends its `ImportFile` subclass (existing example:
  `drivers/custom_imports_boston_service/config/initializers/custom_imports_boston_service_feature.rb`).
- Deleting a data source with `destroy` from a console or controller. Replace with
  `DeleteItemJob.perform_later(item_class: 'GrdaWarehouse::DataSource', item_id:)` so
  `destroy_dependents!` runs and the nightly purge finds the row.
- Writing consent dates onto `GrdaWarehouse::Hud::Client` from an importer. The ETO path stores
  them on `GrdaWarehouse::HmisClient` and reconciles; see `roi/consent-from-external-sources.md`.
- New readers of the legacy window path (`visible_in_window_for_cohorts_to`, `AccessGroup`
  based `has_access_to_data_source_through_*`). Those blocks are marked `START_ACL` for
  removal; new code uses `viewable_by` with an explicit `permission:`.
- Manually created `Funder`, `Inventory`, or `ProjectCoc` rows without `manual_entry: true`.
  The importer's `importable` scope would treat them as import-owned and soft-delete them on
  the next HUD CSV import.

## Related

- `hud-reporting/csv-import.md`: the HUD CSV loader and importer, `import_cleanups`,
  `import_aggregators`, `pre_process_hooks`, thresholds, and the `import_paused` S3 pull.
- `roi/consent-from-external-sources.md`: how ETO consent fields on `HmisClient` reach the
  destination client.
- `roi/roi-authorizations-and-visibility.md`: what `roi_authorized?` grants once `obey_consent`
  allows it.
- `warehouse/client-identity.md`: source and destination clients, `WarehouseClient`, merges.
- `authorization/warehouse-access-controls.md`: collections, `GroupViewableEntity`, and the
  system collections `maintain_system_groups` fills.
- `hmis/restricted-records-and-multi-hmis.md`: hostname routing for Open Path HMIS data sources
  and `hmis_go_live_at`.
- Human-facing sources: `docs/features/warehouse/data-sources.md`,
  `docs/features/warehouse/hmis-supplemental.md`.

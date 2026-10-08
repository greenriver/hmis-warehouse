---
title: PII handling, restricted clients, access logging, and retention
summary: "How the warehouse catalogs and protects client PII. pii_attr declarations via HasPiiAttributes, PiiProvider display decisions, HMIS-restricted client redaction and search exclusion on the warehouse side, ActivityLog records of who viewed which client and the AccessLogs audit report, PII scrubbing for non-production copies, and client data retention, whose nightly job marks inactive clients that are then hidden like restricted ones."
area: warehouse
tags: [pii, HasPiiAttributes, pii_attr, PII_TYPES, PiiProvider, RestrictedPolicy, PiiDisplay, restricted-client, redaction, RestrictedClientLoader, HiddenClients, not_hidden, restricted_subset, hidden_ids_in, text_search, strict_search, name_and_ssn_filter, ClientRetentionMark, ClientRetentionJob, access_logs, ActivityLog, ActivityLogger, AccessLogs::Report, UsageSummary, UserSummary, ScrubClientPiiTask, ScrubAllPiiTask, ScrubModelPii, retention, ADR-0002, ADR-0009]
sources:
  - docs/adr/0002-pii-management-strategy.md
  - docs/adr/0009-client-data-retention-and-removal.md
  - app/models/concerns/has_pii_attributes.rb
  - app/models/concerns/pii_display.rb
  - app/models/grda_warehouse/pii_provider.rb
  - app/models/grda_warehouse/auth_policies/context_loaders/restricted_client_loader.rb
  - app/models/grda_warehouse/hidden_clients.rb
  - app/models/grda_warehouse/client_retention_mark.rb
  - app/jobs/client_retention_job.rb
  - app/models/grda_warehouse/hud/client.rb
  - app/models/concerns/client_search.rb
  - app/models/hud_reports/report_client_base.rb
  - app/controllers/clients_controller.rb
  - app/controllers/concerns/client_controller.rb
  - drivers/client_access_control/app/controllers/client_access_control/clients_controller.rb
  - app/models/grda_warehouse/client_search_query.rb
  - drivers/client_access_control/README.md
  - drivers/access_logs/README.md
  - app/controllers/concerns/activity_logger.rb
  - app/models/activity_log.rb
  - drivers/hmis/app/models/hmis/activity_log.rb
  - drivers/access_logs/app/models/access_logs/report.rb
  - drivers/access_logs/app/models/access_logs/warehouse_reports/usage_summary.rb
  - drivers/access_logs/app/models/access_logs/warehouse_reports/user_summary.rb
  - app/models/grda_warehouse/tasks/scrub_pii/scrub_client_pii_task.rb
  - app/models/grda_warehouse/tasks/scrub_pii/scrub_all_pii_task.rb
  - app/models/pii/scrubber/scrub_model_pii.rb
  - app/models/pii/scrubber/pii_attribute.rb
  - app/models/pii/scrubber/version_history_pruner.rb
  - app/models/pii/scrubber/replacement_pii.rb
  - app/models/pii/scrubber/static_scrubber.rb
related:
  - authorization/warehouse-policies.md
  - hmis/restricted-records-and-multi-hmis.md
  - hud-reporting/csv-export.md
  - warehouse/client-identity.md
---

## Purpose

Client PII in the warehouse (name, SSN, DOB, photo, HIV status, and contact data) is handled by
four mechanisms that share one catalog:

- **Cataloging.** `HasPiiAttributes` (`app/models/concerns/has_pii_attributes.rb`) gives any
  model a `pii_attr` class macro that records which columns hold PII, of what type, and at what
  sensitivity level. Many models declare PII this way, from `GrdaWarehouse::Hud::Client`
  to per-report snapshot tables. This is Phase 1 of `docs/adr/0002-pii-management-strategy.md`.
- **Display.** `GrdaWarehouse::PiiProvider` decides per field whether a value is shown, masked,
  or replaced with `Redacted`, given a policy object. HMIS client restriction is folded in by
  `PiiProvider.restrict`, which forces every PII predicate false. The policy classes and the
  `PiiProvider` API are documented in `authorization/warehouse-policies.md`; this doc covers the
  restriction sources, search exclusion, and the surfaces that do and do not honor them.
- **Access logging.** `ActivityLogger` writes one `ActivityLog` row per warehouse request, with
  the viewed client when a controller calls `log_client`. The `access_logs` driver reports on
  those rows (exports, report usage, user access summary) alongside `Hmis::ActivityLog` and the
  CAS log.
- **Scrubbing.** `GrdaWarehouse::Tasks::ScrubPii::ScrubClientPiiTask` and `ScrubAllPiiTask`
  overwrite cataloged PII and delete related free-text records, for producing a non-production
  copy or honoring a one-off removal request. They are console tasks with no UI or scheduler.

**Retention** (hiding clients inactive for N years) follows
`docs/adr/0009-client-data-retention-and-removal.md`. Phase 1 is built: `ClientRetentionJob`
writes `GrdaWarehouse::ClientRetentionMark` rows, and a marked (inactive) client is hidden
exactly like an HMIS-restricted one. `GrdaWarehouse::HiddenClients` is the single definition of
both hidden sets. Nothing is overwritten or deleted.

## Entry points

Cataloging:

- `pii_attr :column, as: nil, level: nil, required: false` class macro after
  `include HasPiiAttributes`. `Model.stores_pii?` and `Model.pii_attributes_config` read the
  result. `GrdaWarehouse::Hud::Client` declares `SSN`, `FirstName`, `MiddleName`, `LastName`,
  `DOB` in `app/models/concerns/hmis_structure/client.rb`.

Display:

- `client.pii_provider(user:)` (dashboard), `client.project_pii_provider(project:, user:, mode:)`
  (report rows), `GrdaWarehouse::PiiProvider.restrict(policy, restricted:)`,
  `PiiProvider.viewable_name/viewable_ssn/viewable_dob/viewable_hiv_status(value, policy:)`,
  `PiiProvider.from_attributes(policy:, ...)`. Detail in `authorization/warehouse-policies.md`.
- `PiiDisplay#pii_value(col:, raw_value:, pii_policy:)` (`app/models/concerns/pii_display.rb`):
  picks the `viewable_*` helper from the column name. Included by `WarehouseReport::Outcomes`,
  `HomelessSummaryReport::Client`, `MaYyaReport::Client`, and `CoreDemographicsReport::Details`.

Restriction:

- `user.policy_context.client_restricted?(client_id)`.
- `user.policy_context.preload_client_restrictions(ids)` or `preload_client_dependencies(ids)`
  before checking a list of clients; see `authorization/warehouse-policies.md`.
- `client.pii_restricted?(user:)`.
- `GrdaWarehouse::HiddenClients.not_hidden(column)` (Arel predicate for queries),
  `.restricted_subset(ids, identity_links:)`, `.identity_links(ids)`, `.inactive_subset(ids)`, `.hidden_ids_in(scope)`.
- `GrdaWarehouse::Hud::Client.text_search(text, client_scope:, user:)`,
  `.strict_search(criteria, client_scope:)`, `client.potential_matches`;
  `ClientSearch.text_searcher(text, sorted:, name_and_ssn_filter:)`;
  `HudReports::ReportClientBase.restricted_condition`.

Retention:

- `ClientRetentionJob` (nightly), `GrdaWarehouse::ClientRetentionMark.rollup_activity`,
  `GrdaWarehouse::ClientRetentionDryRun.new(global_years:).run` (console rehearsal),
  `WarehouseReports::ClientRetentionController` (`index`, `expired`, `runs`).

Access logging:

- `ApplicationController` includes `ActivityLogger` and runs `before_action :compose_activity`
  and `after_action :log_activity` for every action except `poll`, `active`, `rollup`, `image`.
  Controllers call `log_item(record)` or `log_client` to attach the record.
- `ActivityLog.export_rows(user_id:, range:, limit:)`, `.warehouse_reports`,
  `.created_in_range(range:)`, `.warehouse_report_conditions`.
- `AccessLogs::WarehouseReports::ReportsController` (`index`, `create`, `report_usage`,
  `user_summary`), `AccessLogs::Report#as_excel`, `AccessLogs::WarehouseReports::UsageSummary.new(range:).call`,
  `UserSummary.new(range:).call`, `WarehouseReports::AccessLogsExportJob`.

Scrubbing (console only; no rake task, job, or UI calls these):

- `GrdaWarehouse::Tasks::ScrubPii::ScrubClientPiiTask.perform(client_ids: nil, data_source_ids: nil, custom_scrubber: nil, progress: false)`.
- `GrdaWarehouse::Tasks::ScrubPii::ScrubAllPiiTask.perform(custom_scrubber: nil, progress: false)`.
- `Pii::Scrubber::ScrubModelPii.new(custom_scrubber:, progress:).perform(scope)` for one model.

## How it works

### Cataloging PII

`HasPiiAttributes` stores a `class_attribute :pii_attributes_config` hash keyed by column name.
`pii_attr(attribute, as:, level:, required:)` infers the PII type from
`attribute.to_s.underscore` when `as:` is absent (`:FirstName` becomes `:first_name`, `:SSN`
becomes `:ssn`), raises `ArgumentError` for a type not in `PII_TYPES`, and defaults `level` from
the type. `required: true` marks a column that cannot be nulled, which changes scrub behavior.

`PII_TYPES` defines four sensitivity levels:

- Level 1, direct identifiers: `first_name`, `last_name`, `middle_name`, `full_name`, `ssn`.
- Level 2, strong quasi-identifiers: `dob`, `email`, `phone`, `geo_street`, `geo_postal_code`.
- Level 3, demographic quasi-identifiers: `age`, `geo_locality`, `geo_admin_1`, `geo_admin_2`.
- Level 4, contextual: `free_text`, `url`, `attached_file`, `json`.

`stores_pii?` is true when any attribute is declared. `inherited` deep-copies the parent's
config into each subclass at definition time, so a `pii_attr` added to a parent after a
subclass is defined is not seen by that subclass. HUD models pick up their declarations through
the shared `HmisStructure::*` concerns, so `GrdaWarehouse::Hud::Client` and `Hmis::Hud::Client`
carry the same catalog. Report snapshot tables (`HudApr::Fy2020::AprClient`,
`HudSpmReport::Fy2026::SpmEnrollment`, `HmisDataQualityTool::Client`, and others) declare their
denormalized name, SSN, and DOB columns too, which is what lets `ScrubAllPiiTask` cover them.

Today the catalog has two consumers: `Pii::Scrubber::PiiAttribute.from_record(record)`, which
turns the config into scrubbable field objects, and `ScrubModelPii#perform`, which refuses a
model that does not `stores_pii?`. Display decisions do not read the catalog; `PiiProvider` and
`PiiDisplay` work from method names and column labels. A column declared with `pii_attr` is
therefore protected in scrubs but not automatically redacted on screen.

### Display decisions

`GrdaWarehouse::PiiProvider` wraps a client (or a `PiiProviderRecordAdapter` built by
`from_attributes`) and a duck-typed policy. Name accessors return `Name Redacted` when
`can_view_name?` is false; `dob` returns `nil` when `can_view_full_dob?` is false; `ssn` returns
`nil` for a blank value, `Redacted` when neither partial nor full SSN is allowed, a
`XXX-XX-1234` mask when only partial is allowed, and the full formatted value otherwise; `image`
returns an empty string when `can_view_photo?` is false. The class-level `viewable_*` helpers
apply the same rules to a bare value and return `Redacted` (or a caller-supplied replacement)
when denied. Which policy to resolve, and how, is in `authorization/warehouse-policies.md`.

`PiiProvider::RestrictedPolicy` wraps any policy and answers false to every PII predicate while
`can_view?` still delegates. `PiiProvider.restrict(policy, restricted:)` returns the policy
unchanged when `restricted` is false and the wrapper otherwise. `Client#pii_provider(user:)`
calls it with `pii_restricted?(user:)`, which is `user.policy_context.client_restricted?(id)`.
`User#reporting_policy_for_project` does the same for report rows. Cohorts wrap
`CohortPiiPolicy` or `AllowPiiPolicy` per row in `GrdaWarehouse::CohortClient`,
`Cohorts::ClientsController`, and `CohortColumns::Base#client_restricted?`.

`PiiDisplay#pii_value(col:, raw_value:, pii_policy:)` is for report classes whose rows are
header-to-value hashes. It downcases the column label and dispatches by regex: labels ending in
`name` go to `viewable_name`, exactly `dob` to `viewable_dob`, exactly `ssn` to `viewable_ssn`,
labels containing `hiv_aids` to `viewable_hiv_status`, anything else passes through. Arrays and
hashes recurse, using the hash key as the column label. The `name` match is broad: a column
labeled `project_name` or `Organization Name` is treated as client PII and redacted.

Fragment caches that hold rendered PII include
`current_user.policy_context.client_restricted?(client.id)` in their key (the client dashboard
rollups under `app/views/clients/rollup/` and `app/views/cohorts/_client_row_editable.haml`).
The answer covers both HMIS restriction and retention marks, so restricting, unrestricting,
marking, or unmarking a client busts only that client's fragments.

### Restricted clients on the warehouse side

Restriction is set in HMIS (`Hmis::RestrictedRecord`, see
`hmis/restricted-records-and-multi-hmis.md`). The warehouse treats it as an absolute PII block
with no override permission: the only way to restore visibility is for HMIS staff to unmark the
client. A retention-inactive client gets the same treatment until a later run unmarks it.

**Hidden sets.** `GrdaWarehouse::HiddenClients` defines both in Arel. The restricted set is the
directly restricted ids, the destinations linked to them through live `WarehouseClient` rows
(`deleted_at: nil`), and every sibling source of those destinations; one hop only, so a row that
is both a source and a destination does not pull in its grandparent. The inactive set is the
marked source ids plus their live destinations. `not_hidden(column)` is six correlated
`NOT EXISTS` clauses, each probing an index per candidate row, and keeps `NULL` columns;
`hidden_ids_in(scope)` returns the hidden ids inside a `Client` relation in one query.

**Loading.** `GrdaWarehouse::AuthPolicies::ContextLoaders::RestrictedClientLoader` keeps one memoized
`{client_id => hidden?}` table covering restriction and retention marks. Neither set is loaded
whole: `preload(ids, identity_links: nil)` resolves a page of ids in a fixed number of queries through
`HiddenClients.restricted_subset` and `HiddenClients.inactive_subset`, and `restricted?(id)` answers
from the table (a miss records `:client_restrictions` on the `PreloadMissTracker` and preloads that
id). `nil` is never restricted. The loader is memoized on
`UserBaseContext`, which is memoized on `User#policy_context`, so a request or job holds a
snapshot.

**Redaction.** Every path that resolves a `PiiProvider` through `pii_provider`,
`project_pii_provider`, `reporting_policy_for_project`, or an explicit `PiiProvider.restrict`
redacts name, SSN (no partial mask), DOB, photo, and HIV status. `age` and `dob_and_age` (year
only) still render. Paths that do not resolve a policy show real PII; the human doc
`docs/features/warehouse/warehouse-auth-policies.md` lists the known ones (CSG Engage
submission, ad hoc upload review, aggregate HIV gates, `non_hmis_clients`).

### Hidden clients in search and exports

Hidden means HMIS-restricted or retention-inactive, as defined by `GrdaWarehouse::HiddenClients`.

**Search.** A hidden client is excluded from search by name or SSN, not from search by DOB,
warehouse id, or `PersonalID`. `ClientSearch.text_searcher` takes `name_and_ssn_filter:` (an
Arel predicate) and applies it to the SSN-exact and free-text name branches only.
`Client.text_search` always passes `HiddenClients.not_hidden(arel_table[:id])`, and
`potential_matches` goes through it. `Client.strict_search` (3-of-4 match on name, DOB, SSN)
adds `not_hidden` to its result. `ClientController#look_for_existing_match` (new-client
duplicate check) adds `not_hidden` to its name and SSN clauses directly.
`HudReports::ReportClientBase.restricted_condition` applies `not_hidden` to each report
drilldown client id column. `Hmis::Hud::Client` never passes the keyword; its exclusion is
`searchable_to`.

`Client.text_search(user:)` limits results to `Client.searchable_to(user)`, checked against the
matched source ids (`searchable_to(user, client_ids:)`) rather than the user's whole searchable
set. Above `MAX_SEARCH_CANDIDATES` matches it falls back to a `searchable_to(user)` subquery. An
empty match list skips the call, because `searchable_to` treats empty `client_ids` as unrestricted.
`ClientAccessControl::ClientsController#perform_text_search` passes `user: current_user`.

**Exports.** `Export::RestrictedClientPiiTransform` redacts `Client.csv` in HMIS CSV exports
for restricted and inactive destination clients unless the export is hashed or faked; see
`hud-reporting/csv-export.md`. The Superset view `analytics.client_piis`
(`db/views/analytics_client_piis_v03.sql`) repeats both `HiddenClients` sets in SQL and must
stay in step with it; it redacts name and SSN, not DOB.

### Access logging

`ActivityLogger` (`app/controllers/concerns/activity_logger.rb`) is included in
`ApplicationController`. `compose_activity` builds an unsaved `ActivityLog` with `user_id`
(`true_user`, so impersonation logs the real user), controller and action, `item_id` from
`params[:id]`, `ip_address`, `referrer`, `session_hash`, HTTP method, and `path`
(`request.fullpath`, including the query string). `log_item(record)` sets `item_model` and
`item_id`. `log_activity` sets `title` by calling `title_for_<action>` (the default
`title_for_show` returns `@client.pii_provider(user: current_user).full_name` or `@user.name`)
and saves when `user_id` is present. `ClientsController` and
`ClientAccessControl::ClientsController` add `after_action :log_client`, the former for `show`,
`edit`, `merge`, `unmerge`, the latter for `show`. Dashboard `rollup` and `image` requests are
excluded from logging entirely.

`ActivityLog` (`app/models/activity_log.rb`) keeps `reporting_path`, a 200-character mirror of
`path` set in `before_save`, because `path` is unbounded and cannot be indexed.
`warehouse_report_conditions` maps every `ReportDefinition.report_list` url to an Arel condition
on `reporting_path` (exact, `/url/%`, or `/url?%`, or a per-report `reporting_query` override).
`created_in_range(range:)` expands a `Date..Date` to full days because `created_at` is a UTC
instant. `export_rows` streams `[user_id, agency, path, created_at, session, ip, referrer]` in
batches, stripping query strings and rewriting `/reports/<id>/` to the report name.

`Hmis::ActivityLog` (`drivers/hmis/app/models/hmis/activity_log.rb`) is the HMIS counterpart,
inserted by `Hmis::GraphqlController` and `Hmis::ClientFilesController` with `operation_name`,
`variables`, and `resolved_fields` keyed `Client/<id>`; `Hmis::ActivityLogProcessorJob` later
fills `hmis_activity_logs_clients` and `hmis_activity_logs_enrollments`.

The `access_logs` driver is the "User Access Logs" report. `create` queues
`WarehouseReports::AccessLogsExportJob`, which writes an xlsx through `AccessLogs::Report` with
one sheet each for Warehouse, CAS, and (when `HmisEnforcement.hmis_enabled?`) HMIS, capped at
`EXPORT_ROW_LIMIT` rows per sheet. `report_usage` and `user_summary` render in the background
and read `UsageSummary` (visit-days per report per user, one grouped query over
`ActivityLog.warehouse_reports`) and `UserSummary` (first and last access per user per system,
plus users created in range). Both cache for 15 minutes.

### Scrubbing

`Pii::Scrubber::ScrubModelPii#perform(scope)` raises unless `scope.klass.stores_pii?`, then
walks the scope in batches. For each record it builds `PiiAttribute` objects from the catalog
and runs three passes: the optional custom scrubber (`:fake` uses Faker for name and SSN types;
`:static` is meant to write `FirstName<id>`-style constants), `DobScrubber` (moves a `dob` into
a random date within the same five-year age bracket and recomputes any `age` field), then
`BasicScrubber` for every remaining field with `sensitive?` (level 1 or 2), which writes `nil`,
or a static placeholder when the field is `required: true`. Scrubbed values plus all non-null
columns are written back with `import` on conflict by `id`, with optimistic locking disabled.
Level 3 and 4 fields (`age` without a `dob`, `free_text`, `attached_file`, `json`,
`geo_locality`) are cataloged but not overwritten.

`ScrubClientPiiTask.perform(client_ids:, data_source_ids:, custom_scrubber:, progress:)`
takes a `GrdaWarehouse::Hud::Client.with_deleted` scope, scrubs the client rows, then per batch:
deletes `Hmis::Hud::CustomDataElement` rows whose definition label looks like PII (SSN, DOB,
name, address, email, phone, license or policy number) on the client, its enrollments, and a
fixed list of HMIS record types; prunes paper_trail versions; deletes `Hmis::File` rows for the
client; and deletes `CustomClientAddress`, `CustomClientName`, `CustomClientContactPoint`, and
`CustomCaseNote` rows by `PersonalID` and `data_source_id`. Deletion is `delete_all`, not soft
delete. `VersionHistoryPruner` resolves the `GrdaWarehouse`/`Hmis` alias pair sharing a table so
both `item_type` values are removed.

`ScrubAllPiiTask.perform(...)` runs `ScrubModelPii` over an explicit list of models (HUD
client and user, HMIS custom tables, report snapshot client tables, reporting-db tables, and the
2020, 2022, and 2024 CSV loader and importer client and user tables) and prunes their versions.
The list is hand-maintained and is not derived from the catalog. It is the tool for turning a production copy into a staging database. Both
tasks take a `GrdaWarehouseBase.with_advisory_lock` named after the class with a zero timeout,
so a second concurrent run fails immediately.

Neither task is scheduled or exposed in the UI; the only callers are their specs. Scrubbing
acts on the live database only; backups and S3 copies are untouched.

### Retention

Settings: `GrdaWarehouse::Config` `client_retention_years` is the global window (`nil`, the
default, turns the feature off); `GrdaWarehouse::DataSource#client_retention_years` overrides it
per data source. The human doc `docs/features/warehouse/client-data-retention.md` covers the
settings UI and the activity rules in detail.

`ClientRetentionJob` is enqueued by `Importing::RunDailyImportsJob` and does nothing when the
global window is `nil`. Under a zero-timeout advisory lock it creates a
`GrdaWarehouse::ClientRetentionRun`, walks every destination client in batches of `BATCH_SIZE`,
and calls `ClientRetentionMark.rollup_activity`, which computes per destination the newest
activity date across live sources and the longest applicable window among their data sources.
Soft-deleted rows are skipped, and each date after today is dropped on its own, so one
future-dated field never hides the other dates on the same row.
An identity is inactive when that date is older than today minus the window.

Marks are one `ClientRetentionMark` row per source client, written all-or-none per identity
(`insert_all` unique on `client_id`); sources of evaluated identities that are not inactive lose
their mark. The unmark set comes from the identity's live `warehouse_clients` links, not the
rollup, so it includes soft-deleted sources: the rollup skips them, but their marks would still
hide the identity. Each newly marked or cleared identity gets a `ClientRetentionLogEntry` holding only
identifiers (destination id, source client id, data source, `PersonalID`), never PII. Active
identities expiring within `EXPIRING_WITHIN_DAYS` go to `ClientRetentionExpiringClient`, read by
the Records Expiring Soon report. A failed run records `failed_at`; marks from completed batches
stand.

A mark changes nothing in the client rows. Hiding comes from `GrdaWarehouse::HiddenClients`
feeding `RestrictedClientLoader`, search, report drilldowns, the CSV export transform, and
`analytics.client_piis`. Scrub and Delete, propagation to CAS, and a privileged override are
not built; the ADR (still status Proposed) lists them as later phases or open decisions.

## Key files

- `app/models/concerns/has_pii_attributes.rb`: `PII_TYPES`; `pii_attr`;
  `stores_pii?`; `inherited` deep copy.
- `app/models/concerns/pii_display.rb`: `pii_value` regex dispatch by column label.
- `app/models/grda_warehouse/pii_provider.rb`: `RestrictedPolicy`; `restrict`;
  `viewable_name` and siblings; `from_attributes`; `dob`; `ssn` masking.
- `app/models/grda_warehouse/auth_policies/context_loaders/restricted_client_loader.rb`:
  `restricted?`; `preload`; the `{client_id => hidden?}` table.
- `app/models/grda_warehouse/hidden_clients.rb`: `restricted_subset`; `identity_links`;
  `inactive_subset`; `hidden_ids_in`; `not_hidden`.
- `app/models/grda_warehouse/client_retention_mark.rb`: `rollup_activity`,
  `ROLLUP_ACTIVITY_SQL`.
- `app/jobs/client_retention_job.rb`: `BATCH_SIZE`, `EXPIRING_WITHIN_DAYS`, mark and unmark
  logic.
- `app/models/grda_warehouse/hud/client.rb`: `pii_provider`;
  `project_pii_provider`; `pii_restricted?`; deprecated `name`;
  `text_search`; `strict_search`; `potential_matches`.
- `app/models/concerns/client_search.rb`: `text_searcher`; `name_and_ssn_filter` on the SSN
  and name branches.
- `app/models/hud_reports/report_client_base.rb`: `restricted_condition`.
- `app/controllers/concerns/client_controller.rb`: `look_for_existing_match`.
- `app/controllers/clients_controller.rb`: `after_action :log_client`;
  `handle_unused_search` raises because search lives in the driver; `edit` preloads policy data
  for the client, its potential matches, and split history.
- `drivers/client_access_control/app/controllers/client_access_control/clients_controller.rb`:
  `after_action :log_client`; `index` redirects to a saved `ClientSearchQuery`;
  `perform_search` chooses strict or text search.
- `app/models/grda_warehouse/client_search_query.rb`: saved search parameters, UUID id,
  fingerprint upsert; `ALLOWED_CLIENT_PARAMS` is first name, last name, DOB, SSN.
- `drivers/client_access_control/README.md`: the four sources of client search and view access.
- `app/controllers/concerns/activity_logger.rb`: `compose_activity`; `log_item`;
  `log_activity`; `title_for_show`.
- `app/models/activity_log.rb`: `REPORTING_PATH_LENGTH`; `created_in_range`;
  `warehouse_report_conditions`; `export_rows`; `scrub`.
- `drivers/hmis/app/models/hmis/activity_log.rb`: header comment documents every column and
  the `resolved_fields` key format.
- `drivers/access_logs/README.md`: tab list and definitions.
- `drivers/access_logs/app/models/access_logs/report.rb`: `EXPORT_ROW_LIMIT`, `sheet_rows`,
  `as_excel`.
- `drivers/access_logs/app/models/access_logs/warehouse_reports/usage_summary.rb`: grouped
  visit-day query.
- `drivers/access_logs/app/models/access_logs/warehouse_reports/user_summary.rb`: first and
  last access per user, created users.
- `app/models/grda_warehouse/tasks/scrub_pii/scrub_client_pii_task.rb`: `perform`;
  `process_client_batch`; `delete_custom_data_elements_with_pii` label patterns.
- `app/models/grda_warehouse/tasks/scrub_pii/scrub_all_pii_task.rb`: `models` list.
- `app/models/pii/scrubber/scrub_model_pii.rb`: three-pass scrub and `import!` upsert.
- `app/models/pii/scrubber/pii_attribute.rb`: `sensitive?` is `level < 3`.
- `app/models/pii/scrubber/version_history_pruner.rb`: alias resolution across namespaces.
- `app/models/pii/scrubber/replacement_pii.rb`: `STATIC_TYPE_VALUES`, `fake_value`.
- `app/models/pii/scrubber/static_scrubber.rb`: `:static` scrubber; calls `ReplacementPii.static_value` without its required `id:` keyword, so it raises when used.
- `docs/adr/0002-pii-management-strategy.md`, `docs/adr/0009-client-data-retention-and-removal.md`.

## Gotchas

- `ClientsController#index` raises on purpose. Warehouse client search is
  `ClientAccessControl::ClientsController#index` and `#search`, which store the typed criteria
  (name, SSN, DOB) in `GrdaWarehouse::ClientSearchQuery` under a UUID and redirect to it. Those
  rows hold PII for two years until `GrdaWarehouse::Tasks::CleanupClientSearchQueriesTask`
  deletes them from the `grda_warehouse` rake namespace.
- `ActivityLog.path` is the full request path with query string, and `title` for a client page
  is the client's name as the logging user saw it. Activity logs are therefore not id-only;
  ADR 0009 lists them as a secondary PII store. `export_rows` strips query strings on the way
  out, but the table keeps them.
- `compose_activity` and `log_activity` skip `rollup` and `image`, so a client dashboard visit
  produces one row for `show`, not one per lazily loaded section.
- The Report Usage and User Access Summary tabs read the log tables with no join to `users` or
  access controls. Users whose grants were revoked or who were deleted still appear; that is the
  audit intent, not a bug.
- `PiiDisplay#pii_value` redacts any column whose lowercased label ends in `name`, including
  project and organization names, when the policy denies client names.
- `client_restricted?` on a list without a preload runs one inactive-status query per client,
  and past the miss threshold raises `PreloadMissError` in development and test. Call
  `preload_client_restrictions` or `preload_client_dependencies` on the page's ids first.
- The inactive set includes marked sources and their destinations but not unmarked sibling
  sources. The job marks every live source of an identity, so a sibling is unmarked only until
  the next run after a merge.
- `Pii::Scrubber::StaticScrubber#perform` calls `ReplacementPii.static_value(field)` without
  the required `id:` keyword, so `custom_scrubber: :static` raises `ArgumentError` on the first
  field. `:fake` and the default (no custom scrubber) work.
- `ScrubClientPiiTask` and `ScrubAllPiiTask` use `delete_all`, bypassing `acts_as_paranoid` and
  callbacks, and take a zero-timeout advisory lock, so a concurrent run raises immediately.
- `ScrubAllPiiTask#models` is a hand-typed list. Models that declare `pii_attr` but are missing
  from it include `HudSpmReport::Fy2026::SpmEnrollment`,
  `HmisDataQualityTool::CurrentLivingSituation`, the `hmis_external_apis` form submission and
  referral posting models, and every `HmisCsvTwentyTwentySix` loader and importer table. A
  new snapshot table with PII needs both a `pii_attr` declaration and a line in that list.
- `ClientRetentionLogEntry` and `ClientRetentionExpiringClient` must hold identifiers only
  (warehouse client id, data source, `PersonalID`) per ADR 0009. Do not add name, SSN, or DOB.

## Do not repeat

- `client.name`, `client.FirstName`, `client.SSN`, or `client.DOB` in a view, export, or report
  row without a `PiiProvider`. `GrdaWarehouse::Hud::Client#name`
  (`app/models/grda_warehouse/hud/client.rb`) is deprecated in a comment. Replacement:
  `client.pii_provider(user: current_user).brief_name` on a dashboard,
  `client.project_pii_provider(project:, user:, mode:)` on a report row, or
  `PiiProvider.viewable_name(value, policy:)` for a plucked value. Repo-wide entry:
  `authorization/warehouse-policies.md`, Do not repeat.
- A new column holding name, SSN, DOB, contact, or address data without a `pii_attr`
  declaration. `ScrubAllPiiTask` and `ScrubClientPiiTask` only see cataloged columns, and
  `ScrubModelPii` raises on a model with none. Example of the replacement:
  `app/models/concerns/hmis_structure/client.rb`.
- A new client search path that filters hidden clients with its own id list or
  `where.not(id: ...)`. Use `Client.text_search`, `ClientSearch.text_searcher(name_and_ssn_filter:)`,
  or `GrdaWarehouse::HiddenClients.not_hidden(column)`, as `ClientController#look_for_existing_match`
  does. Hiding covers name and SSN matches only; do not extend it to DOB or id lookups.
- A fragment cache keyed on the client and user but not on
  `current_user.policy_context.client_restricted?(client.id)` when the fragment renders PII.
  Example of the replacement: `app/views/clients/rollup/_demographics.html.haml`.
- Building a hidden-client id list in Ruby and passing it to `where.not(id:)` or `not_in`.
  Replacement: `GrdaWarehouse::HiddenClients.not_hidden(column)` in the query, or
  `user.policy_context.client_restricted?` after a preload.
- Deleting or nulling client rows to implement retention. Phase 1 hides through
  `ClientRetentionMark` rows; extend `ClientRetentionJob` and `HiddenClients` rather than
  `ScrubClientPiiTask`, which is a manual one-off tool.
- Writing PII into `ActivityLog.title` or a new log column beyond what `title_for_show` already
  stores. Log identifiers; resolve names at render time through a `PiiProvider`.
- Repo-wide patterns are in `conventions/do-not-repeat.md`.

## Related

- `authorization/warehouse-policies.md`: `PiiProvider` construction, policy classes,
  `reporting_policy_for_project`, and the `RestrictedClientLoader` memoization on
  `User#policy_context`.
- `hmis/restricted-records-and-multi-hmis.md`: `Hmis::RestrictedRecord`, `mark_as_restricted!`,
  `pii_redacted_for_client?`, and `Hmis::Hud::Client.searchable_to`, the HMIS half of restriction.
- `hud-reporting/csv-export.md`: `Export::RestrictedClientPiiTransform` and when hashed or faked
  exports bypass it.
- `warehouse/client-identity.md`: `WarehouseClient` links that `HiddenClients` follows and that
  retention's client-scoped aging depends on.
- Human-facing sources: `docs/features/warehouse/warehouse-auth-policies.md` (PII Redaction,
  Search, Known limitations, Report detail rows), `docs/features/hmis/hmis-restricted-records.md`,
  `docs/features/warehouse/client-dashboards.md`, `docs/features/warehouse/client-data-retention.md`,
  `docs/adr/0002-pii-management-strategy.md`,
  `docs/adr/0009-client-data-retention-and-removal.md`.

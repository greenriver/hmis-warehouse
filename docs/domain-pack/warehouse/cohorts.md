---
title: Cohorts
summary: "Named client lists with configurable columns used for care coordination and by-name lists. Covers Cohort, CohortClient, the CohortColumns class hierarchy and the analytics table, tabs and column options, change auditing, copying, system and auto-maintained cohorts, and the cohort access audit."
area: warehouse
tags: [cohorts, Cohort, CohortClient, CohortColumns, CohortColumnOption, CohortTab, CohortCopier, CohortClientChange, system-cohorts, SystemCohortsJob, auto-maintained, cohort-access-audit, analytics_value, column_state]
sources:
  - app/models/grda_warehouse/cohort.rb
  - app/models/grda_warehouse/cohort_client.rb
  - app/models/grda_warehouse/cohort_client_change.rb
  - app/models/grda_warehouse/cohort_column_option.rb
  - app/models/grda_warehouse/cohort_tab.rb
  - app/models/grda_warehouse/cohort_copier.rb
  - app/models/grda_warehouse/cohorts/cohort_column.rb
  - app/models/grda_warehouse/cohorts/cohort_client_data.rb
  - app/models/grda_warehouse/cohorts/cohort_analytics_generation.rb
  - lib/tasks/grda_warehouse.rake
  - config/schedule.rb
  - app/models/grda_warehouse/system_cohorts/base.rb
  - app/models/grda_warehouse/system_cohorts/currently_homeless.rb
  - app/models/cohort_columns/base.rb
  - app/models/cohort_columns/read_only.rb
  - app/models/cohort_columns/cohort_string.rb
  - app/models/cohort_columns/open_enrollments.rb
  - app/models/cohort_columns/destination_from_homelessness.rb
  - app/models/audit/cohort_access/base.rb
  - app/models/audit/cohort_access/intervals.rb
  - app/models/audit/cohort_access/legacy.rb
  - app/models/audit/cohort_access/acl.rb
  - app/controllers/cohorts_controller.rb
  - app/controllers/cohorts/clients_controller.rb
  - app/controllers/cohorts/columns_controller.rb
  - app/controllers/concerns/cohort_authorization.rb
  - app/controllers/concerns/cohort_access_auditing.rb
  - app/jobs/system_cohorts_job.rb
related:
  - authorization/warehouse-access-controls.md
  - authorization/warehouse-legacy-roles.md
  - authorization/warehouse-policies.md
  - warehouse/pii-and-restricted-clients.md
---

## Purpose

A cohort is a named list of destination clients (`GrdaWarehouse::Hud::Client`) with a per-cohort
choice of columns. Communities use cohorts as by-name lists for case conferencing and housing
prioritization. `GrdaWarehouse::Cohort` owns the list, `GrdaWarehouse::CohortClient` is one row
per client with one physical column per possible cohort column (`user_string_1`,
`housed_date`, `days_homeless_last_three_years_on_effective_date`, and so on), and the
`CohortColumns::*` classes decide how each of those physical columns is rendered, edited,
filtered into tabs, and exported to analytics.

Three kinds of cohort exist and are told apart by columns on `cohorts`:

- Manual: `system_cohort: false`, `project_group_id: nil`. Users add and remove clients.
- Auto-maintained: `project_group_id` set. `Cohort#maintain` recomputes membership from open
  enrollments in the project group, optionally narrowed by `automation_sub_population` and
  `automation_hoh_only`. Users cannot add clients by hand.
- System: `system_cohort: true`, an STI subclass of `GrdaWarehouse::SystemCohorts::Base`
  (`CurrentlyHomeless`, `Veteran`, `Chronic`, ...). Membership is rebuilt daily by
  `SystemCohortsJob` when `GrdaWarehouse::Config.get(:enable_system_cohorts)` is on.

Every membership change is written to `GrdaWarehouse::CohortClientChange`, so removals carry a
reason and a date. Cohort visibility is per-entity: each cohort owns a system collection and
two system user groups through `EntityAccess`, and a user sees a cohort only through
`GrdaWarehouse::Cohort.viewable_by(user)`.

Use this doc when adding a cohort column, changing tab rules, changing what a system cohort
counts as housed or inactive, touching cohort permissions, or reading cohort data out for
analytics.

## Entry points

- `GrdaWarehouse::Cohort.viewable_by(user, permission:)` and `editable_by(user)`
  (`app/models/grda_warehouse/cohort.rb`): the only sanctioned way to scope cohorts to a user.
  Controllers reach it through `CohortAuthorization#cohort_scope`.
- `CohortsController` (`app/controllers/cohorts_controller.rb`): index, show (builds the grid
  column headers from `@cohort.visible_columns(user:)`), create (grants the creator editor and
  viewer access via `replace_access`, creates the default tabs), update (writes participant and
  viewer lists through `replace_access`), destroy (`remove_system_collections!`), maintain
  (queues `Cohort#maintain`).
- `Cohorts::ClientsController` (`app/controllers/cohorts/clients_controller.rb`): the client
  grid, add/remove/restore, bulk operations, per-cell edits through `cohort_update_params`, and
  the `log_create`/`log_removal`/`log_activate`/`log_deactivate` writers of
  `CohortClientChange`.
- `Cohorts::ColumnsController` (`app/controllers/cohorts/columns_controller.rb`): edits
  `Cohort#column_state`, the per-cohort ordered list of column objects with `visible` and
  `editable` flags.
- `Cohorts::CopyController` and `GrdaWarehouse::CohortCopier`: copy editable column values and
  notes from another visible cohort.
- `Cohorts::ReportsController`: the client change report, gated by
  `can_view_cohort_client_changes_report`.
- `Cohorts::AclAccessAuditsController` and `Cohorts::LegacyAccessAuditsController`, both using
  `CohortAccessAuditing`: who could see this cohort and when, reconstructed from PaperTrail.
- `GrdaWarehouse::Cohorts::CohortColumn.maintain!`: registers every class name in
  `known_cohort_columns` in the `cohort_columns` table; `deactivate` removes a column from every
  cohort's `column_state`.
- Jobs: `SystemCohortsJob` and `GrdaWarehouse::Cohort.maintain_auto_maintained!` are queued from
  the daily import job; `GrdaWarehouse::Cohort.prepare_active_cohorts` (rake `warm_cohort_cache`)
  refreshes the time-dependent columns; `GrdaWarehouse::Cohorts::CohortAnalyticsGeneration
  .maintain_cohort_intermediate_data` (rake `maintain_cohort_intermediate_data`, a daily cron
  entry) rebuilds the analytics tables under an advisory lock, returning `false` without doing
  work when another run already holds it.
- Permissions, defined in `app/models/role.rb`: `can_view_cohorts`,
  `can_participate_in_cohorts`, `can_manage_cohort_data`, `can_configure_cohorts`,
  `can_edit_cohort_columns`, `can_add_cohort_clients`, `can_view_inactive_cohort_clients`,
  `can_manage_inactive_cohort_clients`, `can_view_deleted_cohort_clients`,
  `can_download_cohorts`, `can_view_cohort_client_changes_report`.

## How it works

### Model

`GrdaWarehouse::Cohort` (`app/models/grda_warehouse/cohort.rb`) is paranoid and paper-trailed.
It `has_many :cohort_clients` and `:cohort_tabs`, `belongs_to :project_group` (auto-maintenance
source), `belongs_to :owner` (a cross-database `User`), and `belongs_to :tags`
(`CasAccess::Tag`, used when `visible_in_cas` is set). `column_state` is a YAML-serialized
`Array` of `CohortColumns::*` instances; the permitted class list is
`GrdaWarehouse::Cohorts::CohortColumn.known_cohort_columns`. `visible_columns(user:)` returns
the visible entries of `column_state` (or `default_visible_columns`, last and first name) with
`current_user` assigned to each so columns can make PII decisions.

`after_create :maintain_system_group` queues `Collection.delayed_system_group_maintenance(group:
:cohorts)` (and the legacy `AccessGroup` equivalent), which adds the cohort to the "All
Cohorts" and "Hidden System Group" system collections. Per-user access is handled by
`EntityAccess#replace_access(users, scope: :editor | :viewer)`; see
`authorization/warehouse-access-controls.md` for the collection, user group, and role that
concern creates per cohort.

`viewable_by(user, permission:)` on the ACL branch resolves `user.collections_for_permission`
for `can_view_cohorts` and reads cohort ids from `GrdaWarehouse::GroupViewableEntity`
`where(collection_id:, entity_type: 'GrdaWarehouse::Cohort')`. The legacy branch returns
`user.cohorts`. `editable_by(user)` on the ACL branch passes the collection ids to
`where(access_group_id: ...)` rather than `collection_id:`; do not assume it mirrors
`viewable_by` without reading it.

`GrdaWarehouse::CohortClient` is paranoid and paper-trailed, `belongs_to :cohort` and
`:client`, has `active` (a user-set boolean, independent of calculated inactivity), and holds
one physical column per cohort column. `pii_provider(user:, mode: :browse | :download)` returns
a `GrdaWarehouse::PiiProvider`: browsing allows PII to anyone who can see the cohort, downloads
additionally require `GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)`, and an
HMIS-restricted client is always redacted. `available_removal_reasons` is the fixed list offered
when removing a client.

`GrdaWarehouse::CohortTab` (`app/models/grda_warehouse/cohort_tab.rb`) is a named, ordered
filter over `cohort_clients`: `rules` is a JSON tree of `{column, operator, value}` leaves joined
by `and`/`or`/`not`, compiled to Arel by `rule_query` using each column class's `arel_col` and
`cast_value`; `base_scope` (for example `only_deleted`) picks the paranoid scope; `permissions`
lists role flags, any one of which lets a user see the tab (`show_for?`). `default_rules`
defines the five tabs created with every cohort: Active Clients, Housed, Ineligible, Inactive,
and Removed Clients. There is no UI for editing tabs.

`GrdaWarehouse::CohortColumnOption` stores the dropdown values for `CohortColumns::Select`
subclasses, keyed by `cohort_column` (the physical column name) with `active` and `weight`.

### Columns

Every cohort column is a class under `app/models/cohort_columns/`. `CohortColumns::Base`
(`app/models/cohort_columns/base.rb`) is a `ModelForm` with attributes `column` (the physical
`cohort_clients` column), `translation_key`, `title`, `description`, `visible`, `editable`,
`input_type`, plus runtime context `cohort`, `cohort_client`, and `current_user` that callers
must assign before rendering. It defines defaults for `default_input_type` (`:string`),
`renderer` (`'text'`; the JS grid also understands `dropdown`, `date`, `checkbox`, `numeric`,
and `html`), `column_editable?` (true), `available_for_rules?` (true, meaning tabs may filter
on it), `cast_value` (used by tab rules), `arel_col`, `value(cohort_client)`, `width`,
`date_format`, and `available_options`.

`Base` does not define `display_for` or `display_read_only`. The type classes do:
`CohortString`, `CohortBoolean`, `CohortDate`, `Select`, `Radio`, `Integer`, `Text`, and
`ReadOnly`. Each `display_for(user)` renders an input when `display_as_editable?` is true and
falls back to `display_read_only(user)` otherwise. `display_as_editable?` requires
`cohort.user_can_edit_cohort_clients(user)` and either `can_manage_cohort_data?` or
(`editable` on this cohort's `column_state` entry and `can_participate_in_cohorts?`).
`ReadOnly` (`app/models/cohort_columns/read_only.rb`) sets `column_editable?` false and returns
`value(cohort_client)` for both display methods.

A concrete column such as `CohortColumns::UserString1 < CohortString` only sets `attribute`
defaults for `column`, `translation_key`, `title`, and `description`. Titles and descriptions
go through `Translation.translate`, so installations rename columns without code. Generic slots
exist for `UserString1..30`, `UserBoolean1..49`, `UserSelect1..30`, `UserDate1..30`, and
`UserNumeric1..10`. A calculated column such as `CohortColumns::DaysHomelessLastThreeYears <
ReadOnly` overrides `value`, `arel_col`, and `cast_value` to read the
`*_on_effective_date` column that `Cohort#refresh_time_dependant_client_data` fills.

Analytics export uses two more methods on `Base`. `analytics_data_type` maps the input type and
renderer to one of `boolean`, `integer`, `string`, `text`, or `date`, which picks the
`value_<type>` column in `cohort_client_data`. `analytics_value` defaults to
`display_read_only(current_user)`, so whatever a column renders for a read-only viewer is what
gets stored. Columns that render markup must override it with a text form:
`CohortColumns::OpenEnrollments` renders `<div>` tags in `display_read_only` and returns
`text_value` from `analytics_value` (`app/models/cohort_columns/open_enrollments.rb`).

Adding a column: create the class, add its name to
`GrdaWarehouse::Cohorts::CohortColumn.known_cohort_columns`, add the physical column to
`cohort_clients` if it is user-entered, and run `CohortColumn.maintain!`. `Cohort` also defines
an `attr_accessor` per column and raises at load if one collides with a real `cohorts` column.

### Auditing

`GrdaWarehouse::CohortClientChange` (`app/models/grda_warehouse/cohort_client_change.rb`)
records membership events: `change` is one of `create`, `destroy`, `activate`, `deactivate`;
`reason` is free text or a value from `CohortClient.available_removal_reasons`; `changed_at` is
the event date; `user_id` is the actor (`User.system_user` or `User.setup_system_user` for
automated changes). `belongs_to :cohort_client` is declared `with_deleted` so removed rows still
resolve. `removal` scopes to `destroy` and `deactivate`; `associated_exit` finds the next
removal after a given change for the same cohort client, which the change report uses to pair
entries with exits.

Writers:

- `Cohorts::ClientsController#log_create`, `log_removal`, `log_activate`, `log_deactivate`
  for user actions, with `current_user` as actor.
- `Cohort#add_clients(client_ids, reason)` and `remove_clients(client_ids, reason)` for
  auto-maintained cohorts, with reasons `Matches automation criteria` and `No longer matches
  automation criteria`. Both run under `with_client_update_lock`, a per-cohort advisory lock,
  and bulk insert through `activerecord-import`.
- `GrdaWarehouse::SystemCohorts::Base.update_system_cohort` for system cohorts: for each date
  in the range it deletes the system user's changes with a known reason on that date, then
  re-runs `sync` for that date inside one transaction, so re-processing a week of dates leaves
  exactly one set of changes per date. Known reasons: `Newly identified`, `Returned from
  housing`, `Returned from inactive`, `Inactive`, `No longer meets criteria`, `Housed`.

Cell edits are not written to `CohortClientChange`. `CohortClient` `has_paper_trail`, so
column-value history lives in the warehouse `versions` table. Notes are separate rows
(`GrdaWarehouse::CohortClientNote`).

Two things called "inactive" coexist. `CohortClient#active` is a boolean users and automation
set; the Inactive tab filters on it. Calculated inactivity is
`CohortColumns::Meta#inactive`, which compares `Cohort#days_of_inactivity` against the
client's `last_homeless_date` and `last_intentional_contacts` in `WarehouseClientsProcessed`.
`GrdaWarehouse::Hud::Client#active_cohort_clients` requires both, and CAS sync reads that.

### Copying

`GrdaWarehouse::CohortCopier` (`app/models/grda_warehouse/cohort_copier.rb`) copies column
values from one cohort to another for clients that are on both. `Cohorts::CopyController`
requires `can_add_cohort_clients`, loads the destination cohort through `cohort_scope`, and
offers as sources the other cohorts in `cohort_scope` and as columns the destination's
`column_state` entries with `editable` set.

`CohortCopier.new(destination_cohort, cohort_scope, params)` finds the source cohort inside the
given scope (so a user cannot copy from a cohort they cannot see), selects the requested
physical columns plus `client_id` from the source's `cohort_clients` restricted to the
destination's client ids, and `copy!` runs one transaction that `update`s each destination
`CohortClient` with the source attributes. When `notes` is among the requested columns, each
`GrdaWarehouse::CohortClientNote` on the matching source cohort client is duplicated onto the
destination cohort client, preserving `created_at` and `updated_at`.

Behavior to know before extending it:

- Only clients already on the destination are affected. Copying does not add members.
- `notes` and `client_notes` are removed from the SQL select list because they are not columns
  on `cohort_clients`; `notes` is handled by the note duplication path and `client_notes` is
  ignored.
- The copy uses `update`, so `CohortClient` paper-trail versions record the copied values, but
  no `CohortClientChange` is written.
- `copy!` returns the value of the transaction block; the controller treats a falsy return as
  failure and re-renders, but there is no rescue, so a failing `update` raises.

### System cohorts

`GrdaWarehouse::SystemCohorts::Base < GrdaWarehouse::Cohort`
(`app/models/grda_warehouse/system_cohorts/base.rb`) is an STI parent; each subclass is one
system cohort and one config flag. `cohort_classes` maps the flag to the class:
`currently_homeless_cohort`, `veteran_cohort`, `youth_cohort`, `chronic_cohort`,
`adult_and_child_cohort`, `adult_only_cohort`, `youth_no_child_cohort`,
`youth_and_child_cohort`, `youth_hoh_cohort`, `chronic_adult_only_cohort`. A system cohort
exists only when its flag is on; `ensure_system_cohort` creates it with `system_cohort: true`,
`days_of_inactivity: 90`, its `cohort_name`, and the default tabs, and keeps the name in sync.

`SystemCohortsJob` (`app/jobs/system_cohorts_job.rb`) returns early unless
`GrdaWarehouse::Config.get(:enable_system_cohorts)`, takes a job-wide advisory lock so two runs
never overlap, and calls `Base.update_all_system_cohorts`. The daily import job queues it. The
default range is the last week through yesterday: HMIS data arrives late, so each day
re-computes the prior week to absorb back-dated entry. `date_window` comes from
`GrdaWarehouse::Config.get(:system_cohort_date_window)`, default one day.

`update_system_cohort(range:, date_window:)` loops one transaction per date: delete the system
user's `CohortClientChange` rows with a known reason on that date, load a fresh cohort instance
(so memoized per-date candidates do not leak), and call `sync(processing_date:, date_window:)`.
`sync` returns false when it cannot get the cohort's write lock within ten seconds, and the
transaction rolls back so the deleted changes come back.

`GrdaWarehouse::SystemCohorts::CurrentlyHomeless`
(`app/models/grda_warehouse/system_cohorts/currently_homeless.rb`) is the reference
implementation. `sync` runs four steps against `ServiceHistoryEnrollment.entry` and
`ServiceHistoryService`: `add_missing_clients` classifies candidates (open homeless enrollment
with service in the inactivity window, or a lone CE enrollment whose latest current living
situation is homeless) as `Newly identified`, `Returned from housing` (previous exit to a
permanent destination per `HudHelper.util.permanent_destinations`, or housed service the day
before), or `Returned from inactive`; `remove_housed_clients` removes move-ins to PH and exits
to permanent destinations unless a homeless enrollment is still active; `remove_inactive_clients`
removes anyone without homeless or qualifying CE service within `days_of_inactivity`;
`remove_no_longer_meets_criteria` removes non-permanent exits with no remaining homeless
enrollment and clients currently moved into PH. Household-composition cohorts share the
`households` helper in `Base`, built from open residential enrollments grouped by
`HouseholdID`.

### Access auditing

`Cohorts::AclAccessAuditsController` and `Cohorts::LegacyAccessAuditsController` include
`CohortAccessAuditing` (`app/controllers/concerns/cohort_access_auditing.rb`), which requires
`can_configure_cohorts`, `can_audit_users`, and the cohort being in `cohort_scope`. Each
controller supplies an `audit_service_class`; `show` renders the current access list and event
log, and `export` (or `show.csv`) sends `to_csv`. Both services subclass
`Audit::CohortAccess::Base` (`app/models/audit/cohort_access/base.rb`), which owns the interval
math, the effective-access union, the event log, and the CSV.

`Audit::CohortAccess::Legacy` reconstructs the path User -> `AccessGroupMember` ->
`AccessGroup` -> `GroupViewableEntity(access_group_id)` -> Cohort. Its version sources are
`GrdaWarehouse::Version` for `GroupViewableEntity` rows (warehouse database) and
`GrPaperTrail::Version` for `AccessGroupMember` and `AccessGroup` rows (app database). A
personal access group has no member row for its owner, so the owner's window is derived from
the group's own versions.

`Audit::CohortAccess::Acl` reconstructs User -> `UserGroupMember` -> `UserGroup` ->
`AccessControl(collection_id)` -> `Collection` -> `GroupViewableEntity(collection_id)` ->
Cohort. Sources are `GrdaWarehouse::Version` for `GroupViewableEntity` and
`GrPaperTrail::Version` for `AccessControl` and `UserGroupMember`. A user's window is the
intersection of membership, access-control lifetime, and cohort-in-collection lifetime.

What the reconstruction cannot know, from the code:

- Roles are ignored. `Base::PERMISSIONS_NOTE` states that the audit shows structural
  relationships only; a user listed as having access may have held a role without
  `can_view_cohorts`.
- Restores are unversioned. `Collection#set_viewables`, `Collection#add_viewable`, and
  `AccessGroup#add_viewable` bring back a soft-deleted `GroupViewableEntity` with `restore`,
  which writes no PaperTrail version. `Intervals.reconcile_with_record` detects a live row whose
  version timeline ends closed and reopens it at the row's `updated_at`, an approximation.
- Missing timestamps. `access_groups` has no `created_at` or `updated_at`;
  `access_group_members` has only `deleted_at`. `Intervals.fallback_intervals` treats a live row
  with no versions and no timestamps as present since the epoch, bounded later by the
  intersection with other paths.
- System collections appear as paths. Every cohort is added to the "All Cohorts" and "Hidden
  System Group" collections by the delayed maintenance job after create, and neither service
  filters system collections or groups out of `paths`, so those grants show up dated at the
  job's run time with the system user excluded from affected users.

## Key files

- `app/models/grda_warehouse/cohort.rb:91` `viewable_by`; `:122` `editable_by`; `:325`
  `visible_columns`; `:410` `prepare_active_cohorts`; `:419` `refresh_time_dependant_client_data`;
  `:449` `with_client_update_lock`; `:655` `maintain_system_group`; `:713` `maintain`; `:764`
  `add_clients`; `:809` `remove_clients`.
- `app/models/grda_warehouse/cohort_client.rb:32` `pii_provider(user:, mode:)`.
- `app/models/grda_warehouse/cohort_client_change.rb:22` `removal`; `:28` `associated_exit`.
- `app/models/grda_warehouse/cohort_tab.rb:21` `show_for?`; `:37` `rule_query`; `:159`
  `default_rules`.
- `app/models/grda_warehouse/cohort_column_option.rb`: dropdown values per `Select` column.
- `app/models/grda_warehouse/cohort_copier.rb:21` `copy!`.
- `app/models/grda_warehouse/cohorts/cohort_column.rb:19` `deactivate`; `:44`
  `known_cohort_columns`.
- `app/models/grda_warehouse/cohorts/cohort_analytics_generation.rb`: orchestrates the three
  analytics tables and logs run times; `maintain_cohort_intermediate_data` takes an advisory
  lock (`with_lock`) so concurrent triggers don't double-run.
- `app/models/grda_warehouse/cohorts/cohort_client_data.rb:18` `maintain_data`; `:54`
  `text_value`, which calls `analytics_value`.
- `app/models/grda_warehouse/system_cohorts/base.rb:21` `update_system_cohort`; `:59`
  `ensure_system_cohort`; `:174` `cohort_classes`.
- `app/models/grda_warehouse/system_cohorts/currently_homeless.rb:15` `sync`.
- `app/models/cohort_columns/base.rb:78` `display_as_editable?`; `:110` `analytics_data_type`;
  `:122` `analytics_value`.
- `app/models/cohort_columns/read_only.rb`: the read-only type class.
- `app/models/cohort_columns/cohort_string.rb`: the simplest editable type class.
- `app/models/cohort_columns/open_enrollments.rb:62` `analytics_value` returning `text_value`.
- `app/models/cohort_columns/destination_from_homelessness.rb:18` `value` returning stored
  markup.
- `app/models/audit/cohort_access/base.rb:22` `PERMISSIONS_NOTE`.
- `app/models/audit/cohort_access/intervals.rb:53` `reconstruct`; `:79`
  `reconcile_with_record`; `:118` `fallback_intervals`.
- `app/models/audit/cohort_access/legacy.rb`, `app/models/audit/cohort_access/acl.rb`: the two
  path reconstructions.
- `app/controllers/cohorts_controller.rb:142` `create`; `:166` `update`.
- `app/controllers/cohorts/clients_controller.rb:593` `cohort_update_params`; `:600`
  `log_create`; `:650` `client_scope`.
- `app/controllers/cohorts/columns_controller.rb:20` `update`; `:51` `set_cohort`.
- `app/controllers/concerns/cohort_authorization.rb:19` `require_can_access_cohort!`; `:31`
  `cohort_scope`.
- `app/controllers/concerns/cohort_access_auditing.rb:19-21` the three `before_action`s.
- `app/jobs/system_cohorts_job.rb:28` `_perform`.

## Gotchas

- `analytics_value` defaults to `display_read_only(current_user)`, so a column whose read-only
  display is markup stores that markup in `cohort_client_data.value_text`.
  `CohortColumns::DestinationFromHomelessness` does this today: `Cohort#destination_from_homelessness`
  writes a hidden `<span>` with the sort date into the `cohort_clients` column, `ReadOnly`
  returns the stored value, and no `analytics_value` override strips it. Override
  `analytics_value` with a text form on any column that renders HTML.
- `GrdaWarehouse::Cohorts::CohortClientData.maintain_data` sets `current_user = User.system_user`
  on each column, so PII decisions inside `display_read_only` are made as the system user.
  `Cohort.excluded_from_analytics` (`LastName`, `FirstName`, `Dob`, `Ssn`, `Delete`) keeps direct
  identifiers out; a new PII column must be added there.
- `EntityAccess` creates one system collection, two system user groups, two system roles, and
  two access controls per cohort on first use of `replace_access`. Counting `Collection`,
  `UserGroup`, or `Role` without the `not_system`/`general` scopes inflates the numbers. Details in
  `authorization/warehouse-access-controls.md`.
- `column_state` is YAML with a permitted-class list. A `CohortColumns::*` instance that has
  memoized `@cohort_column` (a live `GrdaWarehouse::Cohorts::CohortColumn`) cannot be
  re-serialized; `GrdaWarehouse::Cohorts::RepairColumnState` exists to strip that ivar from
  affected rows. Do not call `cohort_column` on objects that will be saved back into
  `column_state`.
- `Cohort.editable_by` on the ACL branch queries `GroupViewableEntity` by `access_group_id`
  with collection ids. `viewable_by` queries by `collection_id`. Read both before relying on
  `editable_by` for an ACL user.
- Concurrent writers to `cohort_clients` (system cohort sync, `maintain`, cache warm) use
  `with_client_update_lock`, a per-cohort Postgres advisory lock that is non-blocking by
  default. A caller that skips it can deadlock with the jobs.
- `Cohorts::ColumnsController#set_cohort` uses `GrdaWarehouse::Cohort.find`, not
  `cohort_scope.find`; only `can_edit_cohort_columns` gates it.
- Time-dependent columns (`*_on_effective_date`, `destination_from_homelessness`,
  `related_users`, `missing_documents`, `most_recent_*`) are only as fresh as the last
  `prepare_active_cohorts` run; they are not recomputed on view.
- System cohort `sync` waits up to ten seconds for the cohort lock and returns false on
  failure; the per-date transaction then rolls back and that date is retried on the next run.

## Do not repeat

- A read-only column that returns HTML from `display_read_only` without overriding
  `analytics_value`. `CohortColumns::DestinationFromHomelessness`
  (`app/models/cohort_columns/destination_from_homelessness.rb:18`) persists markup into
  analytics. Replacement: override `analytics_value` to return a plain string, as
  `CohortColumns::OpenEnrollments` does (`app/models/cohort_columns/open_enrollments.rb:62`).
- Gating a cohort action on a global `require_can_x!` alone and loading the cohort with
  `GrdaWarehouse::Cohort.find`. `Cohorts::ColumnsController#set_cohort`
  (`app/controllers/cohorts/columns_controller.rb:51`) does this. Replacement: include
  `CohortAuthorization`, load through `cohort_scope.find`, and keep the permission check as
  the second gate, as `Cohorts::ClientsController` and `CohortAccessAuditing`
  (`app/controllers/concerns/cohort_access_auditing.rb:19-21`) do. `user.can_x?` answers
  "anywhere", not "on this cohort"; see `authorization/warehouse-policies.md`.
- Writing `Collection`, `UserGroup`, `Role`, or `AccessControl` rows to give a user one cohort.
  Replacement: `cohort.replace_access(users, scope:)` as `CohortsController#create`
  (`app/controllers/cohorts_controller.rb:150`) does.
- Changing `cohort_clients` membership without a `GrdaWarehouse::CohortClientChange`. The change
  report, `associated_exit`, and system cohort re-processing depend on one row per event.
  Replacement: `Cohort#add_clients`/`remove_clients` for automated paths, the
  `Cohorts::ClientsController#log_*` methods for user actions.
- A new visibility scope for cohorts (`visible_to`, `accessible_by`). Replacement:
  `GrdaWarehouse::Cohort.viewable_by(user)` (`app/models/grda_warehouse/cohort.rb:91`).

## Related

- `authorization/warehouse-access-controls.md`: `EntityAccess`, system collections,
  `collections_for_permission`, and `GroupViewableEntity`.
- `authorization/warehouse-legacy-roles.md`: the `AccessGroup` path that the legacy audit and
  the `START_ACL`/`END_ACL` blocks in `Cohort` and `CohortsController` still serve.
- `authorization/warehouse-policies.md`: `policy_for`, `CohortPiiPolicy`, and why `can_x?` is
  not a record-level check.
- `warehouse/pii-and-restricted-clients.md`: `PiiProvider`, restricted-client redaction, and
  `include_pii_in_detail_downloads`.
- `docs/features/warehouse/cohorts.md`: the human-facing description, including the inactivity
  calculation and user workflow.

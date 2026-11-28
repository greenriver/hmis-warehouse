---
sources:
  - app/models/grda_warehouse/cohort.rb
  - app/models/grda_warehouse/auth_policies/cohort_policy.rb
  - app/models/grda_warehouse/tasks/backfill_cohort_managers.rb
  - app/controllers/concerns/cohort_authorization.rb
  - app/controllers/cohorts_controller.rb
  - app/models/grda_warehouse/cohort_client_change.rb
  - app/models/grda_warehouse/cohort_copier.rb
  - app/controllers/cohorts/copy_controller.rb
  - app/views/cohorts/_cohorts_js.haml
  - db/warehouse/migrate/20261124140000_reset_invalid_cohort_sort_directions.rb
  - app/models/grda_warehouse/system_cohorts/base.rb
  - app/models/cohort_columns/base.rb
  - app/models/audit/cohort_access/base.rb
  - app/controllers/cohorts/columns_controller.rb
---

# Cohorts

The Cohorts feature is a tool for grouping, tracking, and visualizing client data. It allows users to create custom lists of clients based on specific criteria, which can then be used for case management, reporting, and in-depth data analysis. Many communities use this feature to support By-Name-Lists or BNL.

## Key Concepts

- **Cohort:** A cohort is a dynamic list of clients. Cohorts are configurable, allowing users to define which clients are included and what data is displayed for them.

- **Types of Cohorts:**
  - **Manual Cohort:** A static list of clients that is managed manually. Users can add or remove clients as needed. This is useful for tracking specific groups of clients that don't fit into automated categories.
- **Auto-Maintained Cohort:** A dynamic cohort where membership is determined by a client's enrollment in a `ProjectGroup`. Additional automation filters (Heads of Household, sub-populations, etc.) can be layered on, but only after a project group is selected. A scheduled maintenance job (`Cohort.maintain_auto_maintained!`) keeps these cohorts in sync; users with configuration access can also queue an on-demand refresh from the cohort page. Automation includes clients from every project in the group, including confidential projects that were picked into it; see [Project Groups](./project-groups.md#in-auto-maintained-cohorts).
  - **System Cohort:** These are special, system-defined cohorts that are used for specific, built-in functionalities. They are not typically managed by end-users.

## Permissions & Access

Cohort permissions are the `can_*cohort*` permissions on `Role`. For users on Access Controls, every cohort permission except `can_create_cohorts` is checked per cohort through `GrdaWarehouse::AuthPolicies::CohortPolicy`, so it counts only where the user's roles reach that cohort. See [Cohort policy](./warehouse-auth-policies.md#cohort-policy) for the checks, and [Warehouse Permissions](./warehouse-permissions.md) for how roles, collections and user groups combine.

### Create vs. configure

- `can_create_cohorts` creates cohorts and edits the cohort-wide column names and options (`CohortColumnNamesController`, `CohortColumnOptionsController`). It is global: it applies to every cohort, even under Access Controls, because a new cohort has no collection to scope it to.
- `can_configure_cohorts` edits, removes and refreshes (`maintain`) one cohort. Under Access Controls it applies only to cohorts the user can configure through a collection or as a Manager.
- Creating a cohort grants an Access Controls creator no access to it. A creator still on legacy access groups gets the cohort added to their access group. The Participants, Viewers and Managers submitted with the create form are applied. A project group chosen on create or update is kept only if the user can view it (`GrdaWarehouse::ProjectGroup.viewable_by`); otherwise the cohort is saved without it. On update, the cohort's current project group is kept.

### Managers

Each cohort has three user lists on its Edit form: Participants, Viewers and Managers. Managers are a third per-cohort access control, a system user group bound to the system role "System Role - Can Configure Cohorts". It grants `can_configure_cohorts` on that cohort only. Set it with `cohort.replace_access(users, scope: :manager)`.

- A Manager who is not also a Participant or Viewer can configure the cohort but not view it.
- Managers can change the Participants and Viewers, including adding themselves to either list.
- The Participants, Viewers and Managers pickers list only active, non-system users. Saving the Edit form rewrites each submitted list from the picker, so an inactive user in a list is removed from it. A list absent from the submission is left alone.

### What a configure-only user sees

A user who can configure a cohort but not view it sees the Edit page and nothing else for that cohort. The Edit page also offers the access audit when the user has `can_audit_users`, and the refresh action on auto-maintained cohorts. `CohortPolicy#can_configure?` does not imply `can_view?`.

### Listing

The index lists cohorts through `User#can_access_some_cohorts` and `GrdaWarehouse::Cohort.listable_by`. It includes a cohort when the user has a view, participate, manage-data or configure permission on it. A cohort the user can configure but not view links to Edit instead of the cohort page; the index decides this per cohort with `can_view?` and `can_configure?`. The set of cohorts behind the index is cached per user for five minutes, while the per-request checks are live, so a change to a user's access can take up to five minutes to show in the list.

### Per-cohort checks

The cohort controllers load the cohort without a user scope and then authorize with `authorize_with` and `cohort_policy` (`CohortAuthorization`). A refused request redirects; an id that doesn't exist returns 404. Every other cohort permission (add clients, manage data, participate, manage inactive, view deleted, download, edit columns, changes report) is true only when the user can also view the cohort and holds the permission through it. `can_edit_cohort_columns` gates the columns page per cohort; `can_create_cohorts` gates the column names and options pages.

Reading, changing or removing one cohort client row (`Cohorts::ClientsController` show, edit, field, update, pre_destroy and destroy, and the notes indexes in `Cohorts::ClientNotesController` and `Cohorts::NotesController`) goes through `find_visible_cohort_client`. The row must be in a tab the user can see on that cohort, or the request returns 404. Bulk remove, bulk restore and re-rank act only on the submitted rows that are in a visible tab (`visible_cohort_client_ids`) and skip the rest. `Cohorts::ClientsController#index` answers JSON only; an HTML request returns 406.

An update saves only the columns shown on that cohort's grid (`Cohort#active_columns`) that are editable for the user: every editable column for manage-data, and columns the cohort marks editable for participate. Columns hidden on the cohort are not saved.

Deleting a cohort note (`GrdaWarehouse::ClientNotes::CohortNote#destroyable_by`) checks every cohort the client is on or was removed from, and requires `can_edit_clients?` on at least one.

### Backfill and release notes

`GrdaWarehouse::Tasks::BackfillCohortManagers` runs once from the `BackfillCohortManagers` data migration, so it finishes before the new code serves requests. For each cohort that is not a system cohort and has no manager group, it makes every active Access Controls user who is a Participant and holds `can_configure_cohorts` through a non-system role a Manager. Cohorts with a manager group, even an empty one, are skipped, so a Manager an admin removed is not re-added. The grants are recorded as the system user. The migration runs in one transaction, so a failure stops the deploy with nothing granted, and rerunning the migration retries. Run outside a migration, the task grants each cohort in its own transaction.

Release notes:

- ACL users who could configure any visible cohort now configure only the cohorts where they are Managers or hold configure through a collection. The backfill covers existing Participants who held a non-system configure role. Others need to be added as Managers.
- ACL users now hold every other cohort permission only through a role on a collection that contains the cohort: add clients, manage data, manage inactive clients, view inactive clients, view deleted clients, download, edit columns and the changes report. A role on a data source, project or other collection no longer grants them on any cohort. The Participant and Viewer lists grant only participate and view, so admins must add each affected cohort to a collection and grant a role carrying these permissions to the users who need them. The backfill does not grant them.
- Roles that gave `can_configure_cohorts` now also need `can_create_cohorts` to create cohorts. The `AddCanCreateCohortsPermission` migration sets it on non-system roles that held configure.
- Legacy (role-based) users: a per-cohort permission other than configure now also needs a view, participate or manage-data permission on the cohort. Roles with only add-clients, download, changes-report, edit-columns or manage-inactive lose access to the cohort.
- Managers can add themselves as Participant or Viewer.
- Refused requests redirect. A cohort id that doesn't exist returns 404.

## Configurable Views & Automation Filters
- **Automation Filters:** When a project group is chosen, editors can optionally limit membership further via Heads of Household or configured sub-populations. These filters are intentionally gated behind the project-group requirement so the resulting cohorts remain bounded to the relevant projects; without that guard, user-created automation could balloon to every client in the warehouse and exceed the ~1,000 client scale that the cohorts UI supports comfortably.

Cohorts can be customized to tailor the view to specific needs.

- **Custom Columns:** Users can select which columns of data to display for the clients in a cohort. This can range from basic demographic information to complex calculated fields like "days homeless in the last three years."
- **Tabs:** Cohorts can have multiple tabs, each providing a different filtered view of the client list. For example, a cohort might have separate tabs for "Active Clients," "Inactive Clients," and "Recently Exited Clients.". There is no currently no user interface for managing these tabs; we rely on engineers to manually configure tabs.
- **Thresholds:** Users can define visual thresholds to highlight clients who meet certain criteria. For example, a row might be colored red if a client has been homeless for more than a year.

## Client Activity and Status

A client's activity status within a cohort is determined by two mechanisms:

### 1. The `active` Boolean Field

Each `CohortClient` record has an `active` boolean field that can be set manually or by system processes. This field is used to filter clients into different tabs (e.g., "Active Clients" vs "Inactive Clients"). The field can be updated by:
- Auto-maintained cohorts when clients no longer meet enrollment criteria
- Manual updates by users
- System processes that maintain cohorts

### 2. Calculated Inactivity Based on Service History

Cohorts can detect when a client has become **inactive** due to lack of recent services, which is separate from the `active` boolean. This is controlled by the `days_of_inactivity` setting on each cohort; admin staff may adjust this threshold

Inactivity does not remove a client from the cohort but may remove them from certain tools that use cohort inclusion to make decisions. For instance, CAS will ignore clients who do not meet the activity threshold for a given cohort.

**How it works:**

1. **Service History Foundation**: Service History generates daily `ServiceHistoryService` records for each client's enrollments (see [Service History documentation](./service-history.md))

2. **Cached Aggregation**: A nightly job aggregates service history data into the `WarehouseClientsProcessed` table, computing:
   - `last_homeless_date`: Most recent date with a homeless service
   - `last_intentional_contacts`: JSON array of the most recent contact per project: HUD services, Current Living Situations, and CE Events from enrollments open in the last 3 years, plus the most recent custom service

3. **Inactivity Detection**: When displaying cohort clients, the system checks:
   ```ruby
   # A client is inactive if their last activity was more than N days ago
   last_activity = [last_homeless_date, last_intentional_contact].max
   inactive = (Date.current - cohort.days_of_inactivity.days) > last_activity
   ```

4. **Visual Indicators**: Inactive clients show a warning icon in the cohort view, and some system cohorts automatically remove clients who become inactive.

**Important Notes:**
- The `active` boolean and calculated inactivity are **independent** - a client can be marked `active: true` but still be considered inactive due to no recent services
- Auto-maintained system cohorts (like "Currently Homeless") may automatically remove clients when they become inactive
- The cached data in `WarehouseClientsProcessed` is refreshed periodically via `Cohort.prepare_active_cohorts`. So changes in service history may not immediately affect cohorts.

For a detailed explanation of how the Service History is generated and how it impacts client activity, please see the [Service History documentation](./service-history.md).

## User Workflow

1.  **Creation:** Users can create new cohorts from the main Cohorts index page, giving them a name and configuring their basic properties (e.g., manual vs. auto-maintained).
2.  **Configuration:** Once created, a cohort can be edited to add custom columns, define tabs, and set up display thresholds.
3.  **Client Management:** For manual cohorts, clients can be added or removed individually or in bulk. For auto-maintained cohorts, client membership is handled automatically.
4.  **Viewing and Exporting:** Users can view cohorts through the web interface and export the data to Excel for further analysis.

## Related Code

- **Model:** `app/models/grda_warehouse/cohort.rb`
- **Controller:** `app/controllers/cohorts_controller.rb`
- **Client Management in Cohorts:** `app/controllers/cohorts/clients_controller.rb`
- **Service History Logic:** `app/models/grda_warehouse/service_history_enrollment.rb`
- **Service History Generation Task:** `app/models/grda_warehouse/tasks/service_history/enrollment.rb` (see `rebuild_service_history!`)

## Behavior notes

### Visibility
- Per-user access is per cohort. Each cohort owns a system collection and two system user groups (editor and viewer), created on first use of `replace_access`. Counting collections, user groups, or roles without the `not_system` / `general` scopes inflates the numbers.
- Scope cohorts to a user with `GrdaWarehouse::Cohort.viewable_by(user)` (or `editable_by`), never with a new visibility scope or by writing collection, group, role, or access control rows by hand. Use `cohort.replace_access`.
- A user who can edit a cohort can see it, so `viewable_by` includes the editing permissions by default. `editable_by` does not also require a view permission.
- Cohort PII follows the viewing user. Browsing shows PII to anyone who can see the cohort, downloads also require the `include_pii_in_detail_downloads` config, and a client who is restricted in HMIS or the warehouse, or retention-marked is always redacted.
- New cohort controllers include `CohortAuthorization`, load with `load_cohort`, and authorize with `cohort_policy` rather than scoping the load.

### Membership history
- Every membership change writes a `CohortClientChange` (create, destroy, activate, deactivate), and the change report and `associated_exit` pair entries with exits from those rows. Use `add_clients` / `remove_clients` for automated paths. Do not change membership without a change row.
- Cell edits are not written there. Column-value history lives in PaperTrail versions on `CohortClient`, and notes are separate rows.
- Copying values between cohorts (see [Copying from another cohort](#copying-from-another-cohort)) writes PaperTrail versions, and writes a change row only when it flips a client's `active` flag.

### Copying from another cohort
`Cohorts::CopyController` and `GrdaWarehouse::CohortCopier` copy column values and notes from a source cohort into the destination cohort the user is viewing. The Import link in the cohort nav opens it.

- **Who can copy.** The user needs `can_add_clients?` on the destination. System and auto-maintained cohorts redirect back to the cohort page, and the nav hides the link for them.
- **Source.** The source is chosen from the cohorts the user can view, and the destination is excluded from the list. A source id the user cannot view raises `ActiveRecord::RecordNotFound` (404). Choosing the destination as its own source shows "Choose a different cohort to copy from."
- **Which columns.** `CohortCopier.copyable_columns` returns the destination columns that are editable and visible, and that `display_as_editable?` allows for the user. A selected column is copied only if it is in that list and is a `cohort_clients` column or `notes`. `CohortCopier::NEVER_COPIED_COLUMNS` (the primary key, `cohort_id`, `client_id`, timestamps, `deleted_at`) is never copied. Other submitted names are dropped.
- **Which rows.** Only clients already on the destination are updated. Rows are read from the source and written to the destination only through `Cohort#visible_cohort_clients(user)`, which covers the tabs the user can see and excludes tabs that show deleted clients. Soft-deleted clients are not copied.
- **Notes.** Selecting `notes` copies the source's notes with their original author and timestamps. A note is skipped when the destination row already has one with the same text, author and `created_at`, so repeating a copy does not duplicate notes.
- **`active`.** When a copy changes `active`, it writes a `CohortClientChange` (activate or deactivate) attributed to the copying user. Other column changes write no change rows.
- **Atomicity.** All updates run in one transaction. A validation failure on any row raises and rolls back the whole copy.
- **Messages.** With no copyable columns, the page shows "You can't edit any columns in this cohort." and the nav hides the Import link. With no source or no selected copyable column it shows "All fields are required."

### Inactivity
- The `active` flag drives the Inactive tab; calculated inactivity (`days_of_inactivity` against `WarehouseClientsProcessed`) is separate. A client's active-cohort status for CAS requires both.
- Time-dependent columns (`*_on_effective_date`, destination from homelessness, related users, missing documents, most-recent columns) are only as fresh as the last `prepare_active_cohorts` run; they are not recomputed on view.

### System cohorts
- A system cohort exists only while its config flag is on. It is created with 90 days of inactivity and the default tabs, and the daily job rebuilds it only when system cohorts are enabled.
- Each run re-computes the previous week, because HMIS data arrives late and back-dated entries must be absorbed. For each date, the system user's changes with a known reason are deleted and the date is re-synced in one transaction, so re-processing leaves exactly one set of changes per date.
- The Currently Homeless sync waits up to ten seconds for the cohort lock. If it cannot get it, the transaction rolls back and that date is retried on the next run.
- Writers to a cohort's clients (system sync, `maintain`, cache warm) share a per-cohort advisory lock that is non-blocking by default. A writer that skips the lock can deadlock with those jobs.

### Columns and analytics
- A column's analytics value defaults to whatever it renders for a read-only viewer. A column that renders markup must override `analytics_value` with a plain-text form, or the markup is stored in the analytics table. The destination-from-homelessness column does this today; the open-enrollments column shows the correct pattern.
- Analytics are built as the system user, so PII decisions inside a column are made as that user. A new column holding direct identifiers must be added to `Cohort.excluded_from_analytics`.
- Column titles and descriptions go through translations, so installations can rename columns without code. Adding a column means adding its class, registering it in the known-columns list, adding the physical `cohort_clients` column if it is user-entered, and running `CohortColumn.maintain!`.
- `column_state` is serialized YAML with a permitted-class list. A column object that has memoized its live column record cannot be re-serialized (`RepairColumnState` strips it), so do not call `cohort_column` on objects that will be saved back into `column_state`.

### Grid page parameters
- `Cohort#default_sort_direction` must be blank, `asc` or `desc` (`Cohort.sort_directions`). A data migration reset stored values outside that set to `desc`.
- `_cohorts_js.haml` writes `sort_direction` and `population` into the page with `to_json`, so the values are JavaScript string literals. `cohorts.ts` URI-encodes `population` when it builds the grid data request.

### Access audit
The cohort access audit rebuilds who could see a cohort, and when, from PaperTrail versions. It shows structural relationships only and cannot know:
- Roles. A user listed may have held a role without `can_view_cohorts`.
- Restores. Restoring a removed cohort-to-collection link writes no version, so the audit reopens it at the row's last update time, an approximation.
- Missing timestamps. Legacy access groups lack timestamps, so a live row with no versions is treated as present since the epoch, bounded by the other paths.
- System collections. Every cohort joins the "All Cohorts" and hidden system collections after create, and those grants appear dated at the job's run time.

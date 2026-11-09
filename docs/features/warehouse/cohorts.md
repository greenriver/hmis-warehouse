---
sources:
  - app/models/grda_warehouse/cohort.rb
  - app/models/grda_warehouse/cohort_client_change.rb
  - app/models/grda_warehouse/cohort_copier.rb
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
- **Auto-Maintained Cohort:** A dynamic cohort where membership is determined by a client's enrollment in a `ProjectGroup`. Additional automation filters (Heads of Household, sub-populations, etc.) can be layered on, but only after a project group is selected. A scheduled maintenance job (`Cohort.maintain_auto_maintained!`) keeps these cohorts in sync; users with configuration access can also queue an on-demand refresh from the cohort page.
  - **System Cohort:** These are special, system-defined cohorts that are used for specific, built-in functionalities. They are not typically managed by end-users.

## Permissions & Access

Access to cohorts is controlled by permissions. For details, see the `cohort_*` roles defined in `app/models/role.rb`. Users without the necessary permissions will not see cohorts listed, even if the cohort itself is active.

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
   - `last_intentional_contacts`: JSON array of recent intentional contacts (bed nights, case management, assessments, etc.)

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
- The cached data in `WarehouseClientsProcessed` is periodically via `Cohort.prepare_active_cohorts`. So changes in service history may not immediately affect cohorts.

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
- `Cohorts::ColumnsController` loads the cohort with a plain `find`, so only `can_edit_cohort_columns` gates it, not per-cohort access. New cohort controllers should include `CohortAuthorization` and load through `cohort_scope.find`.

### Membership history
- Every membership change writes a `CohortClientChange` (create, destroy, activate, deactivate), and the change report and `associated_exit` pair entries with exits from those rows. Use `add_clients` / `remove_clients` for automated paths. Do not change membership without a change row.
- Cell edits are not written there. Column-value history lives in PaperTrail versions on `CohortClient`, and notes are separate rows.
- Copying values between cohorts affects only clients already on the destination, writes versions but no change rows, and respects the user's visible cohorts. Notes are duplicated with their original timestamps.

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

### Access audit
The cohort access audit rebuilds who could see a cohort, and when, from PaperTrail versions. It shows structural relationships only and cannot know:
- Roles. A user listed may have held a role without `can_view_cohorts`.
- Restores. Restoring a removed cohort-to-collection link writes no version, so the audit reopens it at the row's last update time, an approximation.
- Missing timestamps. Legacy access groups lack timestamps, so a live row with no versions is treated as present since the epoch, bounded by the other paths.
- System collections. Every cohort joins the "All Cohorts" and hidden system collections after create, and those grants appear dated at the job's run time.

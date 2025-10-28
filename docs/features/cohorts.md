# Cohorts

The Cohorts feature is a tool for grouping, tracking, and visualizing client data. It allows users to create custom lists of clients based on specific criteria, which can then be used for case management, reporting, and in-depth data analysis. Many communities use this feature to support By-Name-Lists or BNL.

## Key Concepts

- **Cohort:** A cohort is a dynamic list of clients. Cohorts are configurable, allowing users to define which clients are included and what data is displayed for them.

- **Types of Cohorts:**
  - **Manual Cohort:** A static list of clients that is managed manually. Users can add or remove clients as needed. This is useful for tracking specific groups of clients that don't fit into automated categories.
  - **Auto-Maintained Cohort:** A dynamic cohort where membership is determined by a client's enrollment in a `ProjectGroup`. A scheduled maintenance job (`Cohort.maintain_auto_maintained!`) keeps these cohorts in sync, so changes in enrollment may take a short time to appear unless the job is triggered manually.
  - **System Cohort:** These are special, system-defined cohorts that are used for specific, built-in functionalities. They are not typically managed by end-users.

## Permissions & Access

Access to cohorts is controlled by permissions. For details, see the `cohort_*` roles defined in `app/models/role.rb`. Users without the necessary permissions will not see cohorts listed, even if the cohort itself is active.

## Configurable Views

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

1. **Service History Foundation**: Service History generates daily `ServiceHistoryService` records for each client's enrollments (see [Service History documentation](./service_history.md))

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

For a detailed explanation of how the Service History is generated and how it impacts client activity, please see the [Service History documentation](./service_history.md).

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

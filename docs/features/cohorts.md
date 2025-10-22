# Cohorts

The Cohorts feature is a tool for grouping, tracking, and visualizing client data. It allows users to create custom lists of clients based on specific criteria, which can then be used for case management, reporting, and in-depth data analysis.

## Key Concepts

- **Cohort:** A cohort is a dynamic list of clients. Cohorts are configurable, allowing users to define which clients are included and what data is displayed for them.

- **Types of Cohorts:**
  - **Manual Cohort:** A static list of clients that is managed manually. Users can add or remove clients as needed. This is useful for tracking specific groups of clients that don't fit into automated categories.
  - **Auto-Maintained Cohort:** A dynamic cohort where membership is determined by a client's enrollment in a `ProjectGroup`. A scheduled maintenance job (`Cohort.maintain_auto_maintained!`) keeps these cohorts in sync, so changes in enrollment may take a short time to appear unless the job is triggered manually.
  - **System Cohort:** These are special, system-defined cohorts that are used for specific, built-in functionalities. They are not typically managed by end-users.

## Permissions & Access

Access to cohorts is controlled by user roles and ACL collections. Users need cohort view permissions (for example, `can_view_cohorts` or the equivalent ACL collection) to see cohorts in the UI. Editing or managing cohort membership requires the stronger cohort participation permission (`can_participate_in_cohorts`). Users without the necessary permissions will not see cohorts listed, even if the cohort itself is active.

## Configurable Views

Cohorts can be customized to tailor the view to specific needs.

- **Custom Columns:** Users can select which columns of data to display for the clients in a cohort. This can range from basic demographic information to complex calculated fields like "days homeless in the last three years."
- **Tabs:** Cohorts can have multiple tabs, each providing a different filtered view of the client list. For example, a cohort might have separate tabs for "Active Clients," "Inactive Clients," and "Recently Exited Clients."
- **Thresholds:** Users can define visual thresholds to highlight clients who meet certain criteria. For example, a row might be colored red if a client has been homeless for more than a year.

## Client Activity and Status

A client's activity status within a cohort is determined by their Service History, which provides a day-by-day record of their enrollments and services.

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

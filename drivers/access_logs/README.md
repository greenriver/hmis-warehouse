## AccessLogs

Audit reporting over who used the Warehouse, the HMIS, or CAS. Registered as the "User Access Logs"
report in the Audit group; every tab is gated by that report definition's visibility.

### Tabs

- **Recent Exports** — queues an xlsx with one sheet per system: Warehouse (`activity_logs`), CAS
  (the CAS database's `activity_logs`), and HMIS (`hmis_activity_logs`).
- **Report Usage** — visit-days per warehouse report, bucketed by `ActivityLog.warehouse_report_conditions`.
- **User Access Summary** — for a date range: users who accessed the Warehouse and users who accessed the
  HMIS (first and latest access each), and users created in the range with the access they hold today.
  Access counts read the log tables directly, so users whose grants were later revoked or who were deleted
  still appear.

### Definitions

- `User.hmis_users` — holds at least one live `Hmis::AccessControl` through a user group.
- `User.warehouse_users` — holds at least one live warehouse `AccessControl`, or a legacy role.
- HMIS dropdowns, sheets, and summary sections are hidden when `HmisEnforcement.hmis_enabled?` is false.

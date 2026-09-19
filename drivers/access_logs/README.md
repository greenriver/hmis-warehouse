## AccessLogs

Audit reporting over who used the Warehouse, the HMIS, or CAS. Registered as the "User Access Logs"
report in the Audit group; every tab is gated by that report definition's visibility.

### Tabs

- **Recent Exports** — queues an xlsx with one sheet per system: Warehouse (`activity_logs`), CAS
  (the CAS database's `activity_logs`), and HMIS (`hmis_activity_logs`).
- **Report Usage** — visit-days per warehouse report, bucketed by `ActivityLog.warehouse_report_conditions`.
- **User Access Summary** — for a date range: users who accessed the Warehouse, the HMIS, and the CAS
  (first and latest access each), users created in the range with the access they hold today, and CAS
  users created in the range. CAS accounts are separate from warehouse accounts and are listed by CAS
  name only, with no link.
  Access counts read the log tables directly, so users whose grants were later revoked or who were deleted
  still appear.

### Definitions

- `User.hmis_users` — holds at least one live `Hmis::AccessControl` through a user group.
- `User.current_or_former_hmis_users` — the above plus users whose grant or membership was removed; used for
  the export's HMIS User filter so revoked users can still be audited.
- Export rows stream from each log table in batches straight into the worksheet; every sheet stops at
  `AccessLogs::Report::EXPORT_ROW_LIMIT` rows and appends a note when truncated.
- The `hmis_activity_logs (created_at, user_id)` index is built by the `hmis_activity_log_user_summary_index`
  TaskQueue task, not a migration, so it does not appear in `db/structure.sql` until a dump from a database
  where the task has run.
- `User.warehouse_users` — holds at least one live warehouse `AccessControl`, or a legacy role.
- HMIS dropdowns, sheets, and summary sections are hidden when `HmisEnforcement.hmis_enabled?` is false;
  CAS ones when `GrdaWarehouse::Config.cas_enabled?` is false.

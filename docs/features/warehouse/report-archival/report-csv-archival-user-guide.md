# Report CSV Archival — User Guide

## Overview

CSV archival reduces database size by exporting report data to CSV files in Active Storage (S3/MinIO), then removing the database rows after a configurable grace period (default 60 days). Archived reports remain fully viewable — if a report's data is later needed, it can be restored from the CSV files.

Two separate archival systems exist in this codebase:

| System | Report types | Concern |
|---|---|---|
| **SimpleReports** | PerformanceMeasurement, SystemPathways, and other warehouse reports | `ReportArchival` |
| **HUD Reports** | SPM, APR, CAPER, CE-APR, DQ, HIC, LSA, PATH, PIT | `HudReportArchival` |

Both systems expose the same status methods and share the same grace period configuration.

---

## Automated Archival

A scheduled rake task handles archival automatically:

```bash
# Archive and purge both SimpleReports and HUD Reports (run nightly)
rails reports:csv:archive_and_purge_eligible

# Archive SimpleReports only
rails reports:csv:archive_and_purge_simple_reports

# Archive HUD Reports only
rails reports:csv:archive_and_purge_hud_reports

# Dry run — shows what would be processed without making changes
rails reports:csv:archive_and_purge_eligible[true]
```

Each task run processes at most 20 reports (oldest `completed_at` first) to limit memory and runtime. Reports within their grace period are skipped.

---

## Status Checking

All archivable reports expose the same status methods regardless of type:

```ruby
# SimpleReport example
report = PerformanceMeasurement::Report.find(123)

# HUD Report example
report = HudReports::ReportInstance.find(456)

# Is the CSV archive complete? (all expected files attached)
report.archived?        # => true / false

# Have database rows been removed?
report.purged?          # => true / false

# Has the grace period expired? (eligible for purging)
report.purge_eligible?  # => true / false

# Full status hash
report.archival_status
# => {
#   archived:           true,
#   purged:             false,
#   purge_eligible:     false,
#   archived_at:        "2025-01-15T10:30:00Z",
#   purged_at:          nil,
#   purge_eligible_at:  "2025-03-16T10:30:00Z",
#   grace_period_days:  60,
#   expected_files:     ["report_cells_csv", "spm_enrollments_csv"],
#   files:              { "report_cells_csv" => { expected: true, attached: true }, ... }
# }
```

---

## Restoring Data from CSV

When a report is purged, its database rows are gone but the CSV files remain in Active Storage. Restoring reinserts those rows so the report is fully usable again. The CSV files are kept after restore so that the next purge cycle does not require re-archiving.

### Via UI

Every HUD report show page displays a **Reload Report from Archived Data** button when the report is purged. Clicking it runs the restore service and redirects back to the report.

For SimpleReports, the same button appears when configured (see the migration guide for setup details).

### Via Service (Rails console / scripts)

**HUD Reports:**

```ruby
report = HudReports::ReportInstance.find(456)

service = HudReports::RestoreArchivedReportDataService.new(report)

# Check feasibility before restoring
service.can_restore?  # => true if archived? and all CSV files attached

result = service.restore!
# => {
#   success:          true,
#   restored_counts:  { report_cells_csv: 840, spm_enrollments_csv: 312, ... },
#   errors:           []
# }
```

**SimpleReports:**

```ruby
report = PerformanceMeasurement::Report.find(123)

service = Reports::ReloadReportFromCsvService.new(report)
service.can_reload?  # => true if archived? and files present

result = service.reload!
# => { success: true, reloaded_counts: { clients_csv: 100 }, errors: [] }
```

### Via Rake Task (SimpleReports only)

```bash
rails reports:csv:reload[123]        # reload report ID 123
rails reports:csv:reload[123,true]   # dry run
```

---

## Manually Triggering Archive + Purge

Use the `archive_and_purge!` method to immediately archive and purge a report without waiting for the nightly task:

```ruby
# HUD Report
report = HudReports::ReportInstance.find(456)
result = report.archive_and_purge!
# => { success: true, deleted_counts: { ... } }

# Force purge even if not purge_eligible? (skips grace period check)
report.archive_and_purge!(force: true)

# SimpleReport
report = PerformanceMeasurement::Report.find(123)
result = report.archive_and_purge!
```

---

## Setting a Custom Purge Date

To schedule a report for early purging (bypassing the grace period calculation):

```ruby
report.update_archival_metadata('purge_eligible_at', 7.days.from_now.iso8601)
```

The nightly task will process it once that timestamp is reached.

---

## Grace Period Configuration

The default grace period is set globally in `Reports.archival_grace_period_days` (defaults to 60 days). This applies to both SimpleReports and HUD Reports unless overridden per report via `purge_eligible_at`.

---

## Troubleshooting

### Report shows "purged" but restore fails

```ruby
report = HudReports::ReportInstance.find(456)
report.archival_status
# Inspect "files" key — any with attached: false are missing from Active Storage
```

Missing CSV files mean the archive is incomplete. The report cannot be restored without those files.

### Archive ran but CSV files are not attached

Check the `archival_metadata['files']` key for error messages per attachment:

```ruby
report.archival_metadata['files']
# => { "report_cells_csv" => { "attached" => false, "error" => "..." } }
```

Re-run archival — `archive!` is idempotent and skips already-attached files:

```ruby
HudReports::ArchiveReportService.new(report).archive!
```

### Restore inserts wrong data

Restore uses `upsert_all` with `unique_by: :id`. If rows with those IDs already exist (e.g., a partial restore was attempted), they will be overwritten. This is intentional and safe.

---

## Related Documentation

- [Migration Guide](report-csv-archival-migration-guide.md) — How to add CSV archival to new report types

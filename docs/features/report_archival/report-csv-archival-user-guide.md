# Report CSV Archival - User Guide

## Overview

CSV archival stores report data in CSV files as backups. Database data is purged after a configurable grace period (default 60 days) to reduce database size. CSV files can reload data back into the database when needed.

## How It Works

The scheduled rake task `reports:csv:archive_and_purge_eligible` automatically:
1. Finds reports where the grace period has expired (based on `completed_at` date)
2. Archives CSV files (if not already archived)
3. Purges database data

Archival eligibility is determined by the report type being in `Rails.application.config.report_archival_types`. When a report includes `ReportArchival`, the report type is automatically registered in this config array.

The rake task does not process all eligible reports in one run, but instead takes the first N (Initially set to 20) reports ordered by the oldest `completed_at` date.

## Status Checking

```ruby
report = PerformanceMeasurement::Report.find(123)

# Check if report has been archived (CSV files exist and are complete)
report.archived? # => true/false

# Check if database data has been purged
report.purged? # => true/false

# Check if grace period has expired (data eligible for purging)
report.purge_eligible? # => true/false

# Get detailed status
report.archival_status
# => {
#   archived: true,
#   purged: false,
#   purge_eligible: false,
#   archived_at: "2025-01-15T10:30:00Z",
#   purge_eligible_at: "2025-03-16T10:30:00Z",
#   purged_at: nil,
#   grace_period_days: 60,
#   complete: true,  # Same as archived?
#   expected_files: ["clients_csv", "projects_csv"],
#   files: { ... }
# }
```

## Accessing Report Data

All report data is accessed through standard ActiveRecord associations. CSV files are backups only:

```ruby
report = MyReport.find(123)

# Access associations (always from database)
items = report.items
categories = report.categories
```

## Reloading Data from CSV

If database data has been purged, reload it from CSV:

### Via Service

```ruby
service = Reports::ReloadReportFromCsvService.new(report)

# Check if reload is possible
service.can_reload? # => true/false

# Reload data
result = service.reload!
# => {
#   success: true,
#   reloaded_counts: { clients_csv: 100, projects_csv: 10 },
#   errors: []
# }
```

### Via Rake Task

```bash
# Reload a specific report
rails reports:csv:reload[123]

# Dry run (see what would be reloaded)
rails reports:csv:reload[123,true]
```

## Available Methods

### Status Methods

- **`archived?`** - Returns `true` if CSV files exist and are complete (all expected files attached)
- **`purged?`** - Returns `true` if database records have been removed
- **`purge_eligible?`** - Returns `true` if grace period has expired
- **`archival_status`** - Returns detailed hash with archival information

## Grace Period and Purging

1. **After Report Generation**: Data is archived to CSV files, but database data remains intact
2. **Grace Period**: Database data is kept for a configurable period (default 60 days)
3. **After Grace Period**: Data becomes eligible for purging via scheduled task
4. **After Purging**: Report shows as "purged" and data can be reloaded from CSV if needed

## Troubleshooting

### Data Not Available After Purge

```ruby
# Check if data is purged
report.purged? # => true means database data has been removed

# Reload data from CSV
service = Reports::ReloadReportFromCsvService.new(report)
service.reload! if service.can_reload?
```

### CSV Files Missing

```ruby
# Check if archival is complete
report.archived? # => false

# Check detailed status
report.archival_status
# Look for files with attached: false
```

## Related Documentation

- [Migration Guide](report-csv-archival-migration-guide.md) - How to add CSV archival to new report types

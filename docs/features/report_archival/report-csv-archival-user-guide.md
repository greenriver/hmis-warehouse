# Report CSV Archival - User Guide

## Overview

This guide explains how CSV archival works for reports. CSV files serve as backups that can reload data into the database when needed. Database data is purged after a configurable grace period (30-90 days) to reduce database size. All report viewing continues to use database data.

**See also:**
- [Migration Guide](report-csv-archival-migration-guide.md) - How to add CSV archival to new report types

## Quick Start

### Checking if a Report is Archived

```ruby
report = PerformanceMeasurement::Report.find(123)

# Check if report has been archived (CSV files exist and are complete)
report.archived? # => true/false

# Check if database data has been purged
report.purged? # => true/false

# Check if CSV archival is complete (all files attached)
report.archival_complete? # => true/false

# Check if grace period has expired (data eligible for purging)
report.purge_eligible? # => true/false

# Get detailed status
report.archival_status
# => {
#   archived: true,  # CSV files exist and are complete
#   purged: false,  # Database data not purged yet
#   purge_eligible: false,  # Grace period expired?
#   archived_at: "2025-01-15T10:30:00Z",
#   purge_eligible_at: "2025-03-16T10:30:00Z",  # 60 days after archived_at
#   purged_at: nil,  # Set when data is purged
#   grace_period_days: 60,
#   complete: true,
#   expected_files: ["items_csv", "categories_csv"],  # Your report's CSV attachments
#   files: {
#     items_csv: { expected: true, attached: true, file_count: 1 },
#     categories_csv: { expected: true, attached: true, file_count: 1 },
#   }
# }
```

### Accessing Report Data

All report data is accessed through database associations. CSV files are backups only:

```ruby
# Example: Replace with your actual report class and associations
report = MyReport.find(123)

# Access your report's associations (always from database)
items = report.items
# => ActiveRecord::Relation

categories = report.categories
# => ActiveRecord::Relation
```

## Reloading Data from CSV

If database data has been purged, you can reload it from CSV:

### Via Rake Task

```bash
# Reload a specific report
rails reports:csv:reload[123]

# Dry run (see what would be reloaded)
rails reports:csv:reload[123,true]
```

### Via Service

```ruby
service = Reports::ReloadReportFromCsvService.new(report)

# Check if reload is possible
service.can_reload? # => true/false

# Reload data
result = service.reload!
# => {
#   success: true,
#   reloaded_counts: { items_csv: 100, categories_csv: 10 },
#   errors: []
# }
```

### Via UI

When viewing an archived report (where data has been purged), a "Reload Data from CSV" button appears. Clicking it will reload all data and restart the grace period.

## Available Methods

### Status Checking Methods

These methods are provided by the `ReportArchival` concern:

- **`archived?`** - Returns `true` if CSV files exist and are complete
- **`purged?`** - Returns `true` if database records have been removed
- **`purge_eligible?`** - Returns `true` if grace period has expired (data eligible for purging)
- **`archival_complete?`** - Returns `true` if all expected CSV files are attached
- **`incomplete_archival?`** - Returns `true` if archival started but didn't complete
- **`missing_archival_files?`** - Returns `true` if any expected files are missing
- **`archival_status`** - Returns a detailed hash with archival information
- **`expected_archival_files`** - Returns an array of expected attachment names

### Data Access Methods

All report data is accessed through standard ActiveRecord associations. Replace these examples with your report's actual associations:

- **`report.items`** - Returns ActiveRecord::Relation (always from database)
- **`report.categories`** - Returns ActiveRecord::Relation (always from database)

**Note:** CSV files are backups only. All data viewing uses the database.

## Data Format

### Database Data Format

All report data is accessed through ActiveRecord associations:

```ruby
# Example: Your report's data structure
item = {
  id: 123,
  name: "Example Item",
  value: 456,
  # ... other fields from your model
}
```


## Common Patterns

### Iterating Over Data

```ruby
# Example: Replace with your report's associations
report.items.each do |item|
  item_id = item.id
  # Process each item
end
```

### Finding Specific Records

```ruby
# Find by ID
item = report.items.find_by(id: 123)

# Find with conditions
item = report.items.where(id: 123, active: true).first
```

### Filtering Data

```ruby
# Filter items
active_items = report.items.where(active: true)

# Filter by category
items_in_category = report.items.joins(:category).where(categories: { name: 'Example' })
```

### Aggregations

```ruby
# Count
item_count = report.items.count

# Sum
total_value = report.items.sum(:value)

# Group by
grouped = report.items.group(:category_id).count
```

### Joining Data

```ruby
# Join items with their categories
items_with_categories = report.items
  .joins(:category)
  .includes(:category)
  .distinct
```

## Grace Period and Purging

### How It Works

1. **After Report Generation**: Data is archived to CSV files, but database data remains intact
2. **Grace Period**: Database data is kept for a configurable period (default 60 days, configurable 30-90 days)
3. **After Grace Period**: Data becomes eligible for purging via scheduled task
4. **After Purging**: Report shows as "archived" and data can be reloaded from CSV if needed

### Checking Grace Period Status

```ruby
# Example: Replace with your actual report class
report = MyReport.find(123)

# Check if data is eligible for purging
report.purge_eligible? # => true/false

# Get purge eligibility date
purge_eligible_at = Time.parse(report.archival_metadata['purge_eligible_at'])
days_remaining = ((purge_eligible_at - Time.current) / 1.day).ceil
```

### Manual Purging

```bash
# Purge a specific report (if grace period expired)
rails reports:csv:purge[123]

# Purge all eligible reports
rails reports:csv:purge_eligible

# Dry run (see what would be purged)
rails reports:csv:purge_eligible[true]
```

## When Data is Purged

After the grace period expires, database data can be purged. Once purged:

- ✅ Report shows as "purged" (`purged?` returns `true`)
- ✅ Report remains "archived" (`archived?` still returns `true` - CSV files exist)
- ✅ Data can be reloaded from CSV using `ReloadReportFromCsvService`
- ✅ Reloading restarts the grace period timer
- ✅ All report viewing continues to use database data (after reload)

## Examples

### Example 1: Displaying Item Count

```ruby
def display_item_count(report)
  count = report.items.count
  puts "Total items: #{count}"
end
```

### Example 2: Finding Items by Category

```ruby
def find_items_by_category(report, category_id)
  report.items.where(category_id: category_id)
end
```

### Example 3: Calculating Average

```ruby
def calculate_average_value(report)
  report.items.average(:value) || 0
end
```

### Example 4: Grouping by Category

```ruby
def items_by_category(report)
  report.items
    .joins(:category)
    .group('categories.id')
    .includes(:category)
end
```

## Troubleshooting

### Data Not Available After Purge

If database data has been purged and you need to access it:

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
report.archival_complete? # => false

# Check which files are missing
report.missing_archival_files? # => true
report.archival_status
# Look for files with attached: false
```

### Grace Period Not Expired

If you need to purge data before grace period expires:

```ruby
# Check grace period status
report.purge_eligible? # => false if grace period not expired

# Get purge eligibility date
purge_eligible_at = Time.parse(report.archival_metadata['purge_eligible_at'])
days_remaining = ((purge_eligible_at - Time.current) / 1.day).ceil
```

## Best Practices

1. **Always use database associations** - All data viewing uses the database
2. **CSV files are backups only** - They're not used for reading, only for reloading
3. **Reload when needed** - If data is purged and you need it, reload from CSV
4. **Monitor grace period** - Check `purge_eligible_at` to know when data can be purged
5. **Test reload functionality** - Ensure CSV files can successfully reload data

## Related Documentation

- [Migration Guide](report-csv-archival-migration-guide.md) - How to add CSV archival to new report types


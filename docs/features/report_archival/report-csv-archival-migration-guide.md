# Report CSV Archival - Migration Guide

## Overview

This guide explains how to add CSV archival support to a new report type. CSV archival stores report data in CSV files via Active Storage as backups. Database data is purged after a configurable grace period (30-90 days) to reduce database size. CSV files can reload data back into the database when needed.

**See also:**
- [User Guide](report-csv-archival-user-guide.md) - How to work with archived reports

## Prerequisites

Before adding CSV archival to a report type, ensure:

1. The report model inherits from `GrdaWarehouse::SimpleReports::ReportInstance` or includes `ReportArchival`
2. The report has ActiveRecord associations for the data you want to archive
3. You understand which data should be archived (typically large datasets that are read-only after report generation)

## Step-by-Step Guide

### Step 1: Include Required Concerns

Add the `ReportArchival` concern to your report model:

```ruby
class MyReport < GrdaWarehouse::SimpleReports::ReportInstance
  include ReportArchival
  
  # ... rest of your model
end
```

### Step 2: Add Active Storage Attachments

Define Active Storage attachments for each CSV file you want to create:

```ruby
class MyReport < GrdaWarehouse::SimpleReports::ReportInstance
  include ReportArchival
  
  # Add attachments for each CSV file you want to archive
  # Example: if your report has :items and :categories associations
  has_many_attached :items_csv
  has_many_attached :categories_csv
  
  # ... rest of your model
end
```

**Note:** Use `has_many_attached` for multiple files or `has_one_attached` for single files.

### Step 3: Define `archival_csv_config`

Implement the `archival_csv_config` method to define which associations to archive. CSV files store the exact data from the database associations:

```ruby
def archival_csv_config
  report_type = self.class.name.gsub('::', '-').underscore
  {
    items_csv: {
      association: :items,
      filename: -> { "#{report_type}-items-#{id}.csv" },
    },
    categories_csv: {
      association: :categories,
      filename: -> { "#{report_type}-categories-#{id}.csv" },
    },
  }
end
```

**Note:** 
- CSV files store the exact data from the database table. All columns from the association's model are included. The CSV is used only for backup/restore - when reloaded, it restores the exact same data that was archived.
- **Best Practice:** Include the report type in filenames (e.g., `my-report-items-1.csv`) to avoid conflicts between different report types that might have the same ID.

### Step 4: Archival Happens Automatically

No additional code is needed! Archival metadata is initialized automatically when the archive service runs. The scheduled rake task `reports:csv:archive_and_purge_eligible` will:

1. Find reports where the grace period has expired (based on `completed_at` date)
2. Archive the CSV files (if not already archived)
3. Purge the database data

**Note:** 
- Archival eligibility is automatically determined by checking if the report includes the `ReportArchival` concern and has a non-empty `archival_csv_config`. No additional configuration is needed.
- The grace period is calculated from the report's `completed_at` date. No metadata initialization is required at report completion.
- CSV archival happens automatically via the scheduled rake task when the grace period expires, right before purging.

### Step 5: Add Reload Button to Views (Optional)

If you want users to be able to reload archived reports from the UI, add the reload button to your report's show view. A shared partial is available:

```haml
- if @report.purged?
  = render 'warehouse_reports/reload_archived_report', report: @report, reload_url: reload_from_csv_your_report_path(@report)
- else
  # ... your normal report content ...
```

You'll also need to:

1. **Add the route** in your report's routes file:
```ruby
resources :reports, only: [:index, :create, :show, :destroy] do
  post 'reload_from_csv', to: 'reports#reload_from_csv', as: :reload_from_csv, on: :member
end
```

2. **Add the controller action** (make sure `reload_from_csv` is included in your `before_action :set_report`):
```ruby
before_action :set_report, only: [:show, :destroy, :reload_from_csv]

def reload_from_csv
  require_can_view_any_reports!  # or appropriate permission check
  service = Reports::ReloadReportFromCsvService.new(@report)
  result = service.reload!

  if result[:success]
    flash[:notice] = "Report data reloaded successfully. #{result[:reloaded_counts].values.sum} records restored."
  else
    flash[:error] = "Failed to reload report data: #{result[:errors].join(', ')}"
  end

  redirect_to your_report_path(@report)
end
```

**Note:** The reload button will only show when `@report.purged?` returns `true`. When not purged, the normal report content is displayed.

### Step 6: Add Tests

Create tests to verify archival works correctly:

```ruby
# spec/models/my_report_spec.rb
describe 'CSV archival' do
  let(:report) { create(:my_report) }
  
  before do
    report.run_and_save!(filter)
  end
  
  it 'archives report data to CSV' do
    expect(report.archived?).to be true
    expect(report.archival_complete?).to be true
    expect(report.items_csv.attached?).to be true
  end
  
  it 'preserves database data after archival' do
    expect(report.items.count).to be > 0
    expect(report.purged?).to be false
  end
  
  it 'can reload data from CSV' do
    # After purging, reload should work
    service = Reports::ReloadReportFromCsvService.new(report)
    expect(service.can_reload?).to be true
  end
end
```

## Complete Example

Here's a complete example of adding CSV archival to a report:

```ruby
class MyReport < GrdaWarehouse::SimpleReports::ReportInstance
  include ReportArchival
  
  # Your report's associations
  has_many :items
  has_many :categories
  
  # Active Storage attachments (one per association you want to archive)
  has_many_attached :items_csv
  has_many_attached :categories_csv
  
  # Define CSV configuration
  def archival_csv_config
    report_type = self.class.name.gsub('::', '-').underscore
    {
      items_csv: {
        association: :items,
        filename: -> { "#{report_type}-items-#{id}.csv" },
      },
      categories_csv: {
        association: :categories,
        filename: -> { "#{report_type}-categories-#{id}.csv" },
      },
    }
  end
  
  def complete
    update(completed_at: Time.current)
  end
  
  def run_and_save!
    start
    begin
      # Your report generation logic here
      generate_report_data
      save!
    rescue Exception => e
      update(failed_at: Time.current)
      raise e
    end
    complete
  end
end
```

## Advanced Configuration

### Multiple CSV Files from Different Associations

You can archive multiple associations:

```ruby
def archival_csv_config
  report_type = self.class.name.gsub('::', '-').underscore
  {
    items_csv: {
      association: :items,
      filename: -> { "#{report_type}-items-#{id}.csv" },
    },
    categories_csv: {
      association: :categories,
      filename: -> { "#{report_type}-categories-#{id}.csv" },
    },
  }
end
```

**Note:** 
- CSV files store the exact data from the database table. If you need data from associated models, those relationships will still work after reload because they're based on foreign keys.
- Including the report type in filenames ensures uniqueness across different report types.

## Testing Checklist

When adding CSV archival to a new report type, verify:

- [ ] Report archives successfully after generation
- [ ] All expected CSV files are attached
- [ ] `archived?` returns `true` after archival
- [ ] `archival_complete?` returns `true` when all files attached
- [ ] CSV filenames include report type (e.g., `my-report-items-1.csv`)
- [ ] CSV data format matches database table structure exactly
- [ ] Database data is preserved after archival (grace period)
- [ ] Database data can be purged after grace period expires
- [ ] Data can be reloaded from CSV back to database
- [ ] Reports continue to work correctly after reload
- [ ] Reload button appears when report is purged (if UI added)
- [ ] Reload functionality works from UI (if UI added)

## Common Issues

### Archival Not Happening

**Problem:** Report doesn't archive when grace period expires.

**Solution:**
- Verify report includes `ReportArchival` concern
- Check that `archival_csv_config` is defined and returns a non-empty hash
- Verify report has `completed_at` set (required for grace period calculation)
- Check that the scheduled rake task `reports:csv:archive_and_purge_eligible` is running
- Verify grace period has expired (calculated from `completed_at` + grace period days)

### CSV Files Not Attached

**Problem:** Some CSV files are missing after archival.

**Solution:**
- Verify all attachments are defined with `has_many_attached` or `has_one_attached`
- Check that `archival_csv_config` includes all expected files
- Review service logs for errors during CSV generation

### Reload Fails

**Problem:** Data cannot be reloaded from CSV.

**Solution:**
- Verify CSV files are attached and accessible
- Check that `archival_complete?` returns `true`
- Review service logs for errors during reload
- Ensure all associations in `archival_csv_config` exist

## Best Practices

1. **Start Simple** - Begin with direct associations
2. **Test Thoroughly** - Test archival, purging, and reloading
3. **Verify Data Integrity** - Ensure CSV data matches database data exactly
4. **Test Reload** - Verify that reloading from CSV restores data correctly
5. **Monitor Performance** - Watch for performance impacts during archival and reload
6. **Handle Errors** - Implement proper error handling for archival failures

## Related Documentation

- [User Guide](report-csv-archival-user-guide.md) - How to work with archived reports


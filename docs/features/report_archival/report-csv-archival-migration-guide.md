# Report CSV Archival - Migration Guide

## Overview

CSV archival stores report data in CSV files via Active Storage as backups. Database data is purged after a configurable grace period (default 60 days) to reduce database size. CSV files can reload data back into the database when needed.

## Prerequisites

- Report model inherits from `GrdaWarehouse::SimpleReports::ReportInstance`
- Report has ActiveRecord associations for the data you want to archive

## Step-by-Step Guide

### Step 1: Include ReportArchival Concern

```ruby
class MyReport < GrdaWarehouse::SimpleReports::ReportInstance
  include ReportArchival
  
  # ... rest of your model
end
```

### Step 2: Add Active Storage Attachments

Define attachments for each CSV file you want to create:

```ruby
has_many_attached :items_csv
has_many_attached :categories_csv
```

### Step 3: Define archival_csv_config

Implement the `archival_csv_config` method to define which associations to archive:

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

**Note:** Include the report type in filenames to avoid conflicts between different report types.

### Step 4: Add UI Partial and Controller Action

To allow users to reload archived reports from the UI, add the reload partial to your report's show view:

**In your report show view:**

```haml
- if @report.purged?
  = render 'warehouse_reports/reload_archived_report', report: @report, reload_url: reload_from_csv_your_report_path(@report)
- else
  = render action_name
  # ... your normal report content ...
```

**Add the route:**

```ruby
resources :reports, only: [:index, :create, :show, :destroy] do
  post 'reload_from_csv', to: 'reports#reload_from_csv', as: :reload_from_csv, on: :member
end
```

**Add the controller action:**

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

The reload button will only show when `@report.purged?` returns `true`. When not purged, the normal report content is displayed.

## Related Documentation

- [User Guide](report-csv-archival-user-guide.md) - How to work with archived reports

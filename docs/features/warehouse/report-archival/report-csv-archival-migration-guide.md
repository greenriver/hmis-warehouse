# Report CSV Archival — Migration Guide

## Overview

CSV archival stores report data in CSV files via Active Storage, then removes the database rows after a configurable grace period (default 60 days). CSV files are used to restore data on demand.

Two parallel archival systems exist:

| System | Report types | Concern |
|---|---|---|
| **SimpleReports** | PerformanceMeasurement, SystemPathways, and other warehouse reports | `ReportArchival` |
| **HUD Reports** | SPM, APR, CAPER, CE-APR, DQ, HIC, LSA, PATH, PIT | `HudReportArchival` |

---

## Adding Archival to a SimpleReport

### Prerequisites

- Report model inherits from `GrdaWarehouse::SimpleReports::ReportInstance`
- Report has ActiveRecord associations for the data to archive

### Step 1: Include ReportArchival Concern

```ruby
class MyReport < GrdaWarehouse::SimpleReports::ReportInstance
  include ReportArchival

  # ... rest of your model
end
```

### Step 2: Add Active Storage Attachments

```ruby
has_many_attached :items_csv
has_many_attached :categories_csv
```

### Step 3: Define archival_csv_config

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

Include the report type in filenames to avoid conflicts between report types.

### Step 4: Add UI and Controller

**Show view:**

```haml
- if @report.purged?
  = render 'warehouse_reports/reload_archived_report', report: @report, reload_url: reload_from_csv_your_report_path(@report)
- else
  = render action_name
```

**Route:**

```ruby
resources :reports, only: [:index, :create, :show, :destroy] do
  post 'reload_from_csv', to: 'reports#reload_from_csv', as: :reload_from_csv, on: :member
end
```

**Controller action:**

```ruby
before_action :set_report, only: [:show, :destroy, :reload_from_csv]

def reload_from_csv
  require_can_view_any_reports!
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

---

## Adding Archival to a HUD Report Driver

HUD report archival works differently: a driver-level `Archival` module is included in each generator class and registers itself with `HudReportArchival`. The shared `HudReports::BaseController#restore` action and `hud_report_actions` route concern handle the UI plumbing automatically.

### Step 1: Create the Driver Archival Module

Create `drivers/hud_my_report/app/models/hud_my_report/archival.rb`:

```ruby
# Copyright (C) 2024 - present Instructure, Inc.
#
# ... license header ...

module HudMyReport
  module Archival
    extend ActiveSupport::Concern

    included do
      # Declare Active Storage attachments on ReportInstance
      HudReports::ReportInstance.class_eval do
        has_one_attached :my_report_clients_csv
        has_one_attached :my_report_living_situations_csv
      end

      # Register this generator so HudReportArchival can find it
      HudReportArchival.register_archival_generator(title, self)
    end

    class_methods do
      def archival_csv_config(report_instance)
        client_ids = HudMyReport::Fy2020::MyClient
          .where(report_instance_id: report_instance.id)
          .select(:id)

        {
          my_report_clients_csv: {
            scope: -> { HudMyReport::Fy2020::MyClient.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-my-report-#{report_instance.id}-clients.csv" },
            delete_order: 3,
          },
          my_report_living_situations_csv: {
            scope: -> { HudMyReport::Fy2020::MyLivingSituation.where(my_client_id: client_ids) },
            filename: -> { "hud-my-report-#{report_instance.id}-living-situations.csv" },
            delete_order: 2,
          },
          report_cells_csv: {
            scope: -> { HudReports::ReportCell.where(report_instance_id: report_instance.id) },
            filename: -> { "hud-my-report-#{report_instance.id}-report-cells.csv" },
            delete_order: 99,
          },
        }
      end
    end
  end
end
```

**Key rules for `archival_csv_config`:**

- `scope:` — a lambda returning an ActiveRecord relation (not an array). Evaluated at archive/purge time.
- `filename:` — a lambda returning a unique string. Include the report type and `report_instance.id`.
- `delete_order:` — integer controlling deletion sequence. Lower numbers are deleted first. Child rows with FK dependencies on parent rows go first. `report_cells_csv` must always be `99` (deleted last because `universe_members` reference it).
- The config is a **class method** receiving `report_instance` as an argument (unlike SimpleReports, which uses an instance method on the report itself).

### Step 2: Include Archival in Each Generator

In each generator class for the driver, include `HudMyReport::Archival` immediately after `generic_title` is defined:

```ruby
module HudMyReport
  module Generators
    module Fy2020
      class Generator < ::HudReports::GeneratorBase
        def self.generic_title
          'My HUD Report'
        end

        include HudMyReport::Archival

        def self.fiscal_year
          'FY2020'
        end

        # ... rest of generator
      end
    end
  end
end
```

`include` must come **after** `generic_title` is defined because the `included` block calls `title` (which combines `generic_title` and `fiscal_year`) to register the generator.

If the driver has multiple fiscal year generators sharing the same models, all can include the same `Archival` module — the `included` block registers each under its own `title`.

#### Special case: generators with per-FY model classes

If each FY generator uses a different model class (e.g., `HudMyReport::Fy2020::SummaryResult` vs `HudMyReport::Fy2023::SummaryResult`), override `archival_csv_config` in each generator:

```ruby
def self.archival_csv_config(report_instance)
  super(report_instance).merge(
    my_report_fy_specific_csv: {
      scope: -> { HudMyReport::Fy2023::SummaryResult.where(hud_report_instance_id: report_instance.id) },
      filename: -> { "hud-my-report-fy2023-#{report_instance.id}-summary.csv" },
      delete_order: 2,
    },
  )
end
```

Or define `archival_csv_config` to raise `NotImplementedError` in the concern and implement it fully in each generator — see `hud_lsa/archival.rb` for this pattern.

### Step 3: Add the Restore Route

If the driver's routes already use the `hud_report_actions` concern from `lib/hud_reports/route_concerns.rb`, the `post :restore` route is already included. Verify with:

```ruby
# drivers/hud_my_report/config/routes.rb
concern :hud_report_actions  # check this is present
```

If the driver defines its own routes without the concern, add `post :restore, on: :member` explicitly:

```ruby
resources :my_reports do
  get  :running,   on: :collection
  get  :history,   on: :collection
  get  :download,  on: :member
  post :restore,   on: :member
end
```

### Step 4: Add :restore to Controller before_action

Add `:restore` to the `set_report` before_action in the driver's controller:

```ruby
before_action :set_report, only: [:show, :destroy, :running, :download, :restore]
```

The `restore` action itself is inherited from `HudReports::BaseController` — no additional implementation needed.

### Step 5: Add the Restore UI to the Show View

#### Option A: Driver uses the shared partial

If the driver's show view renders the shared partial:

```haml
= render 'hud_reports/show'
```

No change needed — the restore block is already in `app/views/hud_reports/_show.haml`.

#### Option B: Driver has a custom show view

Add the restore block at the top of the content area:

```haml
- if @report&.purged?
  .well
    %p The report data has been archived and purged from the database.
    = form_with url: { action: :restore, id: @report.id }, method: :post, local: true do |f|
      = f.submit 'Reload Report from Archived Data', class: 'btn btn-primary'
- elsif @show_recent
  .well
    = render 'questions'
```

Use `@report&.purged?` (safe navigation) if `@report` can be nil in your controller; use `@report.purged?` if it is always set.

### Step 6: Write Specs

Mirror the pattern in `spec/models/hud_spm_report/archival_spec.rb`:

```ruby
# spec/models/hud_my_report/archival_spec.rb

RSpec.describe HudMyReport::Archival do
  let(:report_instance) { create(:hud_report_instance) }

  let(:generators) do
    [
      HudMyReport::Generators::Fy2020::Generator,
      HudMyReport::Generators::Fy2023::Generator,
    ]
  end

  before(:all) do
    # Force autoload so the included block fires and attachments/registrations occur
    generators.each { |g| _ = g }
  end

  describe 'attachment declarations' do
    it 'declares my_report_clients_csv on ReportInstance' do
      expect(HudReports::ReportInstance.new).to respond_to(:my_report_clients_csv)
    end
  end

  describe 'generator registration' do
    it 'registers every generator in HudReportArchival' do
      generators.each do |gen|
        expect(HudReportArchival.generator_registry[gen.title]).to eq(gen)
      end
    end
  end

  describe 'archival_csv_config' do
    it 'includes report_cells_csv in every generator config' do
      generators.each do |gen|
        expect(gen.archival_csv_config(report_instance)).to have_key(:report_cells_csv)
      end
    end

    it 'sets report_cells_csv delete_order to 99' do
      generators.each do |gen|
        expect(gen.archival_csv_config(report_instance)[:report_cells_csv][:delete_order]).to eq(99)
      end
    end

    it 'returns valid entry shapes' do
      generators.each do |gen|
        gen.archival_csv_config(report_instance).each do |key, entry|
          expect(entry).to include(:scope, :filename, :delete_order), "#{gen}.archival_csv_config[:#{key}] missing keys"
          expect(entry[:scope]).to be_a(Proc)
          expect(entry[:filename]).to be_a(Proc)
          expect(entry[:delete_order]).to be_an(Integer)
        end
      end
    end
  end
end
```

---

## Related Documentation

- [User Guide](report-csv-archival-user-guide.md) — How to work with archived reports

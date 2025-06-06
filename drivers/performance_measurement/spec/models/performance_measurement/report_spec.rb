###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMeasurement::Report, type: :model do
  before(:all) do
    setup(default_setup_path)
  end

  after(:all) do
    cleanup
  end

  describe 'smoke tests' do
    before(:all) do
      run!(default_filter)
    end

    it 'generates expected client records' do
      expect(PerformanceMeasurement::Client.count).to eq(5)
    end

    it 'finds expected people in seen throughout the year section' do
      report = report_class.last
      key = :count_of_homeless_clients_in_range
      result = report.result_for(key)
      expect(result.primary_value).to eq(5)
    end

    describe 'when investigating by race ' do
      equity_filters = {
        metric: 'count_of_homeless_clients_in_range',
        investigate_by: 'Race',
        age: [''],
        gender: [''],
        household_type: [''],
        race: [''],
        ethnicity: [''],
        project: [''],
        project_type: [''],
        view_data_by: 'count',
      }
      it 'finds expected categories' do
        report = report_class.last
        analysis_builder = PerformanceMeasurement::EquityAnalysis::Builder.new(equity_filters, report, User.system_user)
        expect(analysis_builder.chart_data.dig(:data, :columns)).to include(
          [
            'x',
            'American Indian, Alaska Native, or Indigenous',
            'Asian or Asian American',
            'Black, African American, or African',
            'Middle Eastern or North African',
            'Native Hawaiian or Pacific Islander',
            'White',
            'Doesn\'t know, prefers not to answer, or not collected',
          ],
        )
      end

      it 'finds two clients in the BlackAfAmerican category for the current period' do
        report = report_class.last
        analysis_builder = PerformanceMeasurement::EquityAnalysis::Builder.new(equity_filters, report, User.system_user)
        expect(analysis_builder.chart_data.dig(:data, :columns)).to include(['Current Period - Current Filters', 0, 2, 2, 0, 0, 0, 1])
      end
    end

    describe 'when investigating by race limited to BlackAfAmerican' do
      equity_filters = {
        metric: 'count_of_homeless_clients_in_range',
        investigate_by: 'Race',
        age: [''],
        gender: [''],
        household_type: [''],
        race: ['', 'BlackAfAmerican'],
        ethnicity: [''],
        project: [''],
        project_type: [''],
        view_data_by: 'count',
      }
      it 'finds expected categories' do
        report = report_class.last
        analysis_builder = PerformanceMeasurement::EquityAnalysis::Builder.new(equity_filters, report, User.system_user)
        # categories are limited since we specified a single race in the filter
        expect(analysis_builder.chart_data.dig(:data, :columns)).to include(
          [
            'x',
            'Black, African American, or African',
          ],
        )
      end

      it 'finds expected clients for the current period' do
        # 2 Asian, 2 Black, 1 PNA
        report = report_class.last
        analysis_builder = PerformanceMeasurement::EquityAnalysis::Builder.new(equity_filters, report, User.system_user)
        expect(analysis_builder.chart_data.dig(:data, :columns)).to include(['Current Period - Current Filters', 2])
      end
    end

    describe 'when investigating by Race and Ethnicity Combinations limited to BlackAfAmerican' do
      equity_filters = {
        metric: 'count_of_homeless_clients_in_range',
        investigate_by: 'Race and Ethnicity Combinations',
        age: [''],
        gender: [''],
        household_type: [''],
        race: ['', 'BlackAfAmerican'],
        ethnicity: [''],
        project: [''],
        project_type: [''],
        view_data_by: 'count',
      }
      it 'finds expected categories' do
        report = report_class.last
        analysis_builder = PerformanceMeasurement::EquityAnalysis::Builder.new(equity_filters, report, User.system_user)
        # NOTE: categories aren't limited because we don't have filtering by race/ethnicity combinations
        expect(analysis_builder.chart_data.dig(:data, :columns)).to include(
          [
            'x',
            'American Indian, Alaska Native, or Indigenous (only)',
            'American Indian, Alaska Native, or Indigenous & Hispanic/Latina/e/o',
            'Asian or Asian American (only)',
            'Asian or Asian American & Hispanic/Latina/e/o',
            'Black, African American, or African (only)',
            'Black, African American, or African & Hispanic/Latina/e/o',
            'Hispanic/Latina/e/o (only)',
            'Middle Eastern or North African (only)',
            'Middle Eastern or North African & Hispanic/Latina/e/o',
            'Native Hawaiian or Pacific Islander (only)',
            'Native Hawaiian or Pacific Islander & Hispanic/Latina/e/o',
            'White (only)',
            'White & Hispanic/Latina/e/o',
            'Multi-racial (all other)',
            'Multi-racial & Hispanic/Latina/e/o',
            'Unknown (Missing, Prefers not to answer, Unknown)',
          ],
        )
      end

      it 'finds expected clients for the current period' do
        report = report_class.last
        analysis_builder = PerformanceMeasurement::EquityAnalysis::Builder.new(equity_filters, report, User.system_user)
        # 1 Black & hispanic, 1 Multi-racial (only)
        expect(analysis_builder.chart_data.dig(:data, :columns)).to include(['Current Period - Current Filters', 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0])
      end
    end
  end

  describe 'inventory date range scenarios' do
    describe 'when inventory starts and ends 2 months into and before the report period' do
      before(:each) do
        # Adjust the inventory to start and end 2 months into and before the report period
        GrdaWarehouse::Hud::Inventory.update_all(InventoryStartDate: '2022-03-01', InventoryEndDate: '2022-10-31')
      end

      it 'calculates average daily inventory correctly for truncated range' do
        run!(default_filter)
        range = Filters::DateRange.new(start: Date.parse('2022-01-01'), end: Date.parse('2022-12-31'))

        # Should average the number of beds over the number of days in the range
        expected_days = (Date.parse('2022-10-31') - Date.parse('2022-03-01')).to_i
        # Two inventory records with 5 beds each calculated individually and added together
        expected_average = (expected_days.to_f * 5 / range.length).round * 2

        actual_average = GrdaWarehouse::Hud::Inventory.all.map { |i| i.average_daily_inventory(range: range, field: :BedInventory) }.sum
        expect(actual_average).to eq(expected_average)
      end

      it 'calculates bed utilization correctly in the report' do
        run!(default_filter)
        report = report_class.last

        # Get the ES bed utilization result
        result = report.result_for(:es_average_bed_utilization)

        # Calculate expected utilization:
        # - 2 inventory records with 5 beds each (10 beds total) active for ~8 months (245 days * 10 beds = 2,450 bed-days)
        # - 5 clients stayed the entire year (5 * 365 = 1,825 days)
        # - Utilization = 1,825 bed-days / 245 inventory days = 7.4 people per day
        expected_utilization = (7.4 / 10) * 100
        expect(result.primary_value).to be_within(0.1).of(expected_utilization)
      end
    end

    describe 'when inventory starts and ends after the report period' do
      before(:each) do
        GrdaWarehouse::Hud::Inventory.update_all(InventoryStartDate: '2023-01-01', InventoryEndDate: '2023-12-31')
      end

      it 'finds no inventory' do
        run!(default_filter)
        range = Filters::DateRange.new(start: Date.parse('2022-01-01'), end: Date.parse('2022-12-31'))

        actual_average = GrdaWarehouse::Hud::Inventory.all.map { |i| i.average_daily_inventory(range: range, field: :BedInventory) }&.sum
        expect(actual_average).to eq(0)
      end
    end

    describe 'when inventory ends before the report period start' do
      before(:each) do
        GrdaWarehouse::Hud::Inventory.update_all(InventoryStartDate: '2023-01-01', InventoryEndDate: '2023-12-31')
      end

      it 'finds no inventory' do
        run!(default_filter)
        range = Filters::DateRange.new(start: Date.parse('2021-01-01'), end: Date.parse('2021-12-31'))

        actual_average = GrdaWarehouse::Hud::Inventory.all.map { |i| i.average_daily_inventory(range: range, field: :BedInventory) }.sum
        expect(actual_average).to eq(0)
      end
    end

    describe 'when inventory has no end date and overlaps the report period' do
      before(:each) do
        GrdaWarehouse::Hud::Inventory.update_all(InventoryStartDate: '2022-06-01', InventoryEndDate: nil)
      end

      it 'finds expected inventory' do
        run!(default_filter)
        range = Filters::DateRange.new(start: Date.parse('2022-01-01'), end: Date.parse('2022-12-31'))

        expected_days = (Date.parse('2022-12-31') - Date.parse('2022-06-01')).to_i
        expected_average = (expected_days.to_f * 10 / range.length).round
        actual_average = GrdaWarehouse::Hud::Inventory.all.map { |i| i.average_daily_inventory(range: range, field: :BedInventory) }.sum
        expect(actual_average).to eq(expected_average)
      end
    end

    describe 'when testing inventory data by day' do
      let(:project) { GrdaWarehouse::Hud::Project.find_by(ProjectID: 'P-1') }
      let(:inventory) do
        create(
          :hud_inventory,
          ProjectID: project.ProjectID,
          data_source_id: project.data_source_id,
          InventoryStartDate: '2022-05-15',
          InventoryEndDate: '2022-09-15',
          BedInventory: 8,
        )
      end
      let(:range) { Filters::DateRange.new(start: Date.parse('2022-01-01'), end: Date.parse('2022-12-31')) }

      it 'calculates inventory correctly using average_daily_inventory' do
        # Range from inventory start to end (123 days)
        expected_days = (Date.parse('2022-09-15') - Date.parse('2022-05-15')).to_i
        # Average should be (123 days with 8 beds) / 365 days in year = 2.7 beds per day for the year
        expected_average = (expected_days.to_f * 8 / range.length).round

        actual_average = inventory.average_daily_inventory(range: range, field: :BedInventory)
        expect(actual_average).to eq(expected_average)
      end

      it 'returns correct daily inventory data using inventory_by_date' do
        daily_data = inventory.inventory_by_date(range: range, field: :BedInventory)

        # Should have data for each day in range
        expect(daily_data.keys.min).to eq(Date.parse('2022-05-15'))
        expect(daily_data.keys.max).to eq(Date.parse('2022-09-15'))
        expect(daily_data.keys.count).to eq((Date.parse('2022-09-15') - Date.parse('2022-05-15')).to_i + 1)

        # All days should have 8 beds
        expect(daily_data.values.uniq).to eq([8])
      end
    end

    describe 'when testing add_capacities' do
      # The project already has one inventory record from the import, we'll update it and add a second
      let(:project) { GrdaWarehouse::Hud::Project.find_by(ProjectID: 'P-1') }
      let!(:removed_inventories) { GrdaWarehouse::Hud::Inventory.where(ProjectID: project.ProjectID).delete_all }
      let!(:inventory) do
        create(
          :hud_inventory,
          InventoryID: 'P-1-I-1',
          ProjectID: project.ProjectID,
          CoCCode: 'XX-501',
          data_source_id: project.data_source_id,
          InventoryStartDate: '2022-01-01',
          InventoryEndDate: '2022-06-30',
          BedInventory: 5,
        )
      end

      # Add a second inventory record to the project
      let!(:inventory2) do
        create(
          :hud_inventory,
          InventoryID: 'P-1-I-2',
          ProjectID: project.ProjectID,
          CoCCode: 'XX-501',
          data_source_id: project.data_source_id,
          InventoryStartDate: '2022-07-01',
          InventoryEndDate: '2022-12-31',
          BedInventory: 10,
        )
      end

      it 'correctly calculates average bed capacity for a project with changing inventory' do
        run!(default_filter)
        report = report_class.last
        # Find the corresponding performance measurement project
        pm_project = PerformanceMeasurement::Project.find_by(project_id: project.id, report_id: report.id)

        # Verify the average bed capacity was calculated correctly
        # First half year: 5 beds for 183 days (Jan 1 - Jun 30)
        # Second half year: 10 beds for 183 days (Jul 1 - Dec 31)
        # Total days in year: 365
        # Average: ((5 * 183) + (10 * 183)) / 365 = 7.5, which rounds to 8
        expect(pm_project.reporting_ave_bed_capacity_per_night).to eq(8)
      end

      describe 'correctly handles inventory ranges that extend beyond the report period' do
        # Create a new inventory that extends beyond the report period
        let!(:inventory3) do
          create(
            :hud_inventory,
            InventoryID: 'P-1-I-3',
            ProjectID: project.ProjectID,
            CoCCode: 'XX-501',
            data_source_id: project.data_source_id,
            InventoryStartDate: '2022-11-01',
            InventoryEndDate: '2023-03-31', # Extends beyond report period
            BedInventory: 15,
          )
        end
        it 'correctly calculates average bed capacity' do
          run!(default_filter)
          report = report_class.last
          pm_project = PerformanceMeasurement::Project.find_by(project_id: project.id, report_id: report.id)

          # Expected calculation:
          # First half year: 5 beds for 183 days (Jan 1 - Jun 30)
          # Second half year: 10 beds for 122 days (Jul 1 - Oct 31)
          # Third half year: 10 + 15 = 25 beds for 60 days(Nov 1 - Dec 31)
          # Average: ((5 * 183) + (10 * 122) + (25 * 60)) / 365 = 10.0, which rounds to 10
          expect(pm_project.reporting_ave_bed_capacity_per_night).to eq(10)
        end
      end

      describe 'correctly handles days with zero inventory' do
        # Delete all inventories
        let!(:removed_inventories) { GrdaWarehouse::Hud::Inventory.where(ProjectID: project.ProjectID).delete_all }

        # Create an inventory with a gap
        let!(:inventory4) do
          create(
            :hud_inventory,
            ProjectID: project.ProjectID,
            data_source_id: project.data_source_id,
            InventoryStartDate: '2022-01-01',
            InventoryEndDate: '2022-03-31',
            BedInventory: 8,
          )

          let!(:inventory5) do
            create(
              :hud_inventory,
              ProjectID: project.ProjectID,
              data_source_id: project.data_source_id,
              InventoryStartDate: '2022-08-01',
              InventoryEndDate: '2022-12-31',
              BedInventory: 12,
            )
          end

          it 'correctly calculates average bed capacity' do
            run!(default_filter)
            report = report_class.last
            pm_project = PerformanceMeasurement::Project.find_by(project_id: project.id, report_id: report.id)

            # Expected calculation:
            # Jan 1 - Mar 31: 8 beds (90 days)
            # Apr 1 - Jul 31: 0 beds (122 days) - These days should be EXCLUDED from the average
            # Aug 1 - Dec 31: 12 beds (153 days)
            # Total days with inventory: 90 + 153 = 243 days
            # Average: ((8 * 90) + (12 * 153)) / 243 = 10.5, which rounds to 11
            expect(pm_project.reporting_ave_bed_capacity_per_night).to eq(11)
          end
        end
      end
    end
  end

  def default_setup_path
    'drivers/performance_measurement/spec/fixtures/files/default'
  end

  def default_filter
    {
      start: Date.parse('2022-01-01'),
      end: Date.parse('2022-12-31'),
      project_type_codes: HudUtility2024.residential_project_type_numbers_by_code.keys,
      coc_codes: ['XX-501'],
      coc_code: 'XX-501',
    }
  end

  def report_class
    PerformanceMeasurement::Report
  end

  def run!(filter)
    PerformanceMeasurement::Goal.ensure_default
    report = report_class.new(
      user_id: User.system_user.id,
    )
    report.filter = filter
    report.save
    report.update_goal_configuration!
    report.run_and_save!

    # PerformanceMeasurement::Report.create!(user_id: User.system_user.id, filter: filter).run_and_save!
  end

  def setup(file_path)
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
    import_hmis_csv_fixture(file_path, version: 'AutoMigrate', skip_location_cleanup: true)
  end

  def cleanup
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end
end

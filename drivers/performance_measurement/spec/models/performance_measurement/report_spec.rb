###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

  def default_setup_path
    'drivers/performance_measurement/spec/fixtures/files/default'
  end

  def default_filter
    {
      start: Date.parse('2022-01-01'),
      end: Date.parse('2022-12-31'),
      project_type_codes: HudUtility2024.residential_project_type_numbers_by_code.keys,
      coc_codes: ['XX-501'],
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
    # We don't need to do anything here currently
  end
end

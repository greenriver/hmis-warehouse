###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe PublicReports::Report, type: :request do
  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  let(:user) { create :user }
  let(:option_lengths) do
    {
      options_3y: {
        start: Date.parse('2021-01-01'),
        end: Date.parse('2024-01-01'),
      },
      options_1y: {
        start: Date.parse('2021-01-01'),
        end: Date.parse('2022-01-01'),
      },
      options_1m_jan: {
        start: Date.parse('2021-01-01'),
        end: Date.parse('2021-01-31'),
      },
      options_1m_may: {
        start: Date.parse('2021-05-01'),
        end: Date.parse('2021-05-31'),
      },
    }
  end

  describe 'smoke tests' do
    before(:each) do
      sign_in user
    end
    let(:public_reports) do
      {
        homeless_count_comparison: PublicReports::HomelessCountComparison,
        homeless_count: PublicReports::HomelessCount,
        homeless_population: PublicReports::HomelessPopulation,
        number_housed: PublicReports::NumberHoused,
        pit_by_month: PublicReports::PitByMonth,
        point_in_time: PublicReports::PointInTime,
        state_level_homelessness: PublicReports::StateLevelHomelessness,
      }
    end

    it 'public reports can build and run with 3 year filter' do
      public_reports.values.each do |report_source|
        run_report(
          report_source: report_source,
          options: get_report_options(options_type: :options_3y),
        )
        expect(report_source.all.count).to eq(1)
      end
    end

    it 'public reports can build and run with 1 year filter' do
      public_reports.values.each do |report_source|
        run_report(
          report_source: report_source,
          options: get_report_options(options_type: :options_1y),
        )
        expect(report_source.all.count).to eq(1)
      end
    end

    it 'public reports can build and run with 1 month (including January PIT date) filter' do
      public_reports.except(:state_level_homelessness).values.each do |report_source|
        run_report(
          report_source: report_source,
          options: get_report_options(options_type: :options_1m_jan),
        )
        expect(report_source.all.count).to eq(1)
      end
    end

    it 'public reports fail to build and run with 1 month span (including January PIT date) filter' do
      expect do
        run_report(
          report_source: public_reports[:state_level_homelessness],
          options: get_report_options(options_type: :options_1m_jan),
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'public reports can build and run with 1 month (not including a PIT date) filter' do
      public_reports.except(:state_level_homelessness).values.each do |report_source|
        run_report(
          report_source: report_source,
          options: get_report_options(options_type: :options_1m_may),
        )
        expect(report_source.all.count).to eq(1)
      end
    end

    it 'public reports fail to build and run with 1 month span (not including a PIT date) filter' do
      expect do
        run_report(
          report_source: public_reports[:state_level_homelessness],
          options: get_report_options(options_type: :options_1m_may),
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    def get_report_options(options_type:)
      params = { enforce_one_year_range: false }.merge(option_lengths[options_type])
      filter = ::Filters::FilterBase.new(user_id: user.id).update(params)
      {
        start_date: filter.start,
        end_date: filter.end,
        filter: filter.for_params,
        user_id: user.id,
      }
    end

    def run_report(report_source:, options:)
      report = report_source.new(options)

      report.save!
      ::WarehouseReports::GenericReportJob.perform_now(
        user_id: user.id,
        report_class: report.class.name,
        report_id: report.id,
      )
    end
  end
end

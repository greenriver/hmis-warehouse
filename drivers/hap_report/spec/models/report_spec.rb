###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HapReport::Report, type: :model do
  describe 'with all projects' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      import_hmis_csv_fixture(
        'drivers/hap_report/spec/fixtures/files/fy2020/default',
        version: '2020',
        run_jobs: true,
      )
      @report = HapReport::Report.create!(
        options: {
          start: '2019-01-01'.to_date,
          end: '2019-12-31'.to_date,
          project_ids: GrdaWarehouse::Hud::Project.pluck(:id),
        },
      )
      @report.run_and_save!
    end

    it 'finds households with children' do
      expect(value(:head_of_households_with_children, :total)).to eq(2)
    end

    it 'finds households without children' do
      expect(value(:head_of_adult_only_households, :total)).to eq(5)
    end

    it 'finds adult es clients' do
      expect(value(:adults_served, :emergency_shelter)).to eq(6)
    end

    it 'all adult clients are es' do
      expect(value(:adults_served, :total)).to eq(6)
    end

    it 'counts all clients' do
      expect(value(:total_clients_served, :total)).to eq(9)
    end
  end

  describe 'with just NBN projects' do
    before(:all) do
      import_hmis_csv_fixture(
        'drivers/hap_report/spec/fixtures/files/fy2020/default',
        version: '2020',
        run_jobs: true,
      )
      @report = HapReport::Report.create!(
        options: {
          start: '2019-01-01'.to_date,
          end: '2019-12-31'.to_date,
          project_ids: GrdaWarehouse::Hud::Project.night_by_night.pluck(:id),
        },
      )
      @report.run_and_save!
    end

    it 'sees only one night' do
      expect(value(:total_units_of_shelter_service, :emergency_shelter)).to eq(1)
    end
  end

  def value(row, column)
    @report.cell("#{row}_#{column}").summary
  end
end

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  before(:all) do
    cleanup_test_environment
    setup_data

    @projects.map { |m| m.update(ProjectType: 1, act_as_project_type: 13, computed_project_type: 13) }
    @project_cocs.map { |m| m.update(CoCCode: 'XX-500', Zip: '11111') }
    @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [@projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: @user.id,
    )
    @exporter.export!(cleanup: false, zip: false, upload: false)

    @zip = '05301'
    GrdaWarehouse::Hud::ProjectCoc.update_all(zip_override: @zip)
    @second_exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [@projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: @user.id,
    )
    @second_exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files
    @second_exporter.remove_export_files
    cleanup_test_environment
  end

  describe 'When exporting' do
    describe 'Project CoC records' do
      it 'adds one row to the ProjectCoC CSV file' do
        csv = CSV.read(csv_file_path(@project_coc_class), headers: true)
        expect(csv.count).to eq 1
      end
      it 'Zip from CSV file matches the first ProjectCoC Zip' do
        csv = CSV.read(csv_file_path(@project_coc_class), headers: true)
        expect(csv.first['Zip']).to eq @project_cocs.first.Zip
      end
    end

    describe 'when override is present' do
      it 'adds one row to the ProjectCoC CSV file' do
        csv = CSV.read(csv_file_path(@project_coc_class, exporter: @second_exporter), headers: true)
        expect(csv.count).to eq 1
      end
      it 'Zip from CSV file matches the first ProjectCoC zip_override' do
        csv = CSV.read(csv_file_path(@project_coc_class, exporter: @second_exporter), headers: true)
        expect(csv.first['Zip']).to eq @zip
      end
    end
  end
end

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
    @projects = create_list :hud_project, 6, data_source_id: @data_source.id, ProjectType: 1, ContinuumProject: 0, hud_continuum_funded: nil
    @projects[0].update(ContinuumProject: 0, hud_continuum_funded: nil)
    @projects[1].update(ContinuumProject: 0, hud_continuum_funded: true)
    @projects[2].update(ContinuumProject: 0, hud_continuum_funded: false)
    @projects[3].update(ContinuumProject: 1, hud_continuum_funded: nil)
    @projects[4].update(ContinuumProject: 1, hud_continuum_funded: true)
    @projects[5].update(ContinuumProject: 1, hud_continuum_funded: false)
    @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: @projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: @user.id,
    )
    @exporter.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files
    cleanup_test_environment
  end

  describe 'when exporting projects' do
    it 'creates a CSV file' do
      expect(File.exist?(csv_file_path(@project_class))).to be true
    end
    it 'adds 5 rows to the project CSV file' do
      csv = CSV.read(csv_file_path(@project_class), headers: true)
      expect(csv.count).to eq 6
    end
    it 'no override for 2 projects' do
      expect(@projects.select { |m| m.hud_continuum_funded.nil? }.count).to eq 2
    end
    it 'true override for 2 projects' do
      expect(@projects.select { |m| m.hud_continuum_funded == true }.count).to eq 2
    end
    it 'false override for 2 projects' do
      expect(@projects.select { |m| m.hud_continuum_funded == false }.count).to eq 2
    end
    it 'exported file to have 3 ContinuumProject: 0' do
      csv = CSV.read(csv_file_path(@project_class), headers: true)
      zeros = csv.select do |row|
        row['ContinuumProject'] == '0'
      end
      expect(zeros.count).to eq 3
    end
    it 'exported file to have 3 ContinuumProject: 0' do
      csv = CSV.read(csv_file_path(@project_class), headers: true)
      ones = csv.select do |row|
        row['ContinuumProject'] == '1'
      end
      expect(ones.count).to eq 3
    end
  end
end

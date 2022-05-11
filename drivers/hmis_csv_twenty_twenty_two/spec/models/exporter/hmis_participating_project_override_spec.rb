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

    @projects.map { |m| m.update(ProjectType: 1, HMISParticipatingProject: 1, hmis_participating_project_override: 0) }
    @project = @projects.first
    @project.update(HMISParticipatingProject: nil)
    @project.update(hmis_participating_project_override: 0)
    @project_2 = @projects.second
    @project_2.update(HMISParticipatingProject: 1)
    @project_2.update(hmis_participating_project_override: nil)
    @project_3 = @projects.third
    @project_3.update(HMISParticipatingProject: nil)
    @project_3.update(hmis_participating_project_override: nil)

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

  describe 'When exporting projects' do
    it 'creates one project CSV file' do
      expect(File.exist?(csv_file_path(@project_class))).to be true
    end
    it 'a ProjectID from CSV file matches the id of first project' do
      csv = CSV.read(csv_file_path(@project_class), headers: true)
      project = csv.detect { |p| p['ProjectID'] == @project.id.to_s }
      expect(project['ProjectID']).to eq @projects.first.id.to_s
    end
    it 'HMISParticipatingProject in project does not equal override' do
      expect(@project.HMISParticipatingProject).not_to eq @project.hmis_participating_project_override
    end
    it 'HMIS Participating Project override is a 0' do
      expect(@project.hmis_participating_project_override).to eq(0)
    end
    it 'exported value matches the override' do
      csv = CSV.read(csv_file_path(@project_class), headers: true)
      project = csv.detect { |p| p['ProjectID'] == @project.id.to_s }
      expect(project['HMISParticipatingProject']).to eq @project.hmis_participating_project_override.to_s
    end
    it 'sets second HMISParticipatingProject in the export file when override is blank' do
      csv = CSV.read(csv_file_path(@project_class), headers: true)
      project = csv.detect { |p| p['ProjectID'] == @project_2.id.to_s }
      aggregate_failures 'checking exported project' do
        expect(project['HMISParticipatingProject']).to_not be_empty
        expect(project['HMISParticipatingProject']).to eq '1'
      end
    end
    it 'when HMISParticipatingProject and override are blank it sets HMISParticipatingProject in the export file' do
      csv = CSV.read(csv_file_path(@project_class), headers: true)
      aggregate_failures 'checking exported project' do
        project = csv.detect { |p| p['ProjectID'] == @project_3.id.to_s }
        expect(project['HMISParticipatingProject']).to_not be_empty
        expect(project['HMISParticipatingProject']).to eq('99')
      end
    end
  end
end

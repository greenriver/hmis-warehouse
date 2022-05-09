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
    @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: [@projects.first.id],
      period_type: 3,
      directive: 3,
      user_id: @user.id,
    )
    @exporter.export!(cleanup: false, zip: false, upload: false)

    @project = @projects.first
    @project.update(ProjectType: 13)
    @project.update(computed_project_type: 1)
    @project_es = @projects.second
    @project_es.update(computed_project_type: 1)
    @project_es.update(TrackingMethod: 3)
    @project_ph = @projects.third
    @project_ph.update(ProjectType: 1)
    @project_ph.update(computed_project_type: 13)

    @exporter_2 = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
      start_date: 1.week.ago.to_date,
      end_date: Date.current,
      projects: @projects.map(&:id),
      period_type: 3,
      directive: 3,
      user_id: @user.id,
    )
    @exporter_2.export!(cleanup: false, zip: false, upload: false)
  end

  after(:all) do
    @exporter.remove_export_files
    @exporter_2.remove_export_files
    cleanup_test_environment
  end

  describe 'when exporting' do
    it 'enrollment scope should find one enrollment' do
      expect(@exporter.enrollment_scope.count).to eq 1
    end
    it 'creates one CSV file' do
      expect(File.exist?(csv_file_path(@enrollment_class))).to be true
    end
    it 'adds one row to the enrollment CSV file' do
      csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
      expect(csv.count).to eq 1
    end
    it 'EnrollmentID from CSV file match the id of first enrollment' do
      csv = CSV.read(csv_file_path(@enrollment_class), headers: true)
      expect(csv.first['EnrollmentID']).to eq @enrollments.first.id.to_s
    end
    it 'ProjectType in project does not equal override' do
      expect(@project_ph.ProjectType).not_to eq @project_ph.computed_project_type
    end
    it 'project type override is a type of PH' do
      expect(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]).to include(@project_ph.computed_project_type)
    end
    it 'project type is overridden' do
      csv = CSV.read(csv_file_path(@project_class, exporter: @exporter_2), headers: true)
      project = csv.detect { |p| p['ProjectID'] == @project_ph.id.to_s }
      expect(project['ProjectType']).to eq '13'
    end
    it 'MoveInDate is set in the enrollment' do
      csv = CSV.read(csv_file_path(@enrollment_class, exporter: @exporter_2), headers: true)
      project = csv.detect { |p| p['ProjectID'] == @project_ph.id.to_s }
      expect(project['MoveInDate']).not_to be_empty
    end
    it 'TrackingMethod is set to blank' do
      csv = CSV.read(csv_file_path(@project_class, exporter: @exporter_2), headers: true)
      project = csv.detect { |p| p['ProjectID'] == @project_ph.id.to_s }
      expect(project['TrackingMethod']).to be_empty
    end
  end

  describe 'when override is to ES' do
    it 'initial project setup is as expected' do
      aggregate_failures 'checking project' do
        expect(@project.ProjectType).to_not eq 1
        expect(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es]).to include(@project.computed_project_type)
        expect(@project.TrackingMethod).to be_nil
        expect(@projects.count).to eq 5
      end
    end
    it 'sets tracking method in the export file' do
      csv = CSV.read(csv_file_path(@project_class, exporter: @exporter_2), headers: true)
      aggregate_failures 'checking exported project' do
        project = csv.detect { |p| p['ProjectID'] == @project.id.to_s }
        expect(project['TrackingMethod']).to_not be_empty
        expect(project['TrackingMethod']).to eq '0'
      end
    end
    it 'if the tracking method is 3 it is not overridden' do
      csv = CSV.read(csv_file_path(@project_class, exporter: @exporter_2), headers: true)
      project = csv.detect { |p| p['ProjectID'] == @project_es.id.to_s }
      aggregate_failures 'checking exported project' do
        expect(project['TrackingMethod']).to_not be_empty
        expect(project['TrackingMethod']).to eq '3'
      end
    end
  end
end

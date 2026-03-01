###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  def delete_records
    # Enrollment-scoped
    ExportHelper2026.enrollments.first.update(DateDeleted: Date.current)
    ExportHelper2026.exits.first.update(DateDeleted: Date.current)
    ExportHelper2026.disabilities.first.update(DateDeleted: Date.current)
    ExportHelper2026.employment_educations.first.update(DateDeleted: Date.current)
    ExportHelper2026.health_and_dvs.first.update(DateDeleted: Date.current)
    ExportHelper2026.income_benefits.first.update(DateDeleted: Date.current)
    ExportHelper2026.services.first.update(DateDeleted: Date.current)
    ExportHelper2026.assessments.first.update(DateDeleted: Date.current)
    ExportHelper2026.assessment_questions.first.update(DateDeleted: Date.current)
    ExportHelper2026.assessment_results.first.update(DateDeleted: Date.current)
    ExportHelper2026.events.first.update(DateDeleted: Date.current)
    ExportHelper2026.current_living_situations.first.update(DateDeleted: Date.current)
    ExportHelper2026.youth_education_statuses.first.update(DateDeleted: Date.current)
    # Project-scoped
    ExportHelper2026.affiliations.first.update(DateDeleted: Date.current)
    ExportHelper2026.funders.first.update(DateDeleted: Date.current)
    ExportHelper2026.hmis_participations.first.update(DateDeleted: Date.current)
    ExportHelper2026.ce_participations.first.update(DateDeleted: Date.current)
  end

  before(:all) do
    cleanup_test_environment
    ExportHelper2026.setup_data
    delete_records
  end

  after(:all) do
    ExportHelper2026.cleanup
  end

  describe 'When include deleted is not set:' do
    before(:all) do
      @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: ExportHelper2026.projects.map(&:id),
        period_type: 3,
        directive: 3,
        user_id: ExportHelper2026.user.id,
      )
      ExportHelper2026.instance_variable_set(:@exporter, @exporter)
      @exporter.export!(cleanup: false, zip: false, upload: false)
    end

    after(:all) do
      @exporter.remove_export_files if @exporter.respond_to?(:remove_export_files)
    end

    it 'Only exports undeleted enrollments' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.enrollment_class), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted exits' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.exit_class), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted affiliations' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Affiliation), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted funders' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Funder), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted hmis participations' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::HmisParticipation), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted ce participations' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::CeParticipation), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted disabilities' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Disability), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted employment educations' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::EmploymentEducation), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted health and dvs' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::HealthAndDv), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted income benefits' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.income_benefit_class), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted services' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Service), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted assessments' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Assessment), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted assessment questions' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::AssessmentQuestion), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted assessment results' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::AssessmentResult), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted events' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Event), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted current living situations' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::CurrentLivingSituation), headers: true)
      expect(csv.count).to eq 4
    end

    it 'Only exports undeleted youth education statuses' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::YouthEducationStatus), headers: true)
      expect(csv.count).to eq 4
    end
  end

  describe 'When include deleted is set:' do
    before(:all) do
      @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
        include_deleted: true,
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: ExportHelper2026.projects.map(&:id),
        period_type: 3,
        directive: 3,
        user_id: ExportHelper2026.user.id,
      )
      ExportHelper2026.instance_variable_set(:@exporter, @exporter)
      @exporter.export!(cleanup: false, zip: false, upload: false)
    end

    after(:all) do
      @exporter.remove_export_files if @exporter.respond_to?(:remove_export_files)
    end

    it 'Exports deleted enrollments' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.enrollment_class), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted exits' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.exit_class), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted affiliations' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Affiliation), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted funders' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Funder), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted hmis participations' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::HmisParticipation), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted ce participations' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::CeParticipation), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted disabilities' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Disability), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted employment educations' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::EmploymentEducation), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted health and dvs' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::HealthAndDv), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted income benefits' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.income_benefit_class), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted services' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Service), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted assessments' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Assessment), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted assessment questions' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::AssessmentQuestion), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted assessment results' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::AssessmentResult), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted events' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::Event), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted current living situations' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::CurrentLivingSituation), headers: true)
      expect(csv.count).to eq 5
    end

    it 'Exports deleted youth education statuses' do
      csv = CSV.read(ExportHelper2026.csv_file_path(HmisCsvTwentyTwentySix::Exporter::YouthEducationStatus), headers: true)
      expect(csv.count).to eq 5
    end
  end
end

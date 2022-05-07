###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'

RSpec.describe HmisCsvTwentyTwentyTwo::Exporter::Base, type: :model do
  describe 'without overrides' do
    before(:all) do
      cleanup_test_environment
      setup_data

      @project_cocs.first.update(CoCCode: 'XX-501')
      @project_cocs.last(4).map { |m| m.update(CoCCode: 'XX-601') }
      @extra_enrollment_coc = create :hud_enrollment_coc, data_source_id: @data_source.id, InformationDate: 1.week.ago, PersonalID: @enrollments.first.PersonalID, EnrollmentID: @enrollments.first.EnrollmentID, CoCCode: 'XX-501'

      @involved_project_ids = @projects.map(&:id)
      @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: @involved_project_ids,
        coc_codes: 'XX-501',
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

    it 'filters ProjectCoC.csv' do
      csv = CSV.read(File.join(@exporter.file_path, 'ProjectCoC.csv'), headers: true)
      expect(csv.count).to eq 1
    end

    it 'Enrollment in Enrolment Scope has two EnrollmentCoC Records' do
      enrollment = @exporter.enrollment_scope.first
      expect(enrollment.enrollment_cocs.count).to eq 2
    end

    it 'filters Services.csv to only those in enrollments in the selected CoC' do
      csv = CSV.read(File.join(@exporter.file_path, 'Services.csv'), headers: true)
      expect(csv.count).to eq 1
    end

    it 'filters EnrollmentCoC.csv to only those in the selected CoC' do
      csv = CSV.read(File.join(@exporter.file_path, 'EnrollmentCoC.csv'), headers: true)
      expect(csv.count).to eq 1
    end
  end

  describe 'with a ProjectCoC override' do
    before(:all) do
      cleanup_test_environment
      setup_data

      @project_cocs.first.update(CoCCode: 'XX-501')
      @project_cocs.second.update(hud_coc_code: 'XX-501')

      @involved_project_ids = @projects.map(&:id)
      @exporter = HmisCsvTwentyTwentyTwo::Exporter::Base.new(
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: @involved_project_ids,
        coc_codes: 'XX-501',
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

    it 'includes the ProjectCoC with the override' do
      csv = CSV.read(File.join(@exporter.file_path, 'ProjectCoC.csv'), headers: true)
      expect(csv.count).to eq 2
    end

    it 'ignores Enrollments where EnrollmentCoC CoC Code is not in selected CoC' do
      csv = CSV.read(File.join(@exporter.file_path, 'Enrollment.csv'), headers: true)
      expect(csv.count).to eq 0
    end

    it 'ignores EnrollmentCoC.csv where CoC Code is not in selected CoC' do
      csv = CSV.read(File.join(@exporter.file_path, 'EnrollmentCoC.csv'), headers: true)
      expect(csv.count).to eq 0
    end
  end
end

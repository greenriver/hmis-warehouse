###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'export_helper'

RSpec.describe HmisCsvTwentyTwentyFour::Exporter::Base, type: :model do
  describe 'without overrides' do
    before(:all) do
      cleanup_test_environment
      setup_data

      @project_cocs.first.update(CoCCode: 'XX-501')
      @project_cocs.last(4).map { |m| m.update(CoCCode: 'XX-601') }

      @enrollments.map { |e| e.update!(EnrollmentCoC: 'MA-500') } # Default to valid, but non-test

      @enrollments.first.update!(EnrollmentCoC: 'XX-501', ProjectID: @enrollments.first.ProjectID)
      @enrollments.second.update!(EnrollmentCoC: nil, ProjectID: @enrollments.first.ProjectID)
      @enrollments.third.update!(EnrollmentCoC: 'WRONG', ProjectID: @enrollments.first.ProjectID)

      @involved_project_ids = @projects.map(&:id)
      @exporter = HmisCsvTwentyTwentyFour::Exporter::Base.new(
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

    it 'Exports 3 enrollment records' do
      expect(@exporter.enrollment_scope.count).to eq 3
    end

    it 'filters Services.csv to only those in enrollments in the selected CoC' do
      csv = CSV.read(File.join(@exporter.file_path, 'Services.csv'), headers: true)
      expect(csv.count).to eq 3 # Includes services for Enrollments with no or invalid CoCs
    end

    it 'filters Enrollment.csv to only those in the selected CoC and those with no CoC, or an invalid CoC' do
      csv = CSV.read(File.join(@exporter.file_path, 'Enrollment.csv'), headers: true)
      expect(csv.count).to eq 3
    end
  end
end

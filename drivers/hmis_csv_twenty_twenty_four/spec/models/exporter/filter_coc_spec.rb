###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2024'

RSpec.describe HmisCsvTwentyTwentyFour::Exporter::Base, type: :model do
  describe 'without overrides' do
    before(:all) do
      cleanup_test_environment
      ExportHelper2024.setup_data

      # Set up a mix of CoC values for project_cocs
      ExportHelper2024.project_cocs.first.update(CoCCode: 'XX-501')
      ExportHelper2024.project_cocs.last(4).map { |m| m.update(CoCCode: 'XX-601') }

      # Set up a mix of CoC values for enrollments
      ExportHelper2024.enrollments.map { |e| e.update!(EnrollmentCoC: 'MA-500') } # Default to valid, but non-test
      ExportHelper2024.enrollments.first.update!(EnrollmentCoC: 'XX-501', ProjectID: ExportHelper2024.enrollments.first.ProjectID)
      ExportHelper2024.enrollments.second.update!(EnrollmentCoC: nil, ProjectID: ExportHelper2024.enrollments.first.ProjectID)
      ExportHelper2024.enrollments.third.update!(EnrollmentCoC: 'WRONG', ProjectID: ExportHelper2024.enrollments.first.ProjectID)

      @exporter = HmisCsvTwentyTwentyFour::Exporter::Base.new(
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: ExportHelper2024.projects.map(&:id),
        coc_codes: ['XX-501'],
        options: { 'coc_codes' => ['XX-501'] },
        period_type: 3,
        directive: 3,
        user_id: ExportHelper2024.user.id,
      )
      ExportHelper2024.instance_variable_set(:@exporter, @exporter)
      @exporter.export!(cleanup: false, zip: false, upload: false)
    end

    after(:all) do
      ExportHelper2024.cleanup
    end

    it 'filters ProjectCoC.csv to only include the matching CoC' do
      csv = CSV.read(ExportHelper2024.csv_file_path(ExportHelper2024.project_coc_class), headers: true)
      expect(csv.count).to eq 1
      expect(csv.first['CoCCode']).to eq 'XX-501'
    end

    it 'Exports 3 enrollment records' do
      expect(@exporter.enrollment_scope.count).to eq 3
    end

    it 'filters Services.csv to only those in enrollments in the selected CoC' do
      csv = CSV.read(ExportHelper2024.csv_file_path('Services'), headers: true)
      expect(csv.count).to eq 3 # Includes services for Enrollments with no or invalid CoCs
    end

    it 'filters Enrollment.csv to only those in the selected CoC and those with no CoC, or an invalid CoC' do
      csv = CSV.read(ExportHelper2024.csv_file_path(ExportHelper2024.enrollment_class), headers: true)
      expect(csv.count).to eq 3
    end
  end
end

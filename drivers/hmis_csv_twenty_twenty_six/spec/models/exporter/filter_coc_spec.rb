###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../support/export_helper_2026'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Base, type: :model do
  describe 'without overrides' do
    before(:all) do
      cleanup_test_environment
      ExportHelper2026.setup_data

      # Set up a mix of CoC values for project_cocs
      ExportHelper2026.project_cocs.first.update(CoCCode: 'XX-501')
      ExportHelper2026.project_cocs.last(4).map { |m| m.update(CoCCode: 'XX-601') }

      # Set up a mix of CoC values for enrollments
      ExportHelper2026.enrollments.map { |e| e.update!(EnrollmentCoC: 'MA-500') } # Default to valid, but non-test
      ExportHelper2026.enrollments.first.update!(EnrollmentCoC: 'XX-501', ProjectID: ExportHelper2026.enrollments.first.ProjectID)
      ExportHelper2026.enrollments.second.update!(EnrollmentCoC: nil, ProjectID: ExportHelper2026.enrollments.first.ProjectID)
      ExportHelper2026.enrollments.third.update!(EnrollmentCoC: 'WRONG', ProjectID: ExportHelper2026.enrollments.first.ProjectID)

      @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: ExportHelper2026.projects.map(&:id),
        coc_codes: ['XX-501'],
        options: { 'coc_codes' => ['XX-501'] },
        period_type: 3,
        directive: 3,
        user_id: ExportHelper2026.user.id,
      )
      ExportHelper2026.instance_variable_set(:@exporter, @exporter)
      @exporter.export!(cleanup: false, zip: false, upload: false)
    end

    after(:all) do
      ExportHelper2026.cleanup
    end

    it 'filters ProjectCoC.csv to only include the matching CoC' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.project_coc_class), headers: true)
      expect(csv.count).to eq 1
      expect(csv.first['CoCCode']).to eq 'XX-501'
    end

    it 'Exports 3 enrollment records' do
      expect(@exporter.enrollment_scope.count).to eq 3
    end

    it 'filters Services.csv to only those in enrollments in the selected CoC' do
      csv = CSV.read(ExportHelper2026.csv_file_path('Services'), headers: true)
      expect(csv.count).to eq 3 # Includes services for Enrollments with no or invalid CoCs
    end

    it 'filters Enrollment.csv to only those in the selected CoC and those with no CoC, or an invalid CoC' do
      csv = CSV.read(ExportHelper2026.csv_file_path(ExportHelper2026.enrollment_class), headers: true)
      expect(csv.count).to eq 3
    end
  end

  describe 'non-HoH member filtering by their HoH CoC' do
    before(:all) do
      cleanup_test_environment
      ExportHelper2026.setup_data

      # Set up project with one CoC
      ExportHelper2026.project_cocs.first.update(CoCCode: 'XX-501')
      ExportHelper2026.project_cocs.last(4).map { |m| m.update(CoCCode: 'XX-601') }

      @test_project = ExportHelper2026.projects.first

      # Household 1: HoH with valid CoC (XX-501), all included
      @hoh_valid = ExportHelper2026.enrollments[0]
      @hoh_valid.update(
        HouseholdID: 'VALID-HH-001',
        RelationshipToHoH: 1,
        ProjectID: @test_project.ProjectID,
        EnrollmentCoC: 'XX-501',
      )

      @member_valid_1 = ExportHelper2026.enrollments[1]
      @member_valid_1.update(
        HouseholdID: 'VALID-HH-001',
        RelationshipToHoH: 2,
        ProjectID: @test_project.ProjectID,
        EnrollmentCoC: nil,
      )

      # Household 2: HoH with valid CoC (XX-502), but not included in the filter, excluded
      @hoh_invalid = ExportHelper2026.enrollments[2]
      @hoh_invalid.update(
        HouseholdID: 'INVALID-HH-001',
        RelationshipToHoH: 1,
        ProjectID: @test_project.ProjectID,
        EnrollmentCoC: 'XX-502', # valid CoC, but not included
      )

      @member_invalid_1 = ExportHelper2026.enrollments[3]
      @member_invalid_1.update(
        HouseholdID: 'INVALID-HH-001',
        RelationshipToHoH: 2,
        ProjectID: @test_project.ProjectID,
        EnrollmentCoC: nil,
      )

      # Household 3: Member with no HoH (no RelationshipToHoH = 1), included, nil CoC
      @member_no_hoh = ExportHelper2026.enrollments[4]
      @member_no_hoh.update(
        HouseholdID: 'NO-HOH-HH-001',
        RelationshipToHoH: 2,
        ProjectID: @test_project.ProjectID,
        EnrollmentCoC: nil,
      )

      @exporter = HmisCsvTwentyTwentySix::Exporter::Base.new(
        start_date: 1.week.ago.to_date,
        end_date: Date.current,
        projects: [@test_project.id],
        coc_codes: ['XX-501'],
        options: { 'coc_codes' => ['XX-501'] },
        period_type: 3,
        directive: 3,
        user_id: ExportHelper2026.user.id,
      )
      ExportHelper2026.instance_variable_set(:@exporter, @exporter)
      @exporter.export!(cleanup: false, zip: false, upload: false)
    end

    after(:all) do
      ExportHelper2026.cleanup
    end

    it 'includes HoH with valid CoC' do
      expect(@exporter.enrollment_scope).to include(@hoh_valid)
    end

    it 'includes household members when their HoH has valid CoC' do
      expect(@exporter.enrollment_scope).to include(@member_valid_1)
    end

    it 'excludes HoH with invalid CoC' do
      expect(@exporter.enrollment_scope).not_to include(@hoh_invalid)
    end

    it 'excludes household members when their HoH has invalid CoC' do
      expect(@exporter.enrollment_scope).not_to include(@member_invalid_1)
    end

    it 'excludes household members when there is no HoH in the household' do
      expect(@exporter.enrollment_scope).to include(@member_no_hoh)
    end

    it 'enrollment scope includes only 3 enrollments, 2 from the valid household and 1 from the no hoh household' do
      expect(@exporter.enrollment_scope.count).to eq 3
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Ensure Relationships', type: :model do
  describe 'without cleanup' do
    before(:all) do
      travel_to Time.local(2018, 1, 1) do
        setup(with_cleanup: false)
      end
    end

    it 'Has expected enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(25)
    end
  end

  describe 'with cleanup' do
    before(:all) do
      travel_to Time.local(2018, 1, 1) do
        setup(with_cleanup: true)
      end
    end

    it 'Has expected enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(25)
    end

    it 'Individual enrollments all have one HoH' do
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H1', RelationshipToHoH: 1).count).to eq(1)
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H2', RelationshipToHoH: 1).count).to eq(1)
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H3', RelationshipToHoH: 1).count).to eq(1)
    end

    it 'Individual enrollments with no HouseholdID all have one HoH ' do
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-8').RelationshipToHoH).to eq(1)
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-9').RelationshipToHoH).to eq(1)
    end

    it 'Multi-client enrollments with no HoH all have one HoH' do
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H8', RelationshipToHoH: 1).count).to eq(1)
    end

    it 'correctly assigned HoH are not changed' do
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H9', RelationshipToHoH: 1).count).to eq(1)
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-18').RelationshipToHoH).to eq(1)
    end

    it 'fixes enrollments with multiple incorrect HoH, choosing the adult' do
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H6', RelationshipToHoH: 1).count).to eq(1)
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-10').RelationshipToHoH).to eq(1)
    end

    it 'all child enrollments with multiple incorrect HoH, sets oldest as HoH, other as unknown relationship' do
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H7').count).to eq(2)
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-13').RelationshipToHoH).to eq(1)
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-14').RelationshipToHoH).to eq(99)
    end

    it 'adds HoH, choosing the adult' do
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H5', RelationshipToHoH: 1).count).to eq(1)
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-6').RelationshipToHoH).to eq(1)
    end

    it 'All teen enrollment is broken up, given alternate HouseholdIDs and HoH' do
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-20').RelationshipToHoH).to eq(1)
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-20').HouseholdID).not_to be_empty
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-21').RelationshipToHoH).to eq(1)
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-21').HouseholdID).not_to be_empty
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H10').count).to eq(0)
    end

    it 'uses age at EntryDate, not age today, when categorizing a household' do
      # C-9 and C-10 were 13 and 12 at their 2020-01-01 EntryDate, so H11 is an
      # 11-to-17 household and must be split into one household per person.
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H11').count).to eq(0)
      ['E-22', 'E-23'].each do |enrollment_id|
        enrollment = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: enrollment_id)
        expect(enrollment.RelationshipToHoH).to eq(1)
        expect(enrollment.HouseholdID).to be_present
      end
      expect(GrdaWarehouse::Hud::Enrollment.where(EnrollmentID: ['E-22', 'E-23']).
        pluck(:HouseholdID).uniq.count).to eq(2)
    end

    it 'treats age 11 as a teen, splitting a household with no child aged 10 or less' do
      # C-11 and C-12 were 11 and 16 at their 2020-01-01 EntryDate. The Glossary
      # only keeps an all-under-18 household together when someone is aged 10 or
      # less, so H12 must be split into one household per person.
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H12').count).to eq(0)
      ['E-24', 'E-25'].each do |enrollment_id|
        enrollment = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: enrollment_id)
        expect(enrollment.RelationshipToHoH).to eq(1)
        expect(enrollment.HouseholdID).to be_present
      end
      expect(GrdaWarehouse::Hud::Enrollment.where(EnrollmentID: ['E-24', 'E-25']).
        pluck(:HouseholdID).uniq.count).to eq(2)
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!

    @data_source = if with_cleanup
      create(:importer_ensure_relationships_ds)
    else
      create(:importer_dont_cleanup_ds)
    end
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/ensure_relationships',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
      stop_version: '2026',
    )
  end
end

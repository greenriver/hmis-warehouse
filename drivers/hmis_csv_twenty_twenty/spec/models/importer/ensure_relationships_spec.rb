###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Ensure Relationships', type: :model do
  describe 'without cleanup' do
    before(:all) do
      travel_to Time.local(2018, 1, 1) do
        setup(with_cleanup: false)
      end
    end

    it 'Has expected enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(21)
    end
  end

  describe 'with cleanup' do
    before(:all) do
      travel_to Time.local(2018, 1, 1) do
        setup(with_cleanup: true)
      end
    end

    it 'Has expected enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(21)
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
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvTwentyTwenty::Utility.clear!

    @data_source = if with_cleanup
      create(:ensure_relationships_ds)
    else
      create(:dont_cleanup_ds)
    end
    import_hmis_csv_fixture(
      'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/ensure_relationships',
      data_source: @data_source,
      version: '2020',
      run_jobs: false,
    )
  end
end

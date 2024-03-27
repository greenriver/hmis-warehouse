###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Fix Household IDs', type: :model do
  describe 'without cleanup' do
    before(:all) do
      travel_to Time.local(2018, 1, 1) do
        setup(with_cleanup: false)
      end
    end

    it 'Has expected enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(21)
    end

    it 'Household IDs should be blank, as expected' do
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-1').HouseholdID).to be_blank
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-8').HouseholdID).to be_blank
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-17').HouseholdID).to be_blank
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-21').HouseholdID).to eq('H10')
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

    it 'Household IDs should be updated in warehouse' do
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-1').HouseholdID).to be_present
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-8').HouseholdID).to be_present
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-17').HouseholdID).to be_present
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-21').HouseholdID).to eq('H10')
    end
  end

  def setup(with_cleanup:)
    if with_cleanup
      import_cleanups = {
        'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::FixBlankHouseholdIds'],
      }
    else
      GrdaWarehouse::Utility.clear!
      HmisCsvTwentyTwenty::Utility.clear!
      import_cleanups = {}
    end
    @data_source = GrdaWarehouse::DataSource.find_by(name: 'Fix blank household ids') || create(:fix_blank_household_ids)
    @data_source.update(import_cleanups: import_cleanups)
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/fix_household_ids',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
  end
end

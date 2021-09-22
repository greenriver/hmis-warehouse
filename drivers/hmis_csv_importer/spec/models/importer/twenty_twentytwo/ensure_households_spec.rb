###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Ensure Households', type: :model do
  describe 'without cleanup' do
    before(:all) do
      travel_to Time.local(2018, 1, 1) do
        setup(with_cleanup: false)
      end
    end

    it 'Has expected enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(21)
    end

    it 'Household IDs should be in warehouse' do
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H4').count).to eq(2)
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H5').count).to eq(2)
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H7').count).to eq(2)
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
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H4').count).to eq(0)
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H5').count).to eq(0)
      expect(GrdaWarehouse::Hud::Enrollment.where(HouseholdID: 'H7').count).to eq(0)
    end

    it 'Clients have correct number of enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.where(PersonalID: 'C-1').count).to eq(7)
      expect(GrdaWarehouse::Hud::Enrollment.where(PersonalID: 'C-2').count).to eq(2)
      expect(GrdaWarehouse::Hud::Enrollment.where(PersonalID: 'C-3').count).to eq(6)
    end
  end

  def setup(with_cleanup:)
    if with_cleanup
      import_cleanups = {
        'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::EnforceRelationshipToHoh'],
      }
    else
      GrdaWarehouse::Utility.clear!
      HmisCsvTwentyTwenty::Utility.clear!
      import_cleanups = {}
    end
    @data_source = GrdaWarehouse::DataSource.find_by(name: 'Ensure Relationships') || create(:ensure_relationships_ds)
    @data_source.update(import_cleanups: import_cleanups)
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twentytwo/ensure_households',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
  end
end

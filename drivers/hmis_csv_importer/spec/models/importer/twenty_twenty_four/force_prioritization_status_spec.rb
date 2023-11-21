###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Force Assessment Prioritization Status', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_cleanup: false)
    end

    it 'not all assessments will have prioritization status set to 1' do
      stati = GrdaWarehouse::Hud::Assessment.all.pluck(:PrioritizationStatus)
      expect(stati.all?(1)).to be false
    end
  end

  describe 'with cleanup' do
    before(:all) do
      setup(with_cleanup: true)
    end

    it 'there are five assessments imported' do
      expect(GrdaWarehouse::Hud::Assessment.count).to eq(5)
    end
    it 'all assessments will have prioritization status set to 1' do
      stati = GrdaWarehouse::Hud::Assessment.all.pluck(:PrioritizationStatus)
      expect(stati.all?(1)).to be true
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!

    data_source = if with_cleanup
      create(:importer_force_prioritized_placement_status)
    else
      create(:importer_dont_cleanup_ds)
    end

    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/forced_prioritization_placement_status',
      data_source: data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
  end
end

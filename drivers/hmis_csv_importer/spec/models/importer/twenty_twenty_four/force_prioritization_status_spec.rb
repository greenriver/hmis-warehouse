###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Force Assessment Prioritization Status', type: :model do
  describe 'without cleanup' do
    before(:all) do
      clear
      setup(with_cleanup: false)
    end

    it 'not all assessments will have prioritization status set to 1' do
      stati = GrdaWarehouse::Hud::Assessment.all.pluck(:PrioritizationStatus)
      expect(stati.all?(1)).to be false
    end
  end

  describe 'with cleanup' do
    before(:all) do
      clear
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

  describe 'previous data is correctly updated' do
    before(:all) do
      clear
      setup(with_cleanup: false)
      @source_hashes = nil
    end

    it 'not all assessments will have prioritization status set to 1' do
      stati = GrdaWarehouse::Hud::Assessment.all.pluck(:PrioritizationStatus)
      @source_hashes = GrdaWarehouse::Hud::Assessment.all.pluck(:id, :source_hash).to_h
      expect(stati.all?(1)).to be false
    end

    describe 'after subsequent import with hook enabled' do
      before(:all) do
        setup(with_cleanup: true)
      end
      it 'all assessments will have prioritization status set to 1' do
        stati = GrdaWarehouse::Hud::Assessment.all.pluck(:PrioritizationStatus)
        new_hashes = GrdaWarehouse::Hud::Assessment.all.pluck(:id, :source_hash).to_h
        expect(new_hashes).to_not eq(@source_hashes)
        expect(stati.all?(1)).to be true
      end
    end
  end

  def clear
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!
  end

  def setup(with_cleanup:)
    @data_source ||= create(:importer_force_prioritized_placement_status)
    if with_cleanup
      @data_source.update(
        import_cleanups: {
          'Assessment': ['HmisCsvImporter::HmisCsvCleanup::ForcePrioritizedPlacementStatus'],
        },
      )
    else
      @data_source.update(import_cleanups: {})
    end

    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/forced_prioritization_placement_status',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
  end
end

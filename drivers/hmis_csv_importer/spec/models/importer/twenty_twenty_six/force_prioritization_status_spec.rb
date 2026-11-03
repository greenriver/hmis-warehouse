###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  describe 'cleanup with an earlier import present' do
    before(:all) do
      clear
      setup(with_cleanup: false)
      @earlier_importer_log_id = HmisCsvImporter::Importer::ImporterLog.maximum(:id)
      setup(with_cleanup: true)
    end

    it 'leaves blank prioritization status on the earlier import rows' do
      earlier_rows = HmisCsvTwentyTwentySix::Importer::Assessment.where(importer_log_id: @earlier_importer_log_id, AssessmentID: '2')
      expect(earlier_rows.pluck(:PrioritizationStatus)).to eq([nil])
    end

    it 'sets prioritization status to 1 on the current import' do
      expect(GrdaWarehouse::Hud::Assessment.find_by!(AssessmentID: '2').PrioritizationStatus).to eq(1)
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
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/forced_prioritization_placement_status',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
      stop_version: '2026',
    )
  end
end

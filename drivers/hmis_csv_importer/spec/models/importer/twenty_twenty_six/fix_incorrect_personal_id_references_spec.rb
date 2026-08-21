###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Integration spec: verifies the post-ingest import extension is wired into the CSV import pipeline.
#
# Runs a full fixture import with/without the cleanup enabled and asserts on resulting warehouse state.
# The Exit fixture contains rows whose PersonalID disagrees with the Enrollment they reference
# (X-5/X-7), plus a row whose PersonalID is already correct (X-1).
#
# Enrollment => PersonalID (see Enrollment.csv):
#   E-1 => C-1, E-5 => C-2, E-7 => C-3
#
# For behavioral coverage of the implementation (all record types, scoping, dry_run, etc.),
# see drivers/hmis/spec/models/hmis/hud/data_integrity/fix_incorrect_personal_id_references_spec.rb.
RSpec.describe 'Fix Incorrect PersonalID References', type: :model do
  def exit_personal_id(exit_id)
    GrdaWarehouse::Hud::Exit.where(data_source_id: @data_source.id).find_by(ExitID: exit_id).PersonalID
  end

  describe 'without cleanup' do
    before(:all) do
      travel_to Time.local(2020, 1, 1) do
        setup(with_cleanup: false)
      end
    end

    it 'leaves the incorrect PersonalIDs in place' do
      expect(exit_personal_id('X-1')).to eq('C-1')
      expect(exit_personal_id('X-5')).to eq('C-1')
      expect(exit_personal_id('X-7')).to eq('C-1')
    end
  end

  describe 'with cleanup' do
    before(:all) do
      travel_to Time.local(2020, 1, 1) do
        setup(with_cleanup: true)
      end
    end

    it 'aligns the PersonalID to the referenced Enrollment' do
      # Already-correct row is untouched
      expect(exit_personal_id('X-1')).to eq('C-1')
      # Incorrect rows are corrected to the Enrollment's PersonalID
      expect(exit_personal_id('X-5')).to eq('C-2')
      expect(exit_personal_id('X-7')).to eq('C-3')
    end
  end

  def setup(with_cleanup:)
    if with_cleanup
      import_cleanups = {
        'Enrollment': ['HmisCsvImporter::PostIngestCleanup::FixIncorrectPersonalIdReferences'],
      }
    else
      GrdaWarehouse::Utility.clear!
      HmisCsvTwentyTwenty::Utility.clear!
      import_cleanups = {}
    end
    @data_source = GrdaWarehouse::DataSource.find_by(name: 'Fix Incorrect Personal IDs') || create(:importer_fix_incorrect_personal_ids_ds)
    @data_source.update(import_cleanups: import_cleanups)
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/fix_incorrect_personal_id',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
      stop_version: '2026',
    )
  end
end

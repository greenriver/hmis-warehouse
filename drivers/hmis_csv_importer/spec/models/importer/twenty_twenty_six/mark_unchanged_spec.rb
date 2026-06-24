###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Exercises the mark_unchanged (source_hash match) path in process_existing.
# When the same data is imported twice, the second pass should recognize all
# in-scope records as unchanged via hash comparison and skip updates entirely.
#
# Uses enrollment_test_files which has 4 enrollments, 3 of which are in scope
# (see deletion_spec.rb for the scope rationale on enrollment 622377).
RSpec.describe 'HUD CSV mark_unchanged on re-import', type: :model do
  fixture = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/enrollment_test_files'

  describe 'when the same data is imported twice' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!

      import_hmis_csv_fixture(fixture, version: 'AutoMigrate', run_jobs: false, stop_version: '2026')
      @loader = import_hmis_csv_fixture(fixture, version: 'AutoMigrate', run_jobs: false, stop_version: '2026')
    end

    after(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
    end

    it 'marks all in-scope enrollments as unchanged' do
      expect(@loader.importer_log.summary['Enrollment.csv']['unchanged']).to eq(3)
    end

    it 'does not remove any enrollments' do
      expect(@loader.importer_log.summary['Enrollment.csv']['removed']).to eq(0)
    end

    it 're-upserts the out-of-scope enrollment as an add' do
      # 622377 is outside involved_warehouse_scope (exited before the export
      # period), so add_new_data sees it as absent from the scoped set and
      # upserts it each time — counted as 1 add.
      expect(@loader.importer_log.summary['Enrollment.csv']['added']).to eq(1)
    end

    it 'preserves all enrollments in the warehouse' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
    end
  end
end

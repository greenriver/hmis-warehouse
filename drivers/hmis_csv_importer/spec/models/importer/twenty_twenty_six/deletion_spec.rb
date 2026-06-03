###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Covers the soft-delete path in remove_pending_deletes. The key scenario —
# import a full data set, then import a subset — was not exercised by any
# existing spec. Without it, the scope-table-based deletion logic could
# regress silently.
#
# Fixture layout:
#   enrollment_test_files        — 4 enrollments (557331, 557890, 559123, 622377)
#   enrollment_test_files_subset — only 557331 and 557890 (559123 omitted;
#                                  622377 also omitted but is outside scope anyway)
#
# 557331, 557890, 559123 have no exit, so they are open during the export
# period (2017-09-01..2017-10-03) and fall within the importer's involved scope.
# 622377 exited 2015-11-07 (before the export start date) so it is outside
# the scope and is never a deletion candidate.
RSpec.describe 'HUD CSV soft-deletion on re-import', type: :model do
  full_fixture   = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/enrollment_test_files'
  subset_fixture = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/enrollment_test_files_subset'
  removed_enrollment_id = '559123'

  describe 'when a subsequent import omits records present in the warehouse' do
    before(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!

      # Pass 1: establish 4 enrollments in the warehouse.
      import_hmis_csv_fixture(full_fixture, version: 'AutoMigrate', run_jobs: false, stop_version: '2026')
      # Pass 2: subset omits EnrollmentID 559123 — it should be soft-deleted.
      @loader = import_hmis_csv_fixture(subset_fixture, version: 'AutoMigrate', run_jobs: false, stop_version: '2026')
    end

    after(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!
    end

    it 'soft-deletes the enrollment absent from the second import' do
      deleted = GrdaWarehouse::Hud::Enrollment.only_deleted.where(EnrollmentID: removed_enrollment_id)
      expect(deleted.count).to eq(1)
      expect(deleted.first.DateDeleted).not_to be_nil
    end

    it 'does not soft-delete enrollments still present in the import' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(3)
    end

    it 'does not soft-delete the out-of-scope enrollment absent from the subset' do
      expect(GrdaWarehouse::Hud::Enrollment.where(EnrollmentID: '622377')).to exist
    end

    it 'records the correct removed count in the importer log' do
      expect(@loader.importer_log.summary['Enrollment.csv']['removed']).to eq(1)
    end

    it 'leaves no rows with pending_date_deleted set after import completes' do
      HmisCsvImporter::Importer::Importer.soft_deletable_sources('2026').each do |source|
        count = source.where.not(pending_date_deleted: nil).count
        expect(count).to eq(0), "#{source.name} has #{count} row(s) with pending_date_deleted set"
      end
    end
  end
end

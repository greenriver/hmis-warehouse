###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Make Sole Member HoH', type: :model do
  def enrollment(id)
    GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: id)
  end

  describe 'without cleanup' do
    before(:all) do
      travel_to Time.local(2020, 1, 15) do
        setup(with_cleanup: false)
      end
    end

    it 'leaves all records unchanged' do
      expect(enrollment('E-1').RelationshipToHoH).to eq(99)
      expect(enrollment('E-2').RelationshipToHoH).to eq(1)
      expect(enrollment('E-3').RelationshipToHoH).to eq(99)
      expect(enrollment('E-4').RelationshipToHoH).to eq(99)
      expect(enrollment('E-5').RelationshipToHoH).to be_blank
      expect(enrollment('E-6').RelationshipToHoH).to eq(99)
    end
  end

  describe 'with cleanup' do
    before(:all) do
      travel_to Time.local(2020, 1, 15) do
        setup(with_cleanup: true)
      end
    end

    it 'promotes the sole member to HoH' do
      expect(enrollment('E-1').RelationshipToHoH).to eq(1)
    end

    it 'promotes a sole member with a blank relationship to HoH' do
      expect(enrollment('E-5').RelationshipToHoH).to eq(1)
    end

    it 'does not alter the canary records' do
      expect(enrollment('E-2').RelationshipToHoH).to eq(1)
      expect(enrollment('E-3').RelationshipToHoH).to eq(99)
      expect(enrollment('E-4').RelationshipToHoH).to eq(99)
      expect(enrollment('E-6').RelationshipToHoH).to eq(99)
    end

    it 'refreshes the staging record source_hash so change-detection stays consistent' do
      # The staging (importer) row for the most recent import of this data source. Two imports may
      # exist (the "without cleanup" and "with cleanup" contexts), so pick the latest importer_log.
      staging_row = HmisCsvTwentyTwentySix.importable_file_class('Enrollment').
        where(EnrollmentID: 'E-1').
        order(importer_log_id: :desc).
        first

      # sanity check: this is the staging row whose relationship was set by the cleanup
      expect(staging_row.RelationshipToHoH).to eq(1)

      # source_hash is derived from the source columns (including RelationshipToHoH). If the
      # cleanup had set HoH without refreshing source_hash, recomputing it here would
      # change the value, and the importer would mis-detect changes on subsequent imports.
      expect { staging_row.set_source_hash }.not_to change(staging_row, :source_hash)
    end
  end

  def setup(with_cleanup:)
    if with_cleanup
      import_cleanups = {
        'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::MakeSoleMemberHoh'],
      }
    else
      GrdaWarehouse::Utility.clear!
      HmisCsvTwentyTwenty::Utility.clear!
      import_cleanups = {}
    end
    @data_source = GrdaWarehouse::DataSource.find_by(name: 'Make sole member HoH') || create(:make_sole_member_hoh)
    @data_source.update(import_cleanups: import_cleanups)
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/make_sole_member_hoh',
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
      stop_version: '2026',
    )
  end
end

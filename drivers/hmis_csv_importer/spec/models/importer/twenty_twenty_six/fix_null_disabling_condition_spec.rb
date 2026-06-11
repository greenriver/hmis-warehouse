###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Fix null DisablingCondition', type: :model do
  fixture = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/fix_household_ids'

  describe 'without cleanup' do
    before(:all) do
      travel_to Time.local(2018, 1, 1) do
        setup(with_cleanup: false)
      end
    end

    it 'leaves DisablingCondition null in the warehouse' do
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-1').DisablingCondition).to be_nil
    end
  end

  describe 'with cleanup' do
    before(:all) do
      travel_to Time.local(2018, 1, 1) do
        setup(with_cleanup: true)
      end
    end

    it 'sets null DisablingCondition to 99 in the warehouse' do
      expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: 'E-1').DisablingCondition).to eq(99)
      expect(GrdaWarehouse::Hud::Enrollment.where(DisablingCondition: nil)).to be_empty
    end
  end

  describe HmisCsvImporter::HmisCsvCleanup::FixNullDisablingCondition do
    it 'does not change enrollments that already have a DisablingCondition value' do
      data_source = create(:source_data_source)
      import_hmis_csv_fixture(
        fixture,
        data_source: data_source,
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
      log = HmisCsvImporter::Importer::ImporterLog.last
      enrollment_source = HmisCsvTwentyTwentySix::Importer::Enrollment
      enrollment_source.
        where(importer_log_id: log.id, EnrollmentID: 'E-2').
        update_all(DisablingCondition: 0)

      described_class.new(
        importer_log: log,
        date_range: Filters::DateRange.new(start: Date.new(2020, 1, 1), end: Date.new(2020, 12, 31)),
        version: '2026',
      ).cleanup!

      scope = enrollment_source.where(importer_log_id: log.id)
      expect(scope.find_by(EnrollmentID: 'E-2').DisablingCondition).to eq(0)
      expect(scope.find_by(EnrollmentID: 'E-1').DisablingCondition).to eq(99)
    end
  end

  def setup(with_cleanup:)
    if with_cleanup
      import_cleanups = {
        'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::FixNullDisablingCondition'],
      }
    else
      GrdaWarehouse::Utility.clear!
      HmisCsvTwentyTwentySix::Utility.clear!
      import_cleanups = {}
    end
    @data_source = GrdaWarehouse::DataSource.find_by(name: 'Fix null disabling condition') ||
      create(:importer_fix_null_disabling_condition_ds)
    @data_source.update(import_cleanups: import_cleanups)
    import_hmis_csv_fixture(
      fixture,
      data_source: @data_source,
      version: 'AutoMigrate',
      run_jobs: false,
      stop_version: '2026',
    )
  end
end

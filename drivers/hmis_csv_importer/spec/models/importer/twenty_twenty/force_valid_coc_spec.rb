###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Force Valid CoC Codes', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_cleanup: false)
    end

    it 'Has 9 enrollment cocs' do
      expect(GrdaWarehouse::Hud::EnrollmentCoc.count).to eq(9)
    end

    it 'Includes invalid CoCCodes' do
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('MA5001')
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('zz999')
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('ma504')
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode).compact.count).to eq(9)
    end
  end

  describe 'with cleanup' do
    before(:all) do
      setup(with_cleanup: true)
    end

    it 'Has 9 enrollment cocs' do
      expect(GrdaWarehouse::Hud::EnrollmentCoc.count).to eq(9)
    end

    it 'Includes ignores CoCCodes it cannot fix' do
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode).compact.count).to eq(4)
    end

    it 'Includes corrected CoCCodes' do
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('MA-502')
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('MA-503')
      expect(GrdaWarehouse::Hud::EnrollmentCoc.pluck(:CoCCode)).to include('MA-504')
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!

    data_source = if with_cleanup
      create(:importer_force_valid_enrollment_cocs)
    else
      create(:importer_dont_cleanup_ds)
    end

    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty/cleanup_move_ins',
      data_source: data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
  end
end

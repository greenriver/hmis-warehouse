###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Delete empty SO enrollments', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_cleanup: false)
    end

    it 'has 8 enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(8)
    end
  end

  describe 'with cleanup' do
    before(:all) do
      setup(with_cleanup: true)
    end

    it 'leaves the empty non-NBN enrollments alone' do
      expect(GrdaWarehouse::Hud::Enrollment.where(ProjectID: 'SAFE').count).to eq(2)
    end

    it 'has 1 ES enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.where(ProjectID: 'ES').count).to eq(1)
    end

    it 'has 2 SO enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.where(ProjectID: 'SO').count).to eq(2)
    end

    it 'has 5 total enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(5)
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!

    data_source = if with_cleanup
      create(:importer_delete_empty_enrollments_ds)
    else
      create(:importer_dont_cleanup_ds)
    end
    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty/delete_empty_enrollments',
      data_source: data_source,
      version: 'AutoMigrate',
      run_jobs: false,
    )
  end
end

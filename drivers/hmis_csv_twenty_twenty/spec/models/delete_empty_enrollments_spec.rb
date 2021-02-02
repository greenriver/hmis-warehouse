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

    after(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!

      FileUtils.rm_rf(@import_path)
    end

    it 'has 8 enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(8)
    end
  end

  describe 'with cleanup' do
    before(:all) do
      setup(with_cleanup: true)
    end

    after(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!

      FileUtils.rm_rf(@import_path)
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
    HmisCsvTwentyTwenty::Utility.clear!

    file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/delete_empty_enrollments'

    @data_source = if with_cleanup
      create(:delete_empty_enrollments_ds)
    else
      create(:dont_cleanup_ds)
    end

    source_file_path = File.join(file_path, 'source')
    @import_path = File.join(file_path, @data_source.id.to_s)
    FileUtils.cp_r(source_file_path, @import_path)

    @loader = HmisCsvTwentyTwenty::Loader::Loader.new(
      file_path: @import_path,
      data_source_id: @data_source.id,
      remove_files: false,
    )
    @loader.load!
    @loader.import!
  end
end

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Prepend Project IDs', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_cleanup: false)
    end

    after(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!

      FileUtils.rm_rf(@import_path)
    end

    it 'Has 1 project' do
      expect(GrdaWarehouse::Hud::Project.count).to eq(1)
    end

    it 'Project Name is Test Project' do
      expect(GrdaWarehouse::Hud::Project.first.ProjectName).to eq('Test Project')
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

    it 'Has 1 project' do
      expect(GrdaWarehouse::Hud::Project.count).to eq(1)
    end

    it 'Project Name is (PROJECT) Test Project' do
      expect(GrdaWarehouse::Hud::Project.first.ProjectName).to eq('(PROJECT) Test Project')
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvTwentyTwenty::Utility.clear!

    file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/cleanup_move_ins'

    @data_source = if with_cleanup
      create(:prepend_project_ids)
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

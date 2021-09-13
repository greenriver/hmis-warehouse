###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Prepend Organization IDs', type: :model do
  describe 'without cleanup' do
    before(:all) do
      setup(with_cleanup: false)
    end

    after(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!

      FileUtils.rm_rf(@import_path)
    end

    it 'Has 1 organization' do
      expect(GrdaWarehouse::Hud::Organization.count).to eq(1)
    end

    it 'Organization Name is Test Organization' do
      expect(GrdaWarehouse::Hud::Organization.first.OrganizationName).to eq('Test Org')
    end
  end

  describe 'with cleanup' do
    before(:all) do
      setup(with_cleanup: true)
    end

    after(:all) do
      HmisCsvImporter::Utility.clear!
      GrdaWarehouse::Utility.clear!

      FileUtils.rm_rf(@import_path)
    end

    it 'Has 1 organization' do
      expect(GrdaWarehouse::Hud::Organization.count).to eq(1)
    end

    it 'has Organization ID prepended' do
      expect(GrdaWarehouse::Hud::Organization.first.OrganizationName).to eq('(ORG-ID) Test Org')
    end
  end

  def setup(with_cleanup:)
    GrdaWarehouse::Utility.clear!
    HmisCsvImporter::Utility.clear!

    file_path = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty/cleanup_move_ins'

    @data_source = if with_cleanup
      create(:importer_prepend_organization_ids)
    else
      create(:importer_dont_cleanup_ds)
    end

    source_file_path = File.join(file_path, 'source')
    @import_path = File.join(file_path, @data_source.id.to_s)
    FileUtils.cp_r(source_file_path, @import_path)

    @loader = HmisCsvImporter::Loader::Loader.new(
      file_path: @import_path,
      data_source_id: @data_source.id,
      remove_files: false,
    )
    @loader.load!
    @loader.import!
    Delayed::Worker.new.work_off(2)
  end
end

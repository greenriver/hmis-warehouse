###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'HUD ExportDate Tests', type: :model do
  # NOTE: date_updated_spec.rb tests test that data isn't changed when imported and the second Export was created before the first.
  # This tests that data is updated regardless of DateUpdated if the ExportDate is newer or the same
  describe 'initial load' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @delete_later = []
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/export_date_fixtures/date_updated_initial'
      import(file_path, @data_source)
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      cleanup_files
    end

    it 'imports Client One' do
      client = GrdaWarehouse::Hud::Client.first
      expect(GrdaWarehouse::Hud::Client.count).to eq(1)
      expect(client.full_name).to eq('Client One')
    end

    describe 'older update' do
      before(:all) do
        file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/export_date_fixtures/date_updated_older'
        import(file_path, @data_source)
      end

      it 'Client One has changed' do
        client = GrdaWarehouse::Hud::Client.first
        expect(GrdaWarehouse::Hud::Client.count).to eq(1)
        expect(client.full_name).to eq('Client Older')
      end
    end

    describe 'same day update' do
      before(:all) do
        file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/export_date_fixtures/date_updated_same_day'
        import(file_path, @data_source)
      end

      it 'Client One is changed' do
        client = GrdaWarehouse::Hud::Client.first
        expect(GrdaWarehouse::Hud::Client.count).to eq(1)
        expect(client.full_name).to eq('Client Same')
      end
    end

    describe 'newer update' do
      before(:all) do
        file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/export_date_fixtures/date_updated_newer'
        import(file_path, @data_source)
      end

      it 'Client One is changed' do
        client = GrdaWarehouse::Hud::Client.first
        expect(GrdaWarehouse::Hud::Client.count).to eq(1)
        expect(client.full_name).to eq('Client Newer')
      end
    end
  end

  def import(file_path, data_source)
    source_file_path = File.join(file_path, 'source')
    import_path = File.join(file_path, data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(source_file_path, import_path)
    @delete_later << import_path unless import_path == source_file_path

    loader = HmisCsvTwentyTwenty::Loader::Loader.new(
      file_path: import_path,
      data_source_id: data_source.id,
      remove_files: false,
    )
    loader.load!
    loader.import!
  end

  def cleanup_files
    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
  end
end

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty, type: :model do
  describe 'When importing data with duplicate primary keys' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @delete_later = []
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/duplicate_primary_keys'
      import(file_path, @data_source)
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      cleanup_files
    end

    it 'the loader tables contain appropriate numbers of rows matching the CSVs' do
      aggregate_failures do
        expect(HmisCsvTwentyTwenty::Loader::Assessment.count).to eq(3)
        expect(HmisCsvTwentyTwenty::Loader::Client.count).to eq(5)
        expect(HmisCsvTwentyTwenty::Loader::Enrollment.count).to eq(5)
        expect(HmisCsvTwentyTwenty::Loader::Funder.count).to eq(3)
      end
    end

    it 'the importer tables contain appropriate numbers of rows matching the CSVs' do
      aggregate_failures do
        expect(HmisCsvTwentyTwenty::Importer::Assessment.count).to eq(3)
        expect(HmisCsvTwentyTwenty::Importer::Client.count).to eq(5)
        expect(HmisCsvTwentyTwenty::Importer::Enrollment.count).to eq(5)
        expect(HmisCsvTwentyTwenty::Importer::Funder.count).to eq(3)
      end
    end

    it 'the importer tables contain appropriate numbers of rows matching the CSVs which are ready to import' do
      aggregate_failures do
        expect(HmisCsvTwentyTwenty::Importer::Assessment.should_import.count).to eq(2)
        expect(HmisCsvTwentyTwenty::Importer::Client.should_import.count).to eq(3)
        expect(HmisCsvTwentyTwenty::Importer::Enrollment.should_import.count).to eq(4)
        expect(HmisCsvTwentyTwenty::Importer::Funder.should_import.count).to eq(1)
      end
    end

    it 'the warehouse tables contain appropriate numbers of rows' do
      aggregate_failures do
        expect(GrdaWarehouse::Hud::Assessment.count).to eq(2)
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(3)
        expect(GrdaWarehouse::Hud::Enrollment.count).to eq(4)
        expect(GrdaWarehouse::Hud::Funder.count).to eq(1)
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
    Delayed::Worker.new.work_off(2)
  end

  def cleanup_files
    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
  end
end

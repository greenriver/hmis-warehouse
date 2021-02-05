###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty, type: :model do
  describe 'When importing enrollments with one allowed project' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @delete_later = []
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      GrdaWarehouse::WhitelistedProjectsForClients.create(ProjectID: 'ALLOW', data_source_id: @data_source.id)
      file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/allowed_projects'
      import(file_path, @data_source)
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::WhitelistedProjectsForClients.delete_all
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      cleanup_files
    end

    it 'the database will have two source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(2)
    end

    it 'the database will have fourteen enrollments' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(14)
    end

    it 'the database will not include third client' do
      expect(GrdaWarehouse::Hud::Client.source.pluck(:PersonalID)).not_to include('C-3')
    end

    describe 'when importing updated enrollment data with an allowlist' do
      before(:all) do
        file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/allowed_projects'
        import(file_path, @data_source)
      end

      after(:all) do
        cleanup_files
      end

      it 'it doesn\'t add additional clients' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(2)
      end
    end
  end # end describe enrollments

  def import(file_path, data_source)
    source_file_path = File.join(file_path, 'source')
    import_path = File.join(file_path, data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(source_file_path, import_path)
    @delete_later << import_path unless import_path == source_file_path

    Importers::HmisAutoDetect::Local.new(
      data_source_id: @data_source.id,
      deidentified: false,
      allowed_projects: true,
      file_path: import_path,
    ).import!
  end

  def cleanup_files
    @delete_later.each do |path|
      FileUtils.rm_rf(path)
    end
  end
end

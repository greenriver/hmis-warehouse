###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwenty, type: :model do
  describe 'When importing enrollments with bad data on 1/1/2020' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @delete_later = []
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/bad_data'
      travel_to Time.local(2020, 1, 1) do
        import(file_path, @data_source)
      end
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      cleanup_files
    end

    it 'the database will have the correct number of source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(134)
    end

    it 'all clients would have last names' do
      expect(GrdaWarehouse::Hud::Client.source.where.not(LastName: nil).count).to eq(134)
    end

    it 'client DOBs appear correctly' do
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6798)
      expect(client.DOB).to eq('1967-05-08'.to_date)

      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6800)

      # 17-JUN-20 - expected to be in 2020 (not 1920) if the date is less than a year ahead
      expect(client.DOB).to eq('2020-06-17'.to_date)
    end

    it 'updated dates appear correctly' do
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6801)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2015-09-10 21:39:00')
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6803)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2015-09-10 21:39:00')
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6810)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2016-07-14 09:59:00')
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6812)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2019-04-28 05:17:00')
    end

    it 'the project has appropriate start and end dates' do
      project = GrdaWarehouse::Hud::Project.first
      expect(project.OperatingStartDate).to eq('2015-12-31'.to_date)
      expect(project.OperatingEndDate).to eq('2025-12-31'.to_date)
    end
  end

  describe 'When importing enrollments with bad data on 1/1/2021' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @delete_later = []
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/bad_data'
      travel_to Time.local(2021, 1, 1) do
        import(file_path, @data_source)
      end
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      cleanup_files
    end

    it 'client DOBs appear correctly' do
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6798)
      expect(client.DOB).to eq('1967-05-08'.to_date)

      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6800)

      # 17-JUN-20 - expected to be in 2020 (not 1920) if the date is in the past
      expect(client.DOB).to eq('2020-06-17'.to_date)
    end

    it 'updated dates appear correctly' do
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6801)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2015-09-10 21:39:00')
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6803)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2015-09-10 21:39:00')
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6810)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2016-07-14 09:59:00')
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6812)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2019-04-28 05:17:00')
    end
  end

  describe 'When importing enrollments with bad data on 12/30/2017' do
    before(:all) do
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      @delete_later = []
      @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
      file_path = 'drivers/hmis_csv_twenty_twenty/spec/fixtures/files/bad_data'
      travel_to Time.local(2017, 12, 30) do
        import(file_path, @data_source)
      end
    end

    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      HmisCsvTwentyTwenty::Utility.clear!
      GrdaWarehouse::Utility.clear!
      cleanup_files
    end

    it 'client DOBs appear correctly' do
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6798)
      expect(client.DOB).to eq('1967-05-08'.to_date)

      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6800)

      # 17-JUN-20 - expected to be in 1920 (not 2020) if the date is more than a year in the future
      expect(client.DOB).to eq('1920-06-17'.to_date)
    end

    it 'updated dates appear correctly' do
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6801)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2015-09-10 21:39:00')
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6803)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2015-09-10 21:39:00')
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6810)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('2016-07-14 09:59:00')
      client = GrdaWarehouse::Hud::Client.source.find_by(PersonalID: 6812)
      expect(client.DateUpdated.strftime('%Y-%m-%d %H:%M:%S')).to eq('1919-04-28 05:17:00')
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

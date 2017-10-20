require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ServiceHistory::Add, type: :model do
  describe 'When processing service history using add' do
    before(:all) do
      @delete_later = []
      setup_initial_imports()
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      @delete_later.each do |path|
        FileUtils.rm_rf(path)
      end
      # also clear out delayed job
      Delayed::Job.delete_all
    end

    it 'the database will have one destination client' do
      expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
    end
    it 'the database will have two source clients' do
      expect(GrdaWarehouse::Hud::Client.source.count).to eq(2)
    end
    it 'the destination client will have two source clients' do
      expect(GrdaWarehouse::Hud::Client.destination.first.source_clients.count).to eq(2)
    end
    it 'the destination client will have two source enrollments' do
      expect(GrdaWarehouse::Hud::Client.destination.first.source_enrollments.count).to eq(2)
    end

    describe 'adding should...' do
      before(:all) do
        GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
        Delayed::Worker.new.work_off(2)
      end
      it 'generate two entry records in the service history' do
        expect(GrdaWarehouse::ServiceHistory.entry.count).to eq(2)
      end
      # First two enrollments are TrackingMethod = 3 (night-by-night)
      it 'generate 20 service records' do
        expect(GrdaWarehouse::ServiceHistory.service.count).to eq(20)
      end
      it 'generage 10 unique dates of service' do
        expect(GrdaWarehouse::ServiceHistory.service.select(:date).distinct.count).to eq(10)
      end
    end
  end # end describe when processing

  describe 'When adding complex service histories ' do
    before(:all) do
      @delete_later = []
      setup_complex_import()  
    end
    after(:all) do
      # Because we are only running the import once, we have to do our own DB and file cleanup
      GrdaWarehouse::Utility.clear!
      @delete_later.each do |path|
        FileUtils.rm_rf(path)
      end
    end
    it 'two destination clients should exist' do
      expect(GrdaWarehouse::Hud::Client.destination.count).to eq(2)
    end
    it 'there should be three source enrollment records' do
      expect(GrdaWarehouse::Hud::Enrollment.count).to eq(3)
    end
    it 'there should be three service history entry records' do
      expect(GrdaWarehouse::ServiceHistory.entry.count).to eq(3)
    end
    it 'there should be two service history exit records' do
      expect(GrdaWarehouse::ServiceHistory.exit.count).to eq(2)
    end
    it 'it should import all source services regardless of enrollment start and end' do
      client = GrdaWarehouse::Hud::Client.destination.where(PersonalID: '1-1').first
      expect(client.source_services.count).to eq(10)
    end
    it 'it should ignore service records that fall outside of the enrollment dates' do
      client = GrdaWarehouse::Hud::Client.destination.where(PersonalID: '1-1').first
      expect(client.service_history.service.count).to eq(7)
    end
    it 'it should generate service history records for entry-exit projects' do
      
    end
  end # end


  def setup_complex_import
    ds_1 = GrdaWarehouse::DataSource.create(name: 'First Data Source', short_name: 'FDS', source_type: :sftp)
    warehouse_ds = GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'Warehouse', source_type: nil)
    {
      'spec/fixtures/files/service_history/tracking_methods' => ds_1,
    }.each do |path, data_source|
      source_file_path = File.join(path, 'source')
      import_path = File.join(path, data_source.id.to_s)
      # duplicate the fixture file as it gets manipulated
      FileUtils.cp_r(source_file_path, import_path)
      @delete_later << import_path unless import_path == source_file_path
  
      importer = Importers::HMISSixOneOne::Base.new(
        file_path: path,
        data_source_id: data_source.id,
        remove_files: false
      )
      importer.import!
    end
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::CalculateProjectTypes.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Update.new.run!
    Delayed::Worker.new.work_off(2)
  end

  def setup_initial_imports
    ds_1 = GrdaWarehouse::DataSource.create(name: 'First Data Source', short_name: 'FDS', source_type: :sftp)
    ds_2 = GrdaWarehouse::DataSource.create(name: 'Second Data Source', short_name: 'SDS', source_type: :sftp)
    warehouse_ds = GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'Warehouse', source_type: nil)
    {
      'spec/fixtures/files/service_history/initial_ds_1' => ds_1,
      'spec/fixtures/files/service_history/initial_ds_2' => ds_2,
    }.each do |path, data_source|
      source_file_path = File.join(path, 'source')
      import_path = File.join(path, data_source.id.to_s)
      # duplicate the fixture file as it gets manipulated
      FileUtils.cp_r(source_file_path, import_path)
      @delete_later << import_path unless import_path == source_file_path
  
      importer = Importers::HMISSixOneOne::Base.new(
        file_path: path,
        data_source_id: data_source.id,
        remove_files: false
      )
      importer.import!
    end
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::CalculateProjectTypes.new.run!
  end  
end
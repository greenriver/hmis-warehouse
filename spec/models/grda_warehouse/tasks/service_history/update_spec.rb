require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ServiceHistory::Update, type: :model do
    describe 'When processing service history using update' do
      before(:all) do
        @delete_later = []
        setup_initial_imports()
        load_third_import()
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
        expect(GrdaWarehouse::Hud::Client.destination.first.source_enrollments.count).to eq(3)
      end
  
    describe 'updating should...' do
      it 'the destination client will have two source clients' do
        expect(GrdaWarehouse::Hud::Client.destination.first.source_clients.count).to eq(2)
      end
      it 'the destination client will have three source enrollments' do
        expect(GrdaWarehouse::Hud::Client.destination.first.source_enrollments.count).to eq(3)
      end
      it 'result in three entry records in the service history' do
        expect(GrdaWarehouse::ServiceHistory.entry.count).to eq(3)
      end
      # All enrollments are TrackingMethod = 3 (night-by-night)
      it 'generate 23 service records' do
        expect(GrdaWarehouse::ServiceHistoryService.service.count).to eq(23)
      end
      it 'generage 13 unique dates of service' do
        expect(GrdaWarehouse::ServiceHistory.service.select(:date).distinct.count).to eq(13)
      end
    end

    describe 'importing an out of order data set should...' do
      before(:all) do
        GrdaWarehouse::Tasks::ServiceHistory::Update.new.run!
        Delayed::Worker.new.work_off(2)
        load_fourth_import()
        GrdaWarehouse::Tasks::ServiceHistory::Update.new.run!
        Delayed::Worker.new.work_off(2)
      end
      it 'result in four enrollments' do
        expect(GrdaWarehouse::ServiceHistory.entry.count).to eq(4)
      end

      it "generate 26 service records" do
        expect(GrdaWarehouse::ServiceHistory.service.count).to eq(26)
      end

      it 'generate 13 service records' do
        expect(GrdaWarehouse::ServiceHistory.service.select(:date).distinct.count).to eq(13)
      end

      it 'the effective export end date is 2016-12-15' do
        expect(GrdaWarehouse::Hud::Export.order(id: :asc).last.effective_export_end_date).to eq('2016-12-15'.to_date)
      end
    end # end importing an out of order data set
  end # end describe when processing

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
    GrdaWarehouse::Tasks::ServiceHistory::Update.new.run!
    Delayed::Worker.new.work_off(2)
  end

  def load_third_import
    ds_1 = GrdaWarehouse::DataSource.find_by(name: 'First Data Source', short_name: 'FDS', source_type: :sftp)
    {
      'spec/fixtures/files/service_history/second_ds_1' => ds_1,
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
    GrdaWarehouse::Tasks::ServiceHistory::Update.new.run!
    Delayed::Worker.new.work_off(2)
  end

  def load_fourth_import
    ds_2 = GrdaWarehouse::DataSource.find_by(name: 'Second Data Source', short_name: 'SDS', source_type: :sftp)
    {
      'spec/fixtures/files/service_history/second_ds_2' => ds_2,
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
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
      GrdaWarehouse::Tasks::CalculateProjectTypes.new.run!
    end
  end
end
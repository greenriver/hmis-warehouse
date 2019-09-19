require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseClientsProcessed, type: :model do
  before(:all) do
    @delete_later = []
    setup_initial_imports
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
    Delayed::Worker.new.work_off(2)
    GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!
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

  it 'has some records in the materialized view' do
    expect(GrdaWarehouse::ServiceHistoryServiceMaterialized.count).to_not eq(0)
  end

  def setup_initial_imports
    ds_1 = GrdaWarehouse::DataSource.create(name: 'First Data Source', short_name: 'FDS', source_type: :sftp)
    GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'Warehouse', source_type: nil)
    {
      'spec/fixtures/files/service_history/materialized' => ds_1,
    }.each do |path, data_source|
      source_file_path = File.join(path, 'source')
      import_path = File.join(path, data_source.id.to_s)
      # duplicate the fixture file as it gets manipulated
      FileUtils.cp_r(source_file_path, import_path)
      @delete_later << import_path unless import_path == source_file_path

      importer = Importers::HMISSixOneOne::Base.new(
        file_path: path,
        data_source_id: data_source.id,
        remove_files: false,
      )
      importer.import!
    end
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::ProjectCleanup.new.run!
  end
end

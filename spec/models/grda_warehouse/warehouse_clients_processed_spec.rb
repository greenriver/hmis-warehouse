require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseClientsProcessed, type: :model do
  before(:all) do
    @delete_later = []
    setup_initial_imports
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
    Delayed::Worker.new.work_off(2)

    # Add includes_verified_days_homeless override
    GrdaWarehouse::Hud::Project.find_by(ProjectName: 'Services Only').update(include_in_days_homeless_override: true)
    # Update
    GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!
    @client_ids = GrdaWarehouse::ServiceHistoryServiceMaterialized.distinct.pluck(:client_id)
    GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: @client_ids)
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

  it 'sets up the harness' do
    expect(GrdaWarehouse::ServiceHistoryServiceMaterialized.count).to_not eq(0)
    expect(GrdaWarehouse::WarehouseClientsProcessed.count).to be > 0
    expect(GrdaWarehouse::WarehouseClientsProcessed.count).to eq(@client_ids.count)
    expect(GrdaWarehouse::Hud::Project.homeless.count).to be > 0
    expect(GrdaWarehouse::Hud::Project.includes_verified_days_homeless.count).to eq(1)
  end

  it 'counts homeless days' do
    client = GrdaWarehouse::Hud::Client.destination.find_by(LastName: 'Two')

    expect(client.source_enrollments.joins(:project).merge(GrdaWarehouse::Hud::Project.homeless).count).to be > 0
  end

  it 'includes the override days in the plus overrides count' do
    client = GrdaWarehouse::Hud::Client.destination.find_by(LastName: 'Two')
    expect(client.processed_service_history.days_homeless_plus_overrides).to be > client.processed_service_history.homeless_days
  end

  it 'excludes overlapping homeless days' do
    client = GrdaWarehouse::Hud::Client.destination.find_by(LastName: 'Two')

    homeless_count = client.service_history_services.joins(service_history_enrollment: :project).merge(GrdaWarehouse::Hud::Project.homeless).count
    override_count = client.service_history_services.joins(service_history_enrollment: :project).merge(GrdaWarehouse::Hud::Project.includes_verified_days_homeless).count

    expect(client.processed_service_history.days_homeless_plus_overrides).to be < homeless_count + override_count
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

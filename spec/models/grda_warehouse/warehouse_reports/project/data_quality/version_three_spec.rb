require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionThree, type: :model do

  describe 'a single project report' do
    before(:all) do
      import_fixture
    end
    after(:all) do
      cleanup_fixture
    end

    let(:project) { GrdaWarehouse::Hud::Project.first }
    let(:report) { create :data_quality_report_base, :single_project }

    it 'loads all clients' do
      expect(report.clients.count).to eq 103
    end

    it 'loads the same clients by project' do
      clients = report.clients.map{|client| client[:id]}
      project_clients = report.clients_for_project(project.id).map{|client| client[:id]}

      expect(project_clients.count).to eq 103
      expect(clients).to match_array project_clients
    end
  end

  describe 'a project group report' do
    before(:all) do
      import_fixture
    end
    after(:all) do
      cleanup_fixture
    end

    let(:report) { create :data_quality_report_base, :project_group }

    it 'has 3 projects' do
      expect(report.projects.count).to eq 3
    end

    it 'loads all clients' do
      expect(report.clients.count).to eq 136
    end
  end

  def import_fixture
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
    warehouse_ds = GrdaWarehouse::DataSource.create(name: 'Warehouse', short_name: 'Warehouse', source_type: nil)
    @file_path = 'spec/fixtures/files/importers/hmis_six_on_one/project_data_quality'
    @source_file_path = File.join(@file_path, 'source')
    @import_path = File.join(@file_path, @data_source.id.to_s)
    # duplicate the fixture file as it gets manipulated
    FileUtils.cp_r(@source_file_path, @import_path)

    importer = Importers::HMISSixOneOne::Base.new(file_path: @file_path, data_source_id: @data_source.id, remove_files: false)
    importer.import!
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    GrdaWarehouse::Tasks::CalculateProjectTypes.new.run!
    GrdaWarehouse::Tasks::ServiceHistory::Update.new(force_sequential_processing: true).run!
    Delayed::Worker.new.work_off(2)
  end

  def cleanup_fixture
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    FileUtils.rm_rf(@import_path) unless @import_path == @file_path
  end

end
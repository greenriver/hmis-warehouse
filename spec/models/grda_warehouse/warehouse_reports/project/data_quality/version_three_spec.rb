require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionThree, type: :model do
  # NOTE: The date range of the report is limited and will not include everyone in the import file
  describe 'project data quality' do
    before(:all) do
      import_fixture
    end
    after(:all) do
      cleanup_fixture
    end
    describe 'a single project report' do
      let(:report) { create :data_quality_report_version_three, :single_project }
      let(:project) { report.project }

      it 'loads clients with enrollments open during the report range' do
        # FIXME: This seems to waffle between 90 and 92
        expect(report.clients.count).to eq 92
      end

      it 'loads the same clients by project' do
        clients_ids = report.clients.map{|client| client[:id]}.uniq
        project_clients = report.clients_for_project(project.id).map{|client| client[:id]}.uniq

        expect(project_clients.count).to eq 92
        expect(clients_ids).to match_array project_clients
      end

      describe 'when looking at universal elements' do
        before do
          report.start_report()
          report.calculate_missing_universal_elements()
        end
        it 'has the appropriate number of total clients' do
          count = report.report['total_clients']
          range = ::Filters::DateRange.new(start: report.start, end: report.end)
          open_enrollments = GrdaWarehouse::Hud::Enrollment.open_during_range(range).where(ProjectID: report.project.ProjectID).distinct.select(:PersonalID).count
          expect(count).to eq 90
          expect(count).to eq open_enrollments
        end

        it 'has the appropriate number of missing names' do
          count = report.report['missing_name']
          expect(count).to eq 37
        end

        it 'has the appropriate number of missing ssn' do
          count = report.report['missing_ssn']

          client_ids = report.clients.map{|client| client[:id]}.uniq
          missing = GrdaWarehouse::Hud::Client.where(id: client_ids, SSNDataQuality: [99, nil, '']).pluck(:id)
          missing += GrdaWarehouse::Hud::Client.where(id: client_ids, SSN: [nil, '']).pluck(:id)

          expect(count).to eq 70
          expect(count).to eq missing.uniq.count
        end
      end
    end

    describe 'a project group report' do
      let(:report) { create :data_quality_report_version_three, :project_group }

      it 'loads all projects' do
        expect(report.projects.count).to eq 3
      end

      it 'loads all clients' do
        expect(report.clients.map{|m| m[:id] }.uniq.count).to eq 112
      end
    end
  end

  def import_fixture
    @data_source = GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :s3)
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
###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::ArchiveReportService, type: :service do
  # Create test model classes and tables
  before(:all) do
    connection = GrdaWarehouseBase.connection

    # Create test clients table
    unless connection.table_exists?(:test_archive_clients)
      connection.create_table :test_archive_clients, force: true do |t|
        t.integer :report_id, null: false
        t.string :name
        t.integer :age
        t.timestamps
      end
    end

    # Create test projects table
    unless connection.table_exists?(:test_archive_projects)
      connection.create_table :test_archive_projects, force: true do |t|
        t.integer :report_id, null: false
        t.string :name
        t.timestamps
      end
    end
  end

  after(:all) do
    connection = GrdaWarehouseBase.connection
    connection.drop_table :test_archive_clients if connection.table_exists?(:test_archive_clients)
    connection.drop_table :test_archive_projects if connection.table_exists?(:test_archive_projects)
  end

  # Test model classes
  let(:test_client_class) do
    klass = Class.new(GrdaWarehouseBase) do
      self.table_name = 'test_archive_clients'
      belongs_to :report, class_name: 'SimpleReports::ReportInstance', foreign_key: :report_id
    end
    class_name = "TestArchiveClient#{SecureRandom.hex(8)}"
    Object.const_set(class_name, klass)
    klass
  end

  let(:test_project_class) do
    klass = Class.new(GrdaWarehouseBase) do
      self.table_name = 'test_archive_projects'
      belongs_to :report, class_name: 'SimpleReports::ReportInstance', foreign_key: :report_id
    end
    class_name = "TestArchiveProject#{SecureRandom.hex(8)}"
    Object.const_set(class_name, klass)
    klass
  end

  # Create a test report model
  let(:test_report_class) do
    client_class_ref = test_client_class
    project_class_ref = test_project_class

    klass = Class.new(SimpleReports::ReportInstance) do
      include ReportArchival

      has_many_attached :clients_csv
      has_many_attached :projects_csv

      define_method :archival_csv_config do
        {
          clients_csv: {
            association: :test_clients,
            filename: -> { "clients-#{id}.csv" },
          },
          projects_csv: {
            association: :test_projects,
            filename: -> { "projects-#{id}.csv" },
          },
        }
      end

      # Associations that return ActiveRecord::Relation
      define_method :test_clients do
        client_class_ref.where(report_id: id)
      end

      define_method :test_projects do
        project_class_ref.where(report_id: id)
      end
    end
    # Give the class a name so Active Storage can work properly
    class_name = "TestReportForArchiveService#{SecureRandom.hex(8)}"
    Object.const_set(class_name, klass)
    klass
  end

  let(:report) { test_report_class.create!(user_id: User.system_user.id) }
  let(:service) { described_class.new(report) }

  # Create test data before each test
  before do
    test_client_class.create!(report_id: report.id, name: 'Client 1', age: nil)
    test_client_class.create!(report_id: report.id, name: 'Client 2', age: nil)
    test_project_class.create!(report_id: report.id, name: 'Project 1')
    test_project_class.create!(report_id: report.id, name: 'Project 2')
  end

  describe '#eligible?' do
    it 'returns true when report includes concern and has non-empty config' do
      expect(service.eligible?).to be true
    end

    it 'returns false when report does not include concern' do
      ineligible_report = SimpleReports::ReportInstance.create!(user_id: User.system_user.id)
      ineligible_service = described_class.new(ineligible_report)
      expect(ineligible_service.eligible?).to be false
    end

    it 'returns false when config is empty' do
      allow(report).to receive(:archival_csv_config).and_return({})
      expect(service.eligible?).to be false
    end
  end

  describe '#archive!' do
    context 'when report is eligible' do
      it 'generates and attaches CSV files' do
        service.archive!

        expect(report.clients_csv.attached?).to be true
        expect(report.projects_csv.attached?).to be true
      end

      it 'updates archival metadata with expected files' do
        service.archive!

        # archived? returns true when CSV files exist
        expect(report.archived?).to be true
        expect(report.purged?).to be false
        expect(report.archival_metadata['expected_file_count']).to eq(2)
        expect(report.archival_metadata['expected_files']).to include('clients_csv', 'projects_csv')
      end

      it 'adds file status to metadata' do
        service.archive!

        files = report.archival_metadata['files']
        expect(files['clients_csv']).to be_present
        expect(files['clients_csv']['attached']).to be true
        expect(files['projects_csv']).to be_present
        expect(files['projects_csv']['attached']).to be true
      end

      it 'generates correct CSV content from associations' do
        service.archive!

        csv_content = report.clients_csv.first.download
        parsed = CSV.parse(csv_content, headers: true)
        expect(parsed.length).to eq(2)
        expect(parsed.map { |r| r['name'] }).to contain_exactly('Client 1', 'Client 2')
      end

      it 'generates correct CSV content from associations for projects' do
        service.archive!

        csv_content = report.projects_csv.first.download
        parsed = CSV.parse(csv_content, headers: true)
        expect(parsed.length).to eq(2)
        expect(parsed.map { |r| r['name'] }).to contain_exactly('Project 1', 'Project 2')
      end

      it 'marks archival as complete' do
        service.archive!

        expect(report.archived?).to be true
        expect(report.archival_metadata['archived_at']).to be_present
      end

      it 'does not set grace period metadata (set at completion or reload)' do
        service.archive!

        # These are set at report completion or on reload
        expect(report.archival_metadata['grace_period_days']).to be_nil
        expect(report.archival_metadata['purge_eligible_at']).to be_nil
      end

      it 'does not purge database data immediately' do
        service.archive!

        # Database data should still be accessible (not purged)
        expect(report.archival_metadata['purged_at']).to be_nil
        # Verify data is still in database
        expect(report.test_clients.count).to eq(2)
      end

      it 'uses existing expected_files from metadata if present' do
        # Set up metadata with expected_files
        report.update_column(:archival_metadata, { expected_files: ['clients_csv'] })
        service.archive!

        # Should only archive clients_csv, not projects_csv
        expect(report.clients_csv.attached?).to be true
        expect(report.projects_csv.attached?).to be false
        expect(report.archival_metadata['expected_files']).to eq(['clients_csv'])
      end
    end

    context 'when report is not eligible' do
      it 'does not archive' do
        ineligible_report = SimpleReports::ReportInstance.create!(user_id: User.system_user.id)
        ineligible_service = described_class.new(ineligible_report)
        result = ineligible_service.archive!

        expect(result).to be false
        expect(ineligible_report.archival_metadata).to be_nil
      end
    end

    context 'when archival_csv_config is blank' do
      it 'does not archive' do
        allow(report).to receive(:archival_csv_config).and_return({})
        service.archive!

        expect(report.clients_csv.attached?).to be false
      end
    end

    context 'when file attachment fails' do
      it 'continues processing other files and tracks errors' do
        allow(report).to receive(:test_clients).and_raise(StandardError.new('Data fetch failed'))

        result = service.archive!

        # Should still process projects_csv
        expect(report.projects_csv.attached?).to be true
        # Should track error for clients_csv
        expect(service.errors).to be_present
        expect(service.errors.first[:attachment]).to eq(:clients_csv)
        expect(result).to be false # Returns false when errors occur
      end
    end

    context 'when report is already archived' do
      before do
        # Archive the report first
        service.archive!
        report.reload
      end

      it 'skips re-archival if already complete' do
        allow(Rails.logger).to receive(:info)
        initial_metadata = report.archival_metadata.dup

        result = service.archive!

        expect(result).to be true
        expect(Rails.logger).to have_received(:info).with(/already archived, skipping/)
        # Metadata should not change
        expect(report.reload.archival_metadata['archived_at']).to eq(initial_metadata['archived_at'])
      end
    end

    context 'when files are already attached' do
      before do
        report.clients_csv.attach(
          io: StringIO.new('id,name\n1,Client 1'),
          filename: 'clients-1.csv',
          content_type: 'text/csv',
        )
      end

      it 'skips attaching already attached files' do
        allow(Rails.logger).to receive(:info)
        initial_blob_id = report.clients_csv.first.id

        service.archive!

        expect(Rails.logger).to have_received(:info).with(/already attached.*skipping/)
        # Blob should remain the same
        expect(report.reload.clients_csv.first.id).to eq(initial_blob_id)
      end
    end

    context 'when association is missing' do
      it 'raises error and tracks it' do
        allow(report).to receive(:archival_csv_config).and_return(
          {
            clients_csv: {
              association: :nonexistent_association,
              filename: -> { "clients-#{report.id}.csv" },
            },
          },
        )

        result = service.archive!

        expect(result).to be false
        expect(service.errors).to be_present
        expect(service.errors.first[:attachment]).to eq(:clients_csv)
      end
    end

    context 'when filename generation fails' do
      it 'handles filename generation errors' do
        allow(report).to receive(:archival_csv_config).and_return(
          {
            clients_csv: {
              association: :test_clients,
              filename: -> { raise StandardError, 'Filename error' },
            },
          },
        )

        result = service.archive!

        expect(result).to be false
        expect(service.errors).to be_present
      end
    end

    context 'with additional columns' do
      it 'generates CSV with all model columns' do
        # Update a client to have an age
        test_client_class.where(report_id: report.id).first.update!(age: 25)
        test_client_class.where(report_id: report.id).last.update!(age: 30)

        service.archive!

        csv_content = report.clients_csv.first.download
        parsed = CSV.parse(csv_content, headers: true)
        expect(parsed.length).to eq(2)
        # Verify age column is included
        expect(parsed.headers).to include('age')
        expect(parsed.map { |r| r['age'] }).to include('25', '30')
      end
    end

    context 'with empty records' do
      let(:empty_report) do
        # Create a fresh report without any data
        test_report_class.create!(user_id: User.system_user.id).tap do |r|
          # Ensure no test clients exist for this report
          test_client_class.where(report_id: r.id).delete_all
        end
      end
      let(:empty_service) { described_class.new(empty_report) }

      it 'handles empty associations gracefully by creating CSV with headers only' do
        empty_report.reload
        empty_service.archive!

        # Empty associations should still create CSV files with headers
        expect(empty_report.clients_csv.attached?).to be true
        csv_content = empty_report.clients_csv.first.download
        parsed = CSV.parse(csv_content, headers: true)
        expect(parsed.headers).to be_present # Should have column headers
        expect(parsed.length).to eq(0) # But no data rows
      end
    end
  end
end

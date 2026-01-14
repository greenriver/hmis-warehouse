###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::PurgeArchivedReportDataService, type: :service do
  # Create test model classes and tables
  before(:all) do
    connection = GrdaWarehouseBase.connection

    # Create test clients table
    unless connection.table_exists?(:test_purge_clients)
      connection.create_table :test_purge_clients, force: true do |t|
        t.integer :report_id, null: false
        t.integer :client_id
        t.integer :reporting_age
        t.timestamps
      end
    end

    # Create test projects table
    unless connection.table_exists?(:test_purge_projects)
      connection.create_table :test_purge_projects, force: true do |t|
        t.integer :report_id, null: false
        t.integer :project_id
        t.timestamps
      end
    end
  end

  after(:all) do
    connection = GrdaWarehouseBase.connection
    connection.drop_table :test_purge_clients if connection.table_exists?(:test_purge_clients)
    connection.drop_table :test_purge_projects if connection.table_exists?(:test_purge_projects)
  end

  # Test model classes - create and name them first
  let(:test_client_class) do
    klass = Class.new(GrdaWarehouseBase) do
      self.table_name = 'test_purge_clients'
      belongs_to :report, class_name: 'SimpleReports::ReportInstance', foreign_key: :report_id
    end
    class_name = "TestPurgeClient#{SecureRandom.hex(8)}"
    Object.const_set(class_name, klass)
    klass
  end

  let(:test_project_class) do
    klass = Class.new(GrdaWarehouseBase) do
      self.table_name = 'test_purge_projects'
      belongs_to :report, class_name: 'SimpleReports::ReportInstance', foreign_key: :report_id
    end
    class_name = "TestPurgeProject#{SecureRandom.hex(8)}"
    Object.const_set(class_name, klass)
    klass
  end

  # Create a test report model
  let(:test_report_class) do
    # Ensure model classes are created and named first
    client_class = test_client_class
    project_class = test_project_class

    klass = Class.new(SimpleReports::ReportInstance) do
      include ReportArchival

      has_many_attached :clients_csv
      has_many_attached :projects_csv

      define_method :archival_csv_config do
        {
          clients_csv: {
            association: :clients,
            filename: -> { "clients-#{id}.csv" },
          },
          projects_csv: {
            association: :projects,
            filename: -> { "projects-#{id}.csv" },
          },
        }
      end
    end
    # Give the class a name so Active Storage can work properly
    class_name = "TestReportForPurgeService#{SecureRandom.hex(8)}"
    Object.const_set(class_name, klass)

    # Define associations after class is named, using class_eval to ensure proper context
    # Capture class names as strings for use in class_eval
    client_class_name = client_class.name
    project_class_name = project_class.name
    klass.class_eval do
      has_many :clients, class_name: client_class_name, foreign_key: :report_id, dependent: :destroy
      has_many :projects, class_name: project_class_name, foreign_key: :report_id, dependent: :destroy
    end

    # Force Rails to process the associations
    klass.reflect_on_association(:clients)
    klass.reflect_on_association(:projects)

    klass
  end

  let(:user) { User.system_user }
  let(:report) { test_report_class.create!(user_id: user.id) }
  let(:service) { described_class.new(report, dry_run: false) }

  # Helper methods to DRY up test setup
  def generate_clients_csv(clients)
    CSV.generate do |csv|
      csv << ['id', 'client_id', 'reporting_age']
      clients.each do |client|
        csv << [client.id, client.client_id, client.reporting_age]
      end
    end
  end

  def attach_clients_csv(report, csv_content, filename: nil)
    report.clients_csv.attach(
      io: StringIO.new(csv_content),
      filename: filename || "clients-#{report.id}.csv",
      content_type: 'text/csv',
    )
  end

  def attach_projects_csv(report, csv_content, filename: nil)
    report.projects_csv.attach(
      io: StringIO.new(csv_content),
      filename: filename || "projects-#{report.id}.csv",
      content_type: 'text/csv',
    )
  end

  def setup_archival_metadata(report, expected_files:, purge_eligible_at: nil, purged_at: nil)
    metadata = {
      archived_at: Time.current.iso8601,
      expected_files: expected_files,
    }
    metadata[:purge_eligible_at] = purge_eligible_at.iso8601 if purge_eligible_at
    metadata[:purged_at] = purged_at.iso8601 if purged_at

    report.update!(
      completed_at: Time.current,
      archival_metadata: metadata,
    )
  end

  def setup_archived_report_with_clients(report, client_count: 1, expected_files: ['clients_csv'], purge_eligible_at: nil)
    clients = client_count.times.map do |i|
      test_client_class.create!(
        report_id: report.id,
        client_id: i + 1,
        reporting_age: 25 + i,
      )
    end

    csv_content = generate_clients_csv(clients)
    attach_clients_csv(report, csv_content)

    setup_archival_metadata(
      report,
      expected_files: expected_files,
      purge_eligible_at: purge_eligible_at,
    )

    clients
  end

  describe '#purge!' do
    context 'when report is not found' do
      let(:service) { described_class.new(nil) }

      it 'returns error' do
        result = service.purge!
        expect(result[:success]).to be false
        expect(result[:errors]).to include('Report not found')
      end
    end

    context 'when report is not archived' do
      before do
        report.update!(completed_at: Time.current)
      end

      it 'returns false and includes error' do
        result = service.purge!
        expect(result[:success]).to be false
        expect(result[:errors]).to include('Report has not been archived or archival is not complete')
      end
    end

    context 'when archival is incomplete' do
      before do
        report.update!(
          completed_at: Time.current,
          archival_metadata: {
            archived_at: Time.current.iso8601,
            expected_files: ['clients_csv', 'projects_csv'],
          },
        )
        report.clients_csv.attach(
          io: StringIO.new('id,name\n1,Client 1'),
          filename: 'clients-1.csv',
          content_type: 'text/csv',
        )
        # Missing projects_csv
      end

      it 'returns false and includes error' do
        result = service.purge!
        expect(result[:success]).to be false
        expect(result[:errors]).to include('Report has not been archived or archival is not complete')
      end
    end

    context 'when CSV files are not accessible' do
      before do
        report.update!(
          completed_at: Time.current,
          archival_metadata: {
            archived_at: Time.current.iso8601,
            expected_files: ['clients_csv'],
          },
        )
        # Don't attach any files
      end

      it 'returns false and includes error' do
        result = service.purge!
        expect(result[:success]).to be false
        # Since no files are attached, archived? will fail first
        expect(result[:errors]).to include('Report has not been archived or archival is not complete')
      end
    end

    context 'when CSV data integrity check fails' do
      before do
        # Create database records
        client1 = test_client_class.create!(report_id: report.id, client_id: 1, reporting_age: 25)
        test_client_class.create!(report_id: report.id, client_id: 2, reporting_age: 30)

        # Attach CSV with different count (only 1 client instead of 2)
        csv_content = generate_clients_csv([client1])
        attach_clients_csv(report, csv_content, filename: 'clients-1.csv')

        setup_archival_metadata(report, expected_files: ['clients_csv'], purge_eligible_at: 1.day.ago)
      end

      it 'returns false when counts do not match' do
        # CSV has 1 record, database has 2 records - counts don't match
        result = service.purge!
        expect(result[:success]).to be false
        expect(result[:errors]).to include('CSV data integrity check failed (row counts do not match database)')
      end

      it 'does not update report updated_at timestamp even when integrity check fails' do
        # reload to get fresh database state - the database is truncating nanoseconds off of the timestamp
        report.reload
        original_updated_at = report.updated_at

        result = service.purge!

        # Verify that the integrity check actually failed
        expect(result[:success]).to be false
        expect(result[:errors]).to include('CSV data integrity check failed (row counts do not match database)')

        # Verify timestamp was not updated
        report.reload
        expect(report.updated_at).to eq(original_updated_at)
      end
    end

    context 'when report is already purged' do
      before do
        attach_clients_csv(report, 'id,name\n1,Client 1', filename: 'clients-1.csv')
        setup_archival_metadata(report, expected_files: ['clients_csv'], purged_at: 1.day.ago)
      end

      it 'returns false and includes error' do
        result = service.purge!
        expect(result[:success]).to be false
        expect(result[:errors]).to include('Report data has already been purged')
      end
    end

    context 'when grace period has not expired' do
      before do
        setup_archived_report_with_clients(
          report,
          client_count: 1,
          purge_eligible_at: 1.day.from_now,
        )
      end

      it 'returns false' do
        result = service.purge!
        expect(result[:success]).to be false
        expect(result[:errors].first).to match(/Grace period has not expired/)
      end
    end

    context 'when force is enabled' do
      before do
        setup_archived_report_with_clients(
          report,
          client_count: 1,
          purge_eligible_at: 1.day.from_now,
        )
      end

      let(:forced_service) { described_class.new(report, dry_run: false, force: true) }

      it 'successfully purges data when force is true' do
        result = forced_service.purge!

        expect(result[:success]).to be true
        expect(result[:deleted_counts]).to include(clients: 1)
        expect(test_client_class.where(report_id: report.id).count).to eq(0)
      end
    end

    context 'when in dry-run mode' do
      let(:service) { described_class.new(report, dry_run: true) }

      before do
        # Create database records
        client1 = test_client_class.create!(report_id: report.id, client_id: 1, reporting_age: 25)
        client2 = test_client_class.create!(report_id: report.id, client_id: 2, reporting_age: 30)
        test_project_class.create!(report_id: report.id, project_id: 100)

        # Attach CSV with matching counts
        csv_content = generate_clients_csv([client1, client2])
        attach_clients_csv(report, csv_content, filename: 'clients-1.csv')

        setup_archival_metadata(report, expected_files: ['clients_csv'], purge_eligible_at: 1.day.ago)
      end

      it 'returns would_delete summary without deleting data' do
        result = service.purge!

        expect(result[:success]).to be true
        expect(result[:dry_run]).to be true
        expect(result[:would_delete]).to include(
          clients: 2,
          projects: 1,
        )

        # Verify data is still present
        expect(test_client_class.where(report_id: report.id).count).to eq(2)
        expect(test_project_class.where(report_id: report.id).count).to eq(1)
      end

      it 'does not update report updated_at timestamp in dry-run mode' do
        # reload to get fresh database state - the database is truncating nanoseconds off of the timestamp
        report.reload
        original_updated_at = report.updated_at
        service.purge!

        report.reload
        expect(report.updated_at).to eq(original_updated_at)
      end
    end

    context 'when all safety checks pass' do
      let!(:client1) do
        test_client_class.create!(
          report_id: report.id,
          client_id: 1,
          reporting_age: 25,
        )
      end
      let!(:client2) do
        test_client_class.create!(
          report_id: report.id,
          client_id: 2,
          reporting_age: 30,
        )
      end
      let!(:project1) do
        test_project_class.create!(
          report_id: report.id,
          project_id: 100,
        )
      end
      let!(:project2) do
        test_project_class.create!(
          report_id: report.id,
          project_id: 200,
        )
      end

      before do
        # Attach CSV with matching counts
        csv_content = generate_clients_csv([client1, client2])
        attach_clients_csv(report, csv_content, filename: 'clients-1.csv')

        setup_archival_metadata(report, expected_files: ['clients_csv'], purge_eligible_at: 1.day.ago)
      end

      it 'deletes all database records for the report' do
        # Verify records exist before purge
        expect(test_client_class.where(report_id: report.id).count).to eq(2)
        expect(test_project_class.where(report_id: report.id).count).to eq(2)

        result = service.purge!

        expect(result[:success]).to be true
        expect(result[:deleted_counts]).to include(
          clients: 2,
          projects: 2,
        )

        # Verify records are deleted
        expect(test_client_class.where(report_id: report.id).count).to eq(0)
        expect(test_project_class.where(report_id: report.id).count).to eq(0)
      end

      it 'updates archival metadata with purged_at timestamp' do
        result = service.purge!

        expect(result[:success]).to be true
        report.reload
        expect(report.archival_metadata['purged_at']).to be_present
      end

      it 'does not update report updated_at timestamp' do
        # reload to get fresh database state - the database is truncating nanoseconds off of the timestamp
        report.reload
        original_updated_at = report.updated_at
        service.purge!

        # Reload to get fresh database state
        report.reload
        expect(report.updated_at).to eq(original_updated_at)
      end

      it 'does not delete records from other reports' do
        # Create another report with its own data
        other_report = test_report_class.create!(user_id: user.id)
        other_client = test_client_class.create!(report_id: other_report.id, client_id: 999, reporting_age: 40)

        result = service.purge!

        expect(result[:success]).to be true

        # Verify other report's data is still present
        expect(test_client_class.where(report_id: other_report.id).count).to eq(1)
        expect(test_client_class.find_by(id: other_client.id)).to be_present
      end
    end
  end

  describe 'csv_files_accessible?' do
    before do
      report.update!(
        archival_metadata: {
          archived_at: Time.current.iso8601,
          expected_files: ['clients_csv', 'projects_csv'],
        },
      )
    end

    it 'returns false when expected_files is empty' do
      report.update_column(:archival_metadata, { archived_at: Time.current.iso8601, expected_files: [] })
      service = described_class.new(report)
      expect(service.send(:csv_files_accessible?)).to be false
    end

    it 'returns false when attachment is not attached' do
      service = described_class.new(report)
      expect(service.send(:csv_files_accessible?)).to be false
    end

    it 'returns true when all expected files are attached' do
      report.clients_csv.attach(
        io: StringIO.new('id,name\n1,Client 1'),
        filename: 'clients-1.csv',
        content_type: 'text/csv',
      )
      report.projects_csv.attach(
        io: StringIO.new('id,name\n1,Project 1'),
        filename: 'projects-1.csv',
        content_type: 'text/csv',
      )

      service = described_class.new(report)
      expect(service.send(:csv_files_accessible?)).to be true
    end
  end

  describe 'csv_data_integrity_verified?' do
    before do
      client1 = test_client_class.create!(report_id: report.id, client_id: 1, reporting_age: 25)
      client2 = test_client_class.create!(report_id: report.id, client_id: 2, reporting_age: 30)

      csv_content = generate_clients_csv([client1, client2])
      attach_clients_csv(report, csv_content, filename: 'clients-1.csv')

      setup_archival_metadata(report, expected_files: ['clients_csv'])
    end

    it 'returns true when counts match exactly' do
      service = described_class.new(report)
      expect(service.send(:csv_data_integrity_verified?)).to be true
    end

    it 'returns false when counts do not match exactly' do
      service = described_class.new(report)
      # Mock the counts to test exact matching requirement
      allow(service).to receive(:csv_row_count).and_return(100)
      allow(service).to receive(:database_row_count).and_return(101) # Even 1 record difference fails

      expect(service.send(:csv_data_integrity_verified?)).to be false
    end

    it 'skips integrity check when association is missing' do
      allow(report).to receive(:archival_csv_config).and_return(
        {
          clients_csv: {
            # No association specified
            filename: -> { "clients-#{report.id}.csv" },
          },
        },
      )

      service = described_class.new(report)
      expect(service.send(:csv_data_integrity_verified?)).to be true
    end
  end

  describe 'database_row_count' do
    before do
      test_client_class.create!(report_id: report.id, client_id: 1, reporting_age: 25)
      setup_archival_metadata(report, expected_files: ['clients_csv'])
    end

    it 'returns count from association' do
      service = described_class.new(report)
      count = service.send(:database_row_count, { association: :clients })
      expect(count).to eq(1)
    end

    it 'returns 0 when association name is missing' do
      service = described_class.new(report)
      count = service.send(:database_row_count, {})
      expect(count).to eq(0)
    end
  end

  describe 'delete_report_data' do
    before do
      test_client_class.create!(report_id: report.id, client_id: 1, reporting_age: 25)
      test_project_class.create!(report_id: report.id, project_id: 100)

      attach_clients_csv(report, 'id,client_id\n1,1', filename: 'clients-1.csv')
      attach_projects_csv(report, 'id,project_id\n1,100', filename: 'projects-1.csv')

      setup_archival_metadata(report, expected_files: ['clients_csv', 'projects_csv'], purge_eligible_at: 1.day.ago)
    end

    it 'deletes records' do
      service = described_class.new(report, dry_run: false, force: true)
      counts = service.send(:delete_report_data)

      expect(counts).to include(:clients, :projects)
      expect(test_client_class.where(report_id: report.id).count).to eq(0)
      expect(test_project_class.where(report_id: report.id).count).to eq(0)
    end

    it 'handles empty config gracefully' do
      allow(report).to receive(:archival_csv_config).and_return({})
      service = described_class.new(report)
      counts = service.send(:delete_report_data)

      expect(counts).to eq({})
    end
  end

  describe 'deletion_summary' do
    before do
      test_client_class.create!(
        report_id: report.id,
        client_id: 1,
        reporting_age: 25,
      )
      test_project_class.create!(report_id: report.id, project_id: 100)
      setup_archival_metadata(report, expected_files: ['clients_csv', 'projects_csv'])
    end

    it 'returns counts for all associations' do
      service = described_class.new(report)
      summary = service.send(:deletion_summary)

      expect(summary).to include(:clients, :projects)
      expect(summary[:clients]).to eq(1)
      expect(summary[:projects]).to eq(1)
    end

    it 'handles empty config gracefully' do
      allow(report).to receive(:archival_csv_config).and_return({})
      service = described_class.new(report)
      summary = service.send(:deletion_summary)

      expect(summary).to eq({})
    end
  end

  describe 'grace_period_expired?' do
    it 'returns false when purge_eligible_at is missing and completed_at is missing' do
      report.update_column(:archival_metadata, { archived_at: Time.current.iso8601 })
      report.update_column(:completed_at, nil)
      service = described_class.new(report)
      expect(service.send(:grace_period_expired?)).to be false
    end

    it 'calculates from completed_at when purge_eligible_at is missing' do
      grace_period_days = Reports.archival_grace_period_days
      # Set completed_at to be past the grace period
      report.update_column(:completed_at, (grace_period_days + 1).days.ago)
      report.update_column(:archival_metadata, { archived_at: Time.current.iso8601 })
      service = described_class.new(report)
      expect(service.send(:grace_period_expired?)).to be true
    end

    it 'returns false when purge_eligible_at is missing but grace period has not expired' do
      grace_period_days = Reports.archival_grace_period_days
      # Set completed_at to be within the grace period
      report.update_column(:completed_at, (grace_period_days - 1).days.ago)
      report.update_column(:archival_metadata, { archived_at: Time.current.iso8601 })
      service = described_class.new(report)
      expect(service.send(:grace_period_expired?)).to be false
    end

    it 'returns true when purge_eligible_at is in the past' do
      report.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          purge_eligible_at: 1.day.ago.iso8601,
        },
      )
      service = described_class.new(report)
      expect(service.send(:grace_period_expired?)).to be true
    end

    it 'returns false when purge_eligible_at is in the future' do
      report.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          purge_eligible_at: 1.day.from_now.iso8601,
        },
      )
      service = described_class.new(report)
      expect(service.send(:grace_period_expired?)).to be false
    end
  end
end

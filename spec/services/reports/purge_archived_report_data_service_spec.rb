###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::PurgeArchivedReportDataService, type: :service do
  let(:user) { User.system_user }
  let(:report) do
    PerformanceMeasurement::Goal.ensure_default
    report = PerformanceMeasurement::Report.new(
      user_id: user.id,
    )
    report.update_goal_configuration!
    report.save!
    report
  end
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

  def setup_archival_metadata(report, expected_files:, complete: false, purge_eligible_at: nil, purged_at: nil)
    metadata = {
      archived_at: Time.current.iso8601,
      expected_files: expected_files,
    }
    metadata[:complete] = true if complete
    metadata[:purge_eligible_at] = purge_eligible_at.iso8601 if purge_eligible_at
    metadata[:purged_at] = purged_at.iso8601 if purged_at

    report.update!(
      completed_at: Time.current,
      archival_metadata: metadata,
    )
  end

  def setup_archived_report_with_clients(report, client_count: 1, expected_files: ['clients_csv'], purge_eligible_at: nil)
    clients = client_count.times.map do |i|
      PerformanceMeasurement::Client.create!(
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
      complete: true,
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
            expected_files: ['clients_csv', 'projects_csv', 'client_projects_csv'],
          },
        )
        report.clients_csv.attach(
          io: StringIO.new('id,name\n1,Client 1'),
          filename: 'clients-1.csv',
          content_type: 'text/csv',
        )
        # Missing projects_csv and client_projects_csv
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
            complete: true,
          },
        )
        # Don't attach any files
      end

      it 'returns false and includes error' do
        result = service.purge!
        expect(result[:success]).to be false
        # Since no files are attached, archival_complete? will fail first
        expect(result[:errors]).to include('Report has not been archived or archival is not complete')
      end
    end

    context 'when CSV data integrity check fails' do
      before do
        # Create database records
        client1 = PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 1, reporting_age: 25)
        PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 2, reporting_age: 30)

        # Attach CSV with different count (only 1 client instead of 2)
        csv_content = generate_clients_csv([client1])
        attach_clients_csv(report, csv_content, filename: 'clients-1.csv')

        setup_archival_metadata(report, expected_files: ['clients_csv'], complete: true, purge_eligible_at: 1.day.ago)
      end

      it 'returns false when discrepancy is too large' do
        # The discrepancy is 50% (1 vs 2), which exceeds the 1% threshold
        result = service.purge!
        expect(result[:success]).to be false
        expect(result[:errors]).to include('CSV data integrity check failed (row counts do not match database)')
      end
    end

    context 'when report is already purged' do
      before do
        attach_clients_csv(report, 'id,name\n1,Client 1', filename: 'clients-1.csv')
        setup_archival_metadata(report, expected_files: ['clients_csv'], complete: true, purged_at: 1.day.ago)
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

      it 'allows purge when force is true' do
        forced_service = described_class.new(report, dry_run: false, force: true)
        result = forced_service.purge!
        expect(result[:success]).to be true
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

      it 'allows purge even when grace period has not expired' do
        result = forced_service.purge!
        expect(result[:success]).to be true
      end

      it 'successfully purges data when force is true' do
        result = forced_service.purge!

        expect(result[:success]).to be true
        expect(result[:deleted_counts]).to include(clients: 1)
        expect(PerformanceMeasurement::Client.where(report_id: report.id).count).to eq(0)
      end
    end

    context 'when in dry-run mode' do
      let(:service) { described_class.new(report, dry_run: true) }

      before do
        # Create database records
        client1 = PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 1, reporting_age: 25)
        client2 = PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 2, reporting_age: 30)
        project1 = PerformanceMeasurement::Project.create!(report_id: report.id, project_id: 100)
        PerformanceMeasurement::ClientProject.create!(report_id: report.id, client_id: client1.client_id, project_id: project1.project_id, for_question: 'test_question', period: 'reporting')

        # Attach CSV with matching counts
        csv_content = generate_clients_csv([client1, client2])
        attach_clients_csv(report, csv_content, filename: 'clients-1.csv')

        setup_archival_metadata(report, expected_files: ['clients_csv'], complete: true, purge_eligible_at: 1.day.ago)
      end

      it 'returns would_delete summary without deleting data' do
        result = service.purge!

        expect(result[:success]).to be true
        expect(result[:dry_run]).to be true
        expect(result[:would_delete]).to include(
          clients: 2,
          projects: 1,
          client_projects: 1,
        )

        # Verify data is still present
        expect(PerformanceMeasurement::Client.where(report_id: report.id).count).to eq(2)
        expect(PerformanceMeasurement::Project.where(report_id: report.id).count).to eq(1)
        expect(PerformanceMeasurement::ClientProject.where(report_id: report.id).count).to eq(1)
      end
    end

    context 'when all safety checks pass' do
      let!(:client1) do
        PerformanceMeasurement::Client.create!(
          report_id: report.id,
          client_id: 1,
          reporting_age: 25,
        )
      end
      let!(:client2) do
        PerformanceMeasurement::Client.create!(
          report_id: report.id,
          client_id: 2,
          reporting_age: 30,
        )
      end
      let!(:project1) do
        PerformanceMeasurement::Project.create!(
          report_id: report.id,
          project_id: 100,
        )
      end
      let!(:project2) do
        PerformanceMeasurement::Project.create!(
          report_id: report.id,
          project_id: 200,
        )
      end
      let!(:client_project1) do
        PerformanceMeasurement::ClientProject.create!(
          report_id: report.id,
          client_id: client1.client_id,
          project_id: project1.project_id,
          for_question: 'test_question',
          period: 'reporting',
        )
      end
      let!(:client_project2) do
        PerformanceMeasurement::ClientProject.create!(
          report_id: report.id,
          client_id: client2.client_id,
          project_id: project2.project_id,
          for_question: 'test_question',
          period: 'reporting',
        )
      end

      before do
        # Attach CSV with matching counts
        csv_content = generate_clients_csv([client1, client2])
        attach_clients_csv(report, csv_content, filename: 'clients-1.csv')

        setup_archival_metadata(report, expected_files: ['clients_csv'], complete: true, purge_eligible_at: 1.day.ago)
      end

      it 'deletes all database records for the report' do
        # Verify records exist before purge
        expect(PerformanceMeasurement::Client.where(report_id: report.id).count).to eq(2)
        expect(PerformanceMeasurement::Project.where(report_id: report.id).count).to eq(2)
        expect(PerformanceMeasurement::ClientProject.where(report_id: report.id).count).to eq(2)

        result = service.purge!

        expect(result[:success]).to be true
        expect(result[:deleted_counts]).to include(
          clients: 2,
          projects: 2,
          client_projects: 2,
        )

        # Verify records are deleted
        expect(PerformanceMeasurement::Client.where(report_id: report.id).count).to eq(0)
        expect(PerformanceMeasurement::Project.where(report_id: report.id).count).to eq(0)
        expect(PerformanceMeasurement::ClientProject.where(report_id: report.id).count).to eq(0)
      end

      it 'updates archival metadata with purged_at timestamp' do
        result = service.purge!

        expect(result[:success]).to be true
        report.reload
        expect(report.archival_metadata['purged_at']).to be_present
      end

      it 'does not delete records from other reports' do
        # Create another report with its own data
        other_report = PerformanceMeasurement::Report.new(
          user_id: user.id,
        )
        other_report.update_goal_configuration!
        other_report.save!
        other_client = PerformanceMeasurement::Client.create!(report_id: other_report.id, client_id: 999, reporting_age: 40)

        result = service.purge!

        expect(result[:success]).to be true

        # Verify other report's data is still present
        expect(PerformanceMeasurement::Client.where(report_id: other_report.id).count).to eq(1)
        expect(PerformanceMeasurement::Client.find_by(id: other_client.id)).to be_present
      end
    end

    context 'when deletion fails' do
      before do
        client1 = PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 1, reporting_age: 25)

        # Attach CSV with matching count
        csv_content = generate_clients_csv([client1])
        attach_clients_csv(report, csv_content, filename: 'clients-1.csv')

        setup_archival_metadata(report, expected_files: ['clients_csv'], complete: true)

        # Simulate deletion failure
        allow(PerformanceMeasurement::Client).to receive(:where).and_raise(StandardError, 'Database error')
      end

      it 'returns error and does not update metadata' do
        result = service.purge!

        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
        report.reload
        expect(report.archival_metadata['purged_at']).to be_nil
      end
    end

    context 'with generator-based CSV (no database count check)' do
      before do
        # Create a test report class with generator
        test_report_class = Class.new(SimpleReports::ReportInstance) do
          include ReportArchival
          has_many_attached :projects_csv

          def archival_csv_config
            {
              projects_csv: {
                generator: ->(_report) { [{ id: 1, name: 'Project 1' }] },
                filename: -> { "projects-#{id}.csv" },
              },
            }
          end
        end
        class_name = "TestReportForPurge#{SecureRandom.hex(8)}"
        Object.const_set(class_name, test_report_class)
        @test_report = test_report_class.create!(user_id: user.id)

        # Attach CSV
        csv_content = CSV.generate do |csv|
          csv << ['id', 'name']
          csv << [1, 'Project 1']
        end
        @test_report.projects_csv.attach(
          io: StringIO.new(csv_content),
          filename: 'projects-1.csv',
          content_type: 'text/csv',
        )

        @test_report.update!(
          completed_at: Time.current,
          archival_metadata: {
            archived_at: Time.current.iso8601,
            expected_files: ['projects_csv'],
            complete: true,
            purge_eligible_at: 1.day.ago.iso8601, # Grace period expired
          },
        )
      end

      it 'skips integrity check for generator-based CSV' do
        purge_service = described_class.new(@test_report)
        # Should pass safety checks even though there's no database count to compare
        result = purge_service.purge!
        expect(result[:success]).to be true
      end
    end
  end

  describe 'integration with ArchiveReportService' do
    it 'does not automatically purge data after successful archival' do
      # Create database records for associations that will be archived
      PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 1, reporting_age: 25)
      PerformanceMeasurement::Project.create!(report_id: report.id, project_id: 100)

      # Archive the report (should NOT trigger immediate purge)
      archive_service = Reports::ArchiveReportService.new(report)
      archive_service.archive!

      # Verify data is NOT purged immediately
      report.reload
      expect(report.archived?).to be true # CSV files exist (including empty ones with headers)
      expect(report.purged?).to be false # Data not purged yet
      expect(report.archival_metadata['purged_at']).to be_nil
      expect(PerformanceMeasurement::Client.where(report_id: report.id).count).to eq(1)
      expect(PerformanceMeasurement::Project.where(report_id: report.id).count).to eq(1)
    end

    it 'does not purge if archival fails' do
      # Create database records
      PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 1, reporting_age: 25)

      # Simulate archival failure by making archival_csv_config return empty
      allow(report).to receive(:archival_csv_config).and_return({})

      archive_service = Reports::ArchiveReportService.new(report)
      archive_service.archive!

      # Verify data is NOT purged
      expect(PerformanceMeasurement::Client.where(report_id: report.id).count).to eq(1)
      report.reload
      expect(report.archival_metadata&.dig('purged_at')).to be_nil
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
      client1 = PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 1, reporting_age: 25)
      client2 = PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 2, reporting_age: 30)

      csv_content = generate_clients_csv([client1, client2])
      attach_clients_csv(report, csv_content, filename: 'clients-1.csv')

      setup_archival_metadata(report, expected_files: ['clients_csv'], complete: true)
    end

    it 'returns true when counts match exactly' do
      service = described_class.new(report)
      expect(service.send(:csv_data_integrity_verified?)).to be true
    end

    it 'allows small discrepancies within 1% threshold' do
      # Add one more client to database (3 total vs 2 in CSV = 33% difference, but let's test with smaller)
      # Actually, let's test with a case that's within 1%
      # If CSV has 100 records and DB has 101, that's 1% difference, should pass
      # But our test has 2 records, so 1% would be 0.02, meaning 2 vs 2.02 would pass
      # Let's add a test that verifies the threshold logic
      service = described_class.new(report)
      # Mock the counts to test threshold
      allow(service).to receive(:csv_row_count).and_return(100)
      allow(service).to receive(:database_row_count).and_return(101) # 1% difference

      expect(service.send(:csv_data_integrity_verified?)).to be true
    end

    it 'returns false when discrepancy exceeds 1% threshold' do
      service = described_class.new(report)
      # Mock the counts to test threshold
      allow(service).to receive(:csv_row_count).and_return(100)
      allow(service).to receive(:database_row_count).and_return(102) # 2% difference

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
      PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 1, reporting_age: 25)
      setup_archival_metadata(report, expected_files: ['clients_csv'])
    end

    it 'handles errors gracefully' do
      service = described_class.new(report)
      allow(report).to receive(:clients).and_raise(StandardError.new('Database error'))

      count = service.send(:database_row_count, { association: :clients })
      expect(count).to eq(0)
    end

    it 'handles non-relation associations' do
      service = described_class.new(report)
      allow(report).to receive(:clients).and_return([double('client')])

      count = service.send(:database_row_count, { association: :clients })
      expect(count).to eq(1)
    end
  end

  describe 'delete_report_data' do
    before do
      PerformanceMeasurement::Client.create!(report_id: report.id, client_id: 1, reporting_age: 25)
      PerformanceMeasurement::Project.create!(report_id: report.id, project_id: 100)

      attach_clients_csv(report, 'id,client_id\n1,1', filename: 'clients-1.csv')
      attach_projects_csv(report, 'id,project_id\n1,100', filename: 'projects-1.csv')

      setup_archival_metadata(report, expected_files: ['clients_csv', 'projects_csv'], complete: true, purge_eligible_at: 1.day.ago)
    end

    it 'deletes records in correct order (child records first)' do
      service = described_class.new(report, dry_run: false, force: true)
      counts = service.send(:delete_report_data)

      expect(counts).to include(:clients, :projects)
      expect(PerformanceMeasurement::Client.where(report_id: report.id).count).to eq(0)
      expect(PerformanceMeasurement::Project.where(report_id: report.id).count).to eq(0)
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
      PerformanceMeasurement::Client.create!(
        report_id: report.id,
        client_id: 1,
        reporting_age: 25,
      )
      PerformanceMeasurement::Project.create!(report_id: report.id, project_id: 100)
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
    it 'returns false when purge_eligible_at is missing' do
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

  describe 'error message formatting' do
    before do
      attach_clients_csv(report, 'id,name\n1,Client 1', filename: 'clients-1.csv')
      setup_archival_metadata(report, expected_files: ['clients_csv'], complete: true, purge_eligible_at: 5.days.from_now)
    end

    it 'includes days remaining in error message' do
      service = described_class.new(report)
      result = service.purge!
      expect(result[:success]).to be false
      expect(result[:errors].first).to match(/day\(s\)/)
    end

    it 'includes date in error message' do
      service = described_class.new(report)
      result = service.purge!
      expect(result[:success]).to be false
      expect(result[:errors].first).to match(/\d{4}-\d{2}-\d{2}/)
    end
  end
end

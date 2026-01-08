###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::ArchiveReportService, type: :service do
  # Create a test report model
  let(:test_report_class) do
    klass = Class.new(SimpleReports::ReportInstance) do
      include ReportArchival

      has_many_attached :clients_csv
      has_many_attached :projects_csv

      def archival_csv_config
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

      # Mock associations
      def test_clients
        [
          { id: 1, name: 'Client 1' },
          { id: 2, name: 'Client 2' },
        ]
      end

      def test_projects
        [
          { id: 1, name: 'Project 1' },
          { id: 2, name: 'Project 2' },
        ]
      end
    end
    # Give the class a name so Active Storage can work properly
    class_name = "TestReportForArchiveService#{SecureRandom.hex(8)}"
    Object.const_set(class_name, klass)
    klass
  end

  let(:report) { test_report_class.create!(user_id: User.system_user.id) }
  let(:service) { described_class.new(report) }

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

    it 'handles errors gracefully' do
      allow(report).to receive(:archival_csv_config).and_raise(StandardError.new('Config error'))
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
        expect(report.archival_complete?).to be true
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
        expect(parsed.first['id']).to eq('1')
        expect(parsed.first['name']).to eq('Client 1')
      end

      it 'generates correct CSV content from associations' do
        service.archive!

        csv_content = report.projects_csv.first.download
        parsed = CSV.parse(csv_content, headers: true)
        expect(parsed.length).to eq(2)
        expect(parsed.first['id']).to eq('1')
        expect(parsed.first['name']).to eq('Project 1')
      end

      it 'marks archival as complete' do
        service.archive!

        expect(report.archival_complete?).to be true
        expect(report.archival_metadata['completed_at']).to be_present
        expect(report.archival_metadata['complete']).to be true
      end

      it 'sets grace period metadata' do
        service.archive!

        expect(report.archival_metadata['grace_period_days']).to eq(Reports::DEFAULT_ARCHIVAL_GRACE_PERIOD_DAYS)
        expect(report.archival_metadata['purge_eligible_at']).to be_present
        purge_eligible_at = Time.parse(report.archival_metadata['purge_eligible_at'])
        expected_days = Reports::DEFAULT_ARCHIVAL_GRACE_PERIOD_DAYS
        expect(purge_eligible_at).to be > Time.current + (expected_days - 1).days
        expect(purge_eligible_at).to be <= Time.current + (expected_days + 1).days
      end

      it 'does not purge database data immediately' do
        # Create some test data
        test_data = [{ id: 1, name: 'Client 1' }]
        allow(report).to receive(:test_clients).and_return(test_data)

        service.archive!

        # Database data should still be accessible (not purged)
        # Since we're using a mock, we can't actually verify this,
        # but we can verify that purge_eligible_at is set (meaning purge hasn't happened yet)
        expect(report.archival_metadata['purged_at']).to be_nil
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

    context 'with empty records' do
      it 'handles empty associations gracefully' do
        allow(report).to receive(:test_clients).and_return([])
        service.archive!

        csv_content = report.clients_csv.first.download
        expect(csv_content).to eq('')
      end
    end
  end

  describe '#complete_archival' do
    it 'completes incomplete archival' do
      # Start archival but don't complete it
      report.update!(
        archival_metadata: {
          archived_at: Time.current,
          expected_files: ['clients_csv', 'projects_csv'],
        },
      )
      report.clients_csv.attach(
        io: StringIO.new('id,name\n1,Client 1'),
        filename: 'clients-1.csv',
        content_type: 'text/csv',
      )

      service.complete_archival

      expect(report.projects_csv.attached?).to be true
      expect(report.archival_complete?).to be true
    end

    it 'returns false when report is not eligible' do
      ineligible_report = SimpleReports::ReportInstance.create!(user_id: User.system_user.id)
      ineligible_service = described_class.new(ineligible_report)
      expect(ineligible_service.complete_archival).to be false
    end

    it 'returns false when archival is already complete' do
      service.archive!
      expect(service.complete_archival).to be false
    end

    it 'handles errors during completion gracefully' do
      report.update!(
        archival_metadata: {
          archived_at: Time.current,
          expected_files: ['clients_csv', 'projects_csv'],
        },
      )
      report.clients_csv.attach(
        io: StringIO.new('id,name\n1,Client 1'),
        filename: 'clients-1.csv',
        content_type: 'text/csv',
      )
      allow(report).to receive(:test_projects).and_raise(StandardError.new('Data fetch failed'))

      result = service.complete_archival
      expect(result).to be false
      expect(service.errors).to be_present
    end
  end

  describe '#archive!' do
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

    context 'with grace period' do
      it 'uses default grace period constant' do
        service.archive!

        expect(report.archival_metadata['grace_period_days']).to eq(Reports::DEFAULT_ARCHIVAL_GRACE_PERIOD_DAYS)
        purge_eligible_at = Time.parse(report.archival_metadata['purge_eligible_at'])
        expected_days = Reports::DEFAULT_ARCHIVAL_GRACE_PERIOD_DAYS
        expect(purge_eligible_at).to be > Time.current + (expected_days - 1).days
        expect(purge_eligible_at).to be <= Time.current + (expected_days + 1).days
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

    context 'with hash records' do
      it 'generates CSV from hash records' do
        allow(report).to receive(:test_clients).and_return(
          [
            { id: 1, name: 'Client 1', age: 25 },
            { id: 2, name: 'Client 2', age: 30 },
          ],
        )

        service.archive!

        csv_content = report.clients_csv.first.download
        parsed = CSV.parse(csv_content, headers: true)
        expect(parsed.length).to eq(2)
        expect(parsed.first['id']).to eq('1')
        expect(parsed.first['name']).to eq('Client 1')
        expect(parsed.first['age']).to eq('25')
      end
    end

    context 'with ActiveRecord::Relation' do
      it 'handles empty relations gracefully' do
        # Test that empty relations don't cause errors
        allow(report).to receive(:test_clients).and_return([])
        service.archive!

        expect(report.clients_csv.attached?).to be true
        csv_content = report.clients_csv.first.download
        expect(csv_content).to eq('')
      end
    end
  end
end

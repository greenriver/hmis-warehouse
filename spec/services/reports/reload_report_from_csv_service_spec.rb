###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::ReloadReportFromCsvService, type: :service do
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
  let(:service) { described_class.new(report) }

  describe '#can_reload?' do
    it 'returns false when report is not present' do
      service = described_class.new(nil)
      expect(service.can_reload?).to be false
    end

    it 'returns false when archival is not complete' do
      expect(service.can_reload?).to be false
    end

    it 'returns false when CSV files are missing' do
      report.update!(
        archival_metadata: {
          archived_at: Time.current.iso8601,
          expected_files: ['clients_csv'],
          complete: true,
        },
      )
      expect(service.can_reload?).to be false
    end

    it 'returns true when CSV files are available' do
      report.update!(
        archival_metadata: {
          archived_at: Time.current.iso8601,
          expected_files: ['clients_csv'],
          complete: true,
        },
      )
      report.clients_csv.attach(
        io: StringIO.new('id,client_id,reporting_age\n1,100,25'),
        filename: 'clients-1.csv',
        content_type: 'text/csv',
      )
      expect(service.can_reload?).to be true
    end
  end

  describe '#reload!' do
    context 'when CSV files are not available' do
      it 'returns error' do
        result = service.reload!
        expect(result[:success]).to be false
        expect(result[:errors]).to include('CSV files are not available or archival is incomplete')
      end
    end

    context 'when CSV files are available' do
      before do
        # Create CSV files
        clients_csv = CSV.generate do |csv|
          csv << ['id', 'client_id', 'report_id', 'reporting_age']
          csv << [1, 100, report.id, 25]
          csv << [2, 101, report.id, 30]
        end

        projects_csv = CSV.generate do |csv|
          csv << ['id', 'project_id', 'report_id']
          csv << [1, 200, report.id]
        end

        report.clients_csv.attach(
          io: StringIO.new(clients_csv),
          filename: 'clients-1.csv',
          content_type: 'text/csv',
        )
        report.projects_csv.attach(
          io: StringIO.new(projects_csv),
          filename: 'projects-1.csv',
          content_type: 'text/csv',
        )

        report.update!(
          archival_metadata: {
            archived_at: Time.current.iso8601,
            expected_files: ['clients_csv', 'projects_csv'],
            complete: true,
            completed_at: Time.current.iso8601,
            purged_at: Time.current.iso8601, # Data was purged
          },
        )
      end

      it 'reloads data from CSV files' do
        result = service.reload!

        expect(result[:success]).to be true
        expect(result[:reloaded_counts][:clients_csv]).to eq(2)
        expect(result[:reloaded_counts][:projects_csv]).to eq(1)
      end

      it 'restarts grace period' do
        result = service.reload!

        expect(result[:success]).to be true
        expect(report.archival_metadata['purged_at']).to be_nil
        expect(report.archival_metadata['reloaded_at']).to be_present
        expect(report.archival_metadata['purge_eligible_at']).to be_present

        purge_eligible_at = Time.parse(report.archival_metadata['purge_eligible_at'])
        expected_days = Reports.archival_grace_period_days
        expect(purge_eligible_at).to be > Time.current + (expected_days - 1).days
        expect(purge_eligible_at).to be <= Time.current + (expected_days + 1).days
      end

      it 'creates database records from CSV data' do
        expect(PerformanceMeasurement::Client.where(report_id: report.id).count).to eq(0)
        expect(PerformanceMeasurement::Project.where(report_id: report.id).count).to eq(0)

        service.reload!

        expect(PerformanceMeasurement::Client.where(report_id: report.id).count).to eq(2)
        expect(PerformanceMeasurement::Project.where(report_id: report.id).count).to eq(1)

        client = PerformanceMeasurement::Client.find_by(report_id: report.id, client_id: 100)
        expect(client).to be_present
        expect(client.reporting_age).to eq(25)
      end

      it 'handles errors gracefully when association fails' do
        # Cause an error by using a nonexistent association
        allow(report).to receive(:archival_csv_config).and_return(
          clients_csv: {
            association: :nonexistent_association,
            filename: -> { "clients-#{report.id}.csv" },
          },
        )

        result = service.reload!

        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
        expect(result[:errors].first).to match(/Failed to reload/)
      end

      it 'handles partial failures - some associations reload successfully' do
        # Set up so clients_csv fails but projects_csv succeeds
        allow(report).to receive(:archival_csv_config).and_return(
          clients_csv: {
            association: :nonexistent_association,
            filename: -> { "clients-#{report.id}.csv" },
          },
          projects_csv: {
            association: :projects,
            filename: -> { "projects-#{report.id}.csv" },
          },
        )

        result = service.reload!

        expect(result[:success]).to be false
        expect(result[:errors]).to be_present
        expect(result[:reloaded_counts][:projects_csv]).to eq(1)
        expect(result[:reloaded_counts][:clients_csv]).to be_nil
        # Grace period should not be restarted if there are errors
        expect(report.archival_metadata['reloaded_at']).to be_nil
      end
    end

    context 'when report has no archival configuration' do
      before do
        # Set up CSV files so can_reload? passes
        report.clients_csv.attach(
          io: StringIO.new('id,client_id\n1,100'),
          filename: 'clients-1.csv',
          content_type: 'text/csv',
        )
        report.update!(
          archival_metadata: {
            archived_at: Time.current.iso8601,
            expected_files: ['clients_csv'],
            complete: true,
          },
        )
        allow(report).to receive(:archival_csv_config).and_return({})
      end

      it 'returns error' do
        result = service.reload!
        expect(result[:success]).to be false
        expect(result[:errors]).to include('No archival configuration found')
      end
    end

    context 'when expected files do not match config' do
      before do
        # Attach files so can_reload? passes
        report.clients_csv.attach(
          io: StringIO.new('id,client_id\n1,100'),
          filename: 'clients-1.csv',
          content_type: 'text/csv',
        )
        report.projects_csv.attach(
          io: StringIO.new('id,project_id\n1,200'),
          filename: 'projects-1.csv',
          content_type: 'text/csv',
        )
        report.update!(
          archival_metadata: {
            archived_at: Time.current.iso8601,
            expected_files: ['clients_csv', 'projects_csv'],
            complete: true,
          },
        )
      end

      it 'returns error when none of the expected files match config' do
        # Config has neither clients_csv nor projects_csv
        allow(report).to receive(:archival_csv_config).and_return(
          results_csv: {
            association: :results,
            filename: -> { "results-#{report.id}.csv" },
          },
        )

        result = service.reload!
        expect(result[:success]).to be false
        expect(result[:errors]).to include('No matching archival configuration found for expected files')
      end

      it 'reloads only files that match config when some expected files are missing from config' do
        # Config only has clients_csv, but expected_files includes both
        # This should succeed and only reload clients_csv
        allow(report).to receive(:archival_csv_config).and_return(
          clients_csv: {
            association: :clients,
            filename: -> { "clients-#{report.id}.csv" },
          },
        )

        result = service.reload!
        expect(result[:success]).to be true
        expect(result[:reloaded_counts]).to have_key(:clients_csv)
        expect(result[:reloaded_counts]).not_to have_key(:projects_csv)
      end
    end
  end
end

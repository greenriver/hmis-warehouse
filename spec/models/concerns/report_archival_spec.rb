###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportArchival, type: :model do
  # Ensure the archival_metadata column exists in test database
  before(:all) do
    connection = GrdaWarehouseBase.connection
    connection.add_column :simple_report_instances, :archival_metadata, :jsonb unless connection.column_exists?(:simple_report_instances, :archival_metadata)
  end

  # Create a test model that includes the concern
  let(:test_model_class) do
    Class.new(SimpleReports::ReportInstance) do
      include ReportArchival
    end
  end

  let(:report) { test_model_class.create!(user_id: User.system_user.id) }

  # Helper method to create test report classes with attachments
  def create_test_report_class_with_attachments(attachment_names, class_suffix = nil)
    attachment_names_array = Array(attachment_names)
    klass = Class.new(SimpleReports::ReportInstance) do
      include ReportArchival
      attachment_names_array.each { |name| has_many_attached name }
    end
    class_name = "TestReport#{class_suffix || SecureRandom.hex(8)}"
    Object.const_set(class_name, klass)
    klass
  end

  describe '#archived?' do
    let(:test_report_class_with_attachments) { create_test_report_class_with_attachments([:file1_csv, :file2_csv], "ForArchived#{SecureRandom.hex(8)}") }
    let(:report_with_attachments) { test_report_class_with_attachments.create!(user_id: User.system_user.id) }

    it 'returns false when archival_metadata is blank' do
      expect(report.archived?).to be false
    end

    it 'returns false when archival_metadata is present but archived_at is missing' do
      report.update_column(:archival_metadata, { some_key: 'value' })
      expect(report.archived?).to be false
    end

    it 'returns false when expected_files is empty' do
      report_with_attachments.update_column(:archival_metadata, { archived_at: Time.current })
      expect(report_with_attachments.archived?).to be false
    end

    it 'returns false when files are not attached' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current,
          expected_files: ['file1_csv', 'file2_csv'],
        },
      )
      expect(report_with_attachments.archived?).to be false
    end

    it 'returns true when all expected files are attached' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current,
          expected_files: ['file1_csv', 'file2_csv'],
        },
      )
      report_with_attachments.file1_csv.attach(
        io: StringIO.new('test'),
        filename: 'file1.csv',
        content_type: 'text/csv',
      )
      report_with_attachments.file2_csv.attach(
        io: StringIO.new('test'),
        filename: 'file2.csv',
        content_type: 'text/csv',
      )
      expect(report_with_attachments.archived?).to be true
    end

    it 'returns true when CSV exists regardless of purge status' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current,
          expected_files: ['file1_csv'],
          purged_at: Time.current.iso8601,
        },
      )
      report_with_attachments.file1_csv.attach(
        io: StringIO.new('test'),
        filename: 'file1.csv',
        content_type: 'text/csv',
      )
      expect(report_with_attachments.archived?).to be true
      expect(report_with_attachments.purged?).to be true
    end
  end

  describe '#purged?' do
    let(:test_report_class_with_attachments) { create_test_report_class_with_attachments(:file1_csv, "ForPurged#{SecureRandom.hex(8)}") }
    let(:report_with_attachments) { test_report_class_with_attachments.create!(user_id: User.system_user.id) }

    it 'returns false when not purged' do
      expect(report_with_attachments.purged?).to be false
    end

    it 'returns false when CSV exists but data is not purged' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          expected_files: ['file1_csv'],
        },
      )
      report_with_attachments.file1_csv.attach(
        io: StringIO.new('test'),
        filename: 'file1.csv',
        content_type: 'text/csv',
      )
      expect(report_with_attachments.purged?).to be false
    end

    it 'returns true when data is purged' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          expected_files: ['file1_csv'],
          purged_at: Time.current.iso8601,
        },
      )
      report_with_attachments.file1_csv.attach(
        io: StringIO.new('test'),
        filename: 'file1.csv',
        content_type: 'text/csv',
      )
      expect(report_with_attachments.purged?).to be true
    end
  end

  describe '#purge_eligible?' do
    let(:test_report_class_with_attachments) { create_test_report_class_with_attachments(:file1_csv, "ForPurgeEligible#{SecureRandom.hex(8)}") }
    let(:report_with_attachments) { test_report_class_with_attachments.create!(user_id: User.system_user.id) }

    it 'returns false when not archived' do
      expect(report_with_attachments.purge_eligible?).to be false
    end

    it 'returns false when purge_eligible_at is missing' do
      report.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
        },
      )
      expect(report.purge_eligible?).to be false
    end

    it 'returns false when already purged' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          purge_eligible_at: 1.day.ago.iso8601,
          purged_at: Time.current.iso8601,
        },
      )
      expect(report_with_attachments.purge_eligible?).to be false
    end

    it 'returns false when grace period has not expired' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          purge_eligible_at: 1.day.from_now.iso8601,
        },
      )
      expect(report_with_attachments.purge_eligible?).to be false
    end

    it 'returns true when grace period has expired' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          purge_eligible_at: 1.day.ago.iso8601,
        },
      )
      expect(report_with_attachments.purge_eligible?).to be true
    end

    it 'raises error when purge_eligible_at is invalid' do
      report.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          purge_eligible_at: 'invalid-date',
        },
      )
      expect { report.purge_eligible? }.to raise_error(ArgumentError)
    end
  end

  describe '#archival_status' do
    let(:test_report_class_with_attachments) { create_test_report_class_with_attachments([:file1_csv, :file2_csv], "ForArchivalStatus#{SecureRandom.hex(8)}") }
    let(:report_with_attachments) { test_report_class_with_attachments.create!(user_id: User.system_user.id) }

    it 'returns archived: false when not archived' do
      status = report_with_attachments.archival_status
      expect(status).to eq({ archived: false })
    end

    it 'returns complete status hash' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current,
          expected_file_count: 2,
          expected_files: ['file1_csv', 'file2_csv'],
        },
      )
      report_with_attachments.file1_csv.attach(
        io: StringIO.new('test'),
        filename: 'file1.csv',
        content_type: 'text/csv',
      )
      report_with_attachments.file2_csv.attach(
        io: StringIO.new('test'),
        filename: 'file2.csv',
        content_type: 'text/csv',
      )

      status = report_with_attachments.archival_status
      expect(status).to include(
        archived: true, # CSV files exist
        purged: false, # Data not purged yet
        purge_eligible: false,
        archived_at: be_present,
        expected_file_count: 2,
        expected_files: ['file1_csv', 'file2_csv'],
      )
      expect(status[:files]).to be_present
      expect(status[:files]['file1_csv'][:attached]).to be true
      expect(status[:files]['file2_csv'][:attached]).to be true
    end

    it 'includes purge_eligible status when purge_eligible_at is set' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          expected_files: ['file1_csv'],
          purge_eligible_at: 1.day.ago.iso8601,
        },
      )
      report_with_attachments.file1_csv.attach(
        io: StringIO.new('test'),
        filename: 'file1.csv',
        content_type: 'text/csv',
      )

      status = report_with_attachments.archival_status
      expect(status[:purge_eligible]).to be true
    end

    it 'includes purged status when purged_at is set' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          expected_files: ['file1_csv'],
          purged_at: Time.current.iso8601,
        },
      )
      report_with_attachments.file1_csv.attach(
        io: StringIO.new('test'),
        filename: 'file1.csv',
        content_type: 'text/csv',
      )

      status = report_with_attachments.archival_status
      expect(status[:purged]).to be true
    end

    it 'includes grace_period_days in status' do
      report_with_attachments.update_column(
        :archival_metadata,
        {
          archived_at: Time.current.iso8601,
          expected_files: ['file1_csv'],
          grace_period_days: 90,
        },
      )
      report_with_attachments.file1_csv.attach(
        io: StringIO.new('test'),
        filename: 'file1.csv',
        content_type: 'text/csv',
      )

      status = report_with_attachments.archival_status
      expect(status[:grace_period_days]).to eq(90)
    end
  end

  describe '#update_archival_metadata' do
    it 'updates a single key in metadata' do
      report.update_archival_metadata('test_key', 'test_value')
      expect(report.archival_metadata['test_key']).to eq('test_value')
    end

    it 'preserves existing metadata' do
      report.update_column(:archival_metadata, { existing_key: 'existing_value' })
      report.update_archival_metadata('new_key', 'new_value')
      expect(report.archival_metadata['existing_key']).to eq('existing_value')
      expect(report.archival_metadata['new_key']).to eq('new_value')
    end

    it 'handles nil archival_metadata' do
      report.update_column(:archival_metadata, nil)
      report.update_archival_metadata('test_key', 'test_value')
      expect(report.archival_metadata['test_key']).to eq('test_value')
    end

    it 'handles updating with nil value' do
      report.update_column(:archival_metadata, { existing_key: 'value' })
      report.update_archival_metadata('existing_key', nil)
      expect(report.archival_metadata['existing_key']).to be_nil
    end
  end

  describe '#archive_and_purge!' do
    let(:test_report_class_with_archival) do
      klass = Class.new(SimpleReports::ReportInstance) do
        include ReportArchival
        has_many_attached :clients_csv

        def archival_csv_config
          {
            clients_csv: {
              association: :clients,
              filename: -> { "test-clients-#{id}.csv" },
            },
          }
        end
      end
      class_name = "TestReportForArchiveAndPurge#{SecureRandom.hex(8)}"
      Object.const_set(class_name, klass)
      klass
    end

    let(:report_with_archival) { test_report_class_with_archival.create!(user_id: User.system_user.id) }

    it 'calls ArchiveReportService and PurgeArchivedReportDataService when not already archived' do
      archive_service_double = instance_double(Reports::ArchiveReportService)
      purge_service_double = instance_double(Reports::PurgeArchivedReportDataService)
      allow(Reports::ArchiveReportService).to receive(:new).with(report_with_archival).and_return(archive_service_double)
      allow(archive_service_double).to receive(:archive!).and_return(true)
      allow(Reports::PurgeArchivedReportDataService).to receive(:new).with(report_with_archival, dry_run: false, force: false).and_return(purge_service_double)
      allow(purge_service_double).to receive(:purge!).and_return({ success: true })
      allow(report_with_archival).to receive(:reload).and_return(report_with_archival)
      allow(report_with_archival).to receive(:archived?).and_return(false)

      report_with_archival.archive_and_purge!

      expect(report_with_archival).to have_received(:reload)
      expect(Reports::ArchiveReportService).to have_received(:new).with(report_with_archival)
      expect(archive_service_double).to have_received(:archive!)
      expect(Reports::PurgeArchivedReportDataService).to have_received(:new).with(report_with_archival, dry_run: false, force: false)
      expect(purge_service_double).to have_received(:purge!)
    end

    it 'passes force parameter to purge service' do
      purge_service_double = instance_double(Reports::PurgeArchivedReportDataService)
      allow(report_with_archival).to receive(:archived?).and_return(true)
      allow(Reports::PurgeArchivedReportDataService).to receive(:new).with(report_with_archival, dry_run: false, force: true).and_return(purge_service_double)
      allow(purge_service_double).to receive(:purge!).and_return({ success: true })

      report_with_archival.archive_and_purge!(force: true)

      expect(Reports::PurgeArchivedReportDataService).to have_received(:new).with(report_with_archival, dry_run: false, force: true)
      expect(purge_service_double).to have_received(:purge!)
    end

    it 'skips archiving when already archived' do
      purge_service_double = instance_double(Reports::PurgeArchivedReportDataService)
      allow(Reports::ArchiveReportService).to receive(:new).and_call_original
      allow(Reports::PurgeArchivedReportDataService).to receive(:new).with(report_with_archival, dry_run: false, force: false).and_return(purge_service_double)
      allow(purge_service_double).to receive(:purge!).and_return({ success: true })
      allow(report_with_archival).to receive(:archived?).and_return(true)

      report_with_archival.archive_and_purge!

      expect(Reports::ArchiveReportService).not_to have_received(:new)
      expect(Reports::PurgeArchivedReportDataService).to have_received(:new).with(report_with_archival, dry_run: false, force: false)
      expect(purge_service_double).to have_received(:purge!)
    end

    it 'returns error when archiving fails' do
      archive_service_double = instance_double(Reports::ArchiveReportService)
      allow(Reports::ArchiveReportService).to receive(:new).and_return(archive_service_double)
      allow(archive_service_double).to receive(:archive!).and_return(false)
      allow(archive_service_double).to receive(:errors).and_return([{ attachment: 'clients_csv', error: 'Test error' }])
      allow(Reports::PurgeArchivedReportDataService).to receive(:new).and_call_original
      allow(Rails.logger).to receive(:error)
      allow(report_with_archival).to receive(:reload).and_return(report_with_archival)
      allow(report_with_archival).to receive(:archived?).and_return(false)

      result = report_with_archival.archive_and_purge!

      expect(result[:success]).to be false
      expect(result[:errors].first).to include('Failed to archive report before purge')
      expect(Rails.logger).to have_received(:error).with(match(/Failed to archive report/))
      expect(Reports::PurgeArchivedReportDataService).not_to have_received(:new)
    end
  end

  describe '#expected_archival_files' do
    it 'returns empty array when not archived' do
      expect(report.expected_archival_files).to eq([])
    end

    it 'returns expected files list when archived' do
      report.update_column(
        :archival_metadata,
        {
          archived_at: Time.current,
          expected_files: ['file1_csv', 'file2_csv'],
        },
      )
      expect(report.expected_archival_files).to eq(['file1_csv', 'file2_csv'])
    end

    it 'returns empty array when archived_at is missing' do
      report.update_column(:archival_metadata, { expected_files: ['file1_csv'] })
      expect(report.expected_archival_files).to eq([])
    end
  end
end

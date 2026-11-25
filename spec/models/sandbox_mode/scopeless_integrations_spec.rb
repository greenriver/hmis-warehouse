###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sandbox mode for integrations without an active column', type: :model do
  describe GrdaWarehouse::LftpS3Sync do
    let!(:sync) do
      described_class.create!(
        data_source: create(:grda_warehouse_data_source),
        ftp_host: 'ftp.example.org',
        ftp_user: 'user',
        ftp_pass: 'pass',
        ftp_path: '/',
      )
    end

    it 'includes syncs outside sandbox mode and none in it' do
      expect(described_class.active).to contain_exactly(sync)

      with_sandbox_mode do
        expect(described_class.active).to be_empty
      end
    end
  end

  describe GrdaWarehouse::RecurringHmisExport do
    let!(:export) { create(:recurring_hmis_export, :with_s3_settings, updated_at: 2.days.ago) }

    it 'includes exports outside sandbox mode and none in it' do
      expect(described_class.active).to contain_exactly(export)

      with_sandbox_mode do
        expect(described_class.active).to be_empty
      end
    end

    it 'is the scope the scheduled task iterates' do
      task = GrdaWarehouse::Tasks::ProcessRecurringHmisExports.new
      expect(task.recurring_exports_scope).to contain_exactly(export)

      with_sandbox_mode do
        expect(task.recurring_exports_scope).to be_empty
      end
    end

    describe '#store' do
      let(:aws_s3) { instance_double(AwsS3, store: nil) }
      let(:report) { instance_double(GrdaWarehouse::HmisExport, hmis_zip: double(download: 'zip-bytes'), export_id: 42) }

      before { allow(export).to receive(:aws_s3).and_return(aws_s3) }

      it 'uploads to S3 outside sandbox mode' do
        export.store(report)

        expect(aws_s3).to have_received(:store).with(content: 'zip-bytes', name: export.object_name(report)).once
      end

      it 'makes no S3 call in sandbox mode' do
        with_sandbox_mode { export.store(report) }

        expect(aws_s3).not_to have_received(:store)
      end
    end
  end
end

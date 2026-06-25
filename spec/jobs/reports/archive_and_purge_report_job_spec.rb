###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reports::ArchiveAndPurgeReportJob, type: :job do
  # Simulate a DJ worker process where eager_load is false (the production DJ default)
  before do
    allow(Rails.application).to receive(:eager_load!)
    allow(Rails.application.config).to receive(:eager_load).and_return(false)
  end

  describe '#perform' do
    context 'when the report class is unknown' do
      it 'warns and returns without raising' do
        allow(Rails.logger).to receive(:warn)

        expect { described_class.new.perform(report_class: 'NonExistent::Report', report_id: 1) }.not_to raise_error
        expect(Rails.logger).to have_received(:warn).with(match(/unknown report class/))
      end
    end

    context 'when the report record is not found' do
      before do
        allow(SimpleReports::ReportInstance).to receive(:find_by).with(id: 99).and_return(nil)
      end

      it 'warns and returns without raising' do
        allow(Rails.logger).to receive(:warn)

        expect { described_class.new.perform(report_class: 'SimpleReports::ReportInstance', report_id: 99) }.not_to raise_error
        expect(Rails.logger).to have_received(:warn).with(match(/not found/))
      end
    end

    describe 'eager_load! guard' do
      before do
        report = double('report', id: 42)
        allow(SimpleReports::ReportInstance).to receive(:find_by).with(id: 42).and_return(report)
        allow(report).to receive(:archive_and_purge!).and_return({ success: true })
        allow(Rails.logger).to receive(:info)
      end

      it 'calls eager_load! when config.eager_load is false' do
        described_class.new.perform(report_class: 'SimpleReports::ReportInstance', report_id: 42)

        expect(Rails.application).to have_received(:eager_load!)
      end

      it 'skips eager_load! when config.eager_load is true' do
        allow(Rails.application.config).to receive(:eager_load).and_return(true)

        described_class.new.perform(report_class: 'SimpleReports::ReportInstance', report_id: 42)

        expect(Rails.application).not_to have_received(:eager_load!)
      end
    end

    context 'with a SimpleReport' do
      let(:report) { double('report', id: 42) }

      before do
        allow(SimpleReports::ReportInstance).to receive(:find_by).with(id: 42).and_return(report)
      end

      context 'when archive_and_purge! succeeds' do
        before do
          allow(report).to receive(:archive_and_purge!).and_return({ success: true, deleted_counts: {} })
          allow(Rails.logger).to receive(:info)
        end

        it 'calls archive_and_purge! on the report' do
          described_class.new.perform(report_class: 'SimpleReports::ReportInstance', report_id: 42)

          expect(report).to have_received(:archive_and_purge!)
        end
      end

      context 'when archive_and_purge! fails' do
        let(:errors) { ['Failed to archive before purge: S3 upload timeout'] }

        before do
          allow(report).to receive(:archive_and_purge!).and_return({ success: false, errors: errors })
          allow(report).to receive(:update_archival_metadata)
        end

        it 'stamps purge_failed_at with an ISO8601 timestamp' do
          expect { described_class.new.perform(report_class: 'SimpleReports::ReportInstance', report_id: 42) }.
            to raise_error(RuntimeError)

          expect(report).to have_received(:update_archival_metadata).
            with('purge_failed_at', match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/))
        end

        it 'raises with the report class, id, and error details' do
          expect { described_class.new.perform(report_class: 'SimpleReports::ReportInstance', report_id: 42) }.
            to raise_error(RuntimeError, match(/SimpleReports::ReportInstance.*42.*S3 upload timeout/))
        end
      end
    end

    context 'with a HUD report' do
      let(:report) { double('hud_report', id: 7) }

      before do
        allow(HudReports::ReportInstance).to receive(:find_by).with(id: 7).and_return(report)
      end

      context 'when archive_and_purge! succeeds' do
        before do
          allow(report).to receive(:archive_and_purge!).and_return({ success: true })
          allow(Rails.logger).to receive(:info)
        end

        it 'calls archive_and_purge! on the report' do
          described_class.new.perform(report_class: 'HudReports::ReportInstance', report_id: 7)

          expect(report).to have_received(:archive_and_purge!)
        end
      end

      context 'when archive_and_purge! fails' do
        before do
          allow(report).to receive(:archive_and_purge!).and_return({ success: false, errors: ['Archive failed'] })
          allow(report).to receive(:update_archival_metadata)
        end

        it 'stamps purge_failed_at and raises' do
          expect { described_class.new.perform(report_class: 'HudReports::ReportInstance', report_id: 7) }.
            to raise_error(RuntimeError, match(/HudReports::ReportInstance.*7/))

          expect(report).to have_received(:update_archival_metadata).
            with('purge_failed_at', match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/))
        end
      end
    end
  end
end

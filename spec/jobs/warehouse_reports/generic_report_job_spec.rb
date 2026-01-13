# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WarehouseReports::GenericReportJob, type: :job do
  let(:user_id) { 1 }
  let(:report_class) { 'GrdaWarehouse::WarehouseReports::Youth::Export' }
  let(:report_id) { 123 }
  let(:job) { described_class.new }

  describe '#perform' do
    context 'when the advisory lock cannot be obtained' do
      before do
        # with_advisory_lock returns false when it fails to acquire the lock (timeout: 0)
        allow(ApplicationRecord).to receive(:with_advisory_lock).and_return(false)
        allow(job).to receive(:requeue_at)
      end

      it 'requeues the job and returns false' do
        result = job.perform(user_id: user_id, report_class: report_class, report_id: report_id)

        expect(job).to have_received(:requeue_at).with(
          instance_of(ActiveSupport::TimeWithZone),
          /already running \(advisory lock contention\)/,
        )
        expect(result).to be(false)
      end
    end

    context 'when the advisory lock is obtained' do
      let(:report) { instance_double(GrdaWarehouse::WarehouseReports::Youth::Export, run_and_save!: true) }

      before do
        # with_advisory_lock yields to the block and returns its result when successful
        allow(HudReports::ReportInstance).to receive(:with_advisory_lock) { |*_args, &block| block.call }
        allow(GrdaWarehouse::WarehouseReports::Youth::Export).to receive(:find_by).with(id: report_id).and_return(report)
        allow(NotifyUser).to receive_message_chain(:report_completed, :deliver_later)
      end

      it 'runs the report and returns the completion status' do
        result = job.perform(user_id: user_id, report_class: report_class, report_id: report_id)

        expect(report).to have_received(:run_and_save!)
        expect(result).to be(true)
      end

      it 'sends completion notification to the correct user' do
        expect(NotifyUser).to receive(:report_completed).with(user_id, report).and_return(double(deliver_later: true))
        job.perform(user_id: user_id, report_class: report_class, report_id: report_id)
      end

      context 'when the report record is missing' do
        before do
          allow(GrdaWarehouse::WarehouseReports::Youth::Export).to receive(:find_by).with(id: report_id).and_return(nil)
        end

        it 'returns false gracefully' do
          result = job.perform(user_id: user_id, report_class: report_class, report_id: report_id)
          expect(result).to be(false)
        end
      end
    end

    context 'when an invalid report class is provided' do
      let(:invalid_class) { 'NonExistent::Report' }

      before do
        allow(HudReports::ReportInstance).to receive(:with_advisory_lock) { |*_args, &block| block.call }
      end

      it 'pings the notifier and returns false' do
        # Setup notifier mock
        notifier = double('notifier')
        allow(job).to receive(:setup_notifier)
        job.instance_variable_set(:@notifier, notifier)
        job.instance_variable_set(:@send_notifications, true)
        expect(notifier).to receive(:ping).with(/is not included in the allowed list/)

        result = job.perform(user_id: user_id, report_class: invalid_class, report_id: report_id)
        expect(result).to be(false)
      end
    end
  end
end

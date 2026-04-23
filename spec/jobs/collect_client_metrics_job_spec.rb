###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CollectClientMetricsJob, type: :job do
  let(:calculation_date) { Date.current }

  before do
    allow(GrdaWarehouseBase).to receive(:with_advisory_lock).and_yield
  end

  describe '#perform' do
    context 'when all metrics are stable' do
      before do
        allow(GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector).
          to receive(:run_daily_collection).and_return([])
      end

      it 'runs metric snapshot collection' do
        expect(GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector).to receive(:run_daily_collection).
          with(
            entity_type: 'GrdaWarehouse::Hud::Client',
            calculation_date: calculation_date,
            metric_names: nil,
          ).and_return([])
        described_class.new.perform(calculation_date)
      end

      it 'does not enqueue a follow-up job' do
        expect(described_class).not_to receive(:perform_later)
        described_class.new.perform(calculation_date)
      end
    end

    context 'when some metrics are skipped and before the retry deadline' do
      before do
        allow(GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector).
          to receive(:run_daily_collection).and_return(['max_household_size', 'min_household_size'])
        allow(Time).to receive(:current).and_return(
          Time.current.change(hour: described_class::RETRY_DEADLINE_HOUR - 1),
        )
      end

      it 'enqueues a targeted follow-up job for the skipped metrics' do
        skipped_metric_names = ['max_household_size', 'min_household_size']
        expect do
          described_class.new.perform(calculation_date)
        end.to have_enqueued_job(described_class).
          with(calculation_date, metric_names: skipped_metric_names).
          at(a_value > Time.current)
      end
    end

    context 'when some metrics are skipped but past the retry deadline' do
      before do
        allow(GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector).
          to receive(:run_daily_collection).and_return(['max_household_size'])
      end

      it 'does not enqueue a follow-up job when hour is past the deadline' do
        allow(Time).to receive(:current).and_return(
          Time.current.change(hour: described_class::RETRY_DEADLINE_HOUR + 1),
        )
        expect(described_class).not_to receive(:perform_later)
        described_class.new.perform(calculation_date)
      end

      it 'does not enqueue a follow-up job when hour equals the deadline exactly' do
        allow(Time).to receive(:current).and_return(
          Time.current.change(hour: described_class::RETRY_DEADLINE_HOUR),
        )
        expect(described_class).not_to receive(:perform_later)
        described_class.new.perform(calculation_date)
      end
    end

    context 'when called with specific metric_names for a targeted retry' do
      before do
        allow(GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector).
          to receive(:run_daily_collection).and_return([])
      end

      it 'passes metric_names through to the collector' do
        expect(GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector).to receive(:run_daily_collection).
          with(
            entity_type: 'GrdaWarehouse::Hud::Client',
            calculation_date: calculation_date,
            metric_names: ['max_household_size'],
          ).and_return([])
        described_class.new.perform(calculation_date, metric_names: ['max_household_size'])
      end
    end
  end
end

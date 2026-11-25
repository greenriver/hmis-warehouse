###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector, type: :model do
  let(:calculation_date) { Date.current }
  let(:entity_type) { 'GrdaWarehouse::Hud::Client' }

  let!(:metric_definition) do
    create(
      :grda_warehouse_monitoring_metric_definition,
      name: 'test_metric',
      entity_type: entity_type,
      calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator',
      count_change_threshold: 30,
      active: true,
    )
  end

  let!(:client1) { create(:grda_warehouse_hud_client) }
  let!(:client2) { create(:grda_warehouse_hud_client) }

  let!(:processed1) do
    create(
      :grda_warehouse_warehouse_clients_processed,
      client_id: client1.id,
      routine: 'service_history',
      days_homeless_last_three_years: 100,
    )
  end

  let!(:processed2) do
    create(
      :grda_warehouse_warehouse_clients_processed,
      client_id: client2.id,
      routine: 'service_history',
      days_homeless_last_three_years: 50,
    )
  end

  # RSpec wraps each example in a transaction for rollback-based cleanup.
  # PostgreSQL does not allow setting isolation level inside a nested transaction,
  # so we stub the REPEATABLE READ call to simply yield for all tests that do not
  # specifically test transaction behavior. Tests that do care override this stub.
  before do
    allow(GrdaWarehouseBase).to receive(:transaction).and_call_original
    allow(GrdaWarehouseBase).to receive(:transaction).
      with(isolation: :repeatable_read).
      and_yield
  end

  describe '.run_daily_collection' do
    it 'creates snapshots for entities with data' do
      expect do
        described_class.run_daily_collection(
          entity_type: entity_type,
          calculation_date: calculation_date,
          entity_ids: [client1.id, client2.id],
          metric_names: ['test_metric'],
        )
      end.to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(2)
    end

    it 'discovers entities via the default scope when entity_ids is not provided' do
      # client1/client2 are destination clients with processed service history records
      # (processed1/processed2), so they must be discoverable without an explicit entity_ids
      # list — this is the path the real nightly job (CollectClientMetricsJob) exercises.
      expect do
        described_class.run_daily_collection(
          entity_type: entity_type,
          calculation_date: calculation_date,
          metric_names: ['test_metric'],
        )
      end.to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(2)
    end

    it 'enqueues the threshold crossing notification job for the previous day' do
      expect do
        described_class.run_daily_collection(
          entity_type: entity_type,
          calculation_date: calculation_date,
          entity_ids: [client1.id, client2.id],
          metric_names: ['test_metric'],
        )
      end.to have_enqueued_job(NotifyMetricThresholdCrossingsJob).with(calculation_date - 1.day)
    end

    it 'records statistics in calculation run' do
      described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: [client1.id, client2.id],
        metric_names: ['test_metric'],
      )

      run = GrdaWarehouse::Monitoring::MetricCalculationRun.last
      expect(run.status).to eq('completed')
      expect(run.entities_evaluated_count).to eq(2)
      expect(run.snapshots_created_count).to eq(2)
      expect(run.completed_at).to be_present
    end

    context 'when running same collection twice' do
      before do
        described_class.run_daily_collection(
          entity_type: entity_type,
          calculation_date: calculation_date,
          entity_ids: [client1.id],
          metric_names: ['test_metric'],
        )
      end

      it 'reuses existing calculation run record' do
        expect do
          described_class.run_daily_collection(
            entity_type: entity_type,
            calculation_date: calculation_date,
            entity_ids: [client1.id],
            metric_names: ['test_metric'],
          )
        end.not_to change(GrdaWarehouse::Monitoring::MetricCalculationRun, :count)
      end
    end
  end

  describe 'threshold detection' do
    before do
      # Create initial snapshot
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        entity: client1,
        metric_definition: metric_definition,
        initial_observation_date: 1.day.ago,
        current_observation_date: 1.day.ago,
        initial_value: 100,
        current_value: 100,
      )
    end

    context 'when value changes below threshold' do
      before do
        processed1.update!(days_homeless_last_three_years: 110) # +10, below threshold of 30
      end

      it 'updates existing snapshot' do
        expect do
          described_class.run_daily_collection(
            entity_type: entity_type,
            calculation_date: calculation_date,
            entity_ids: [client1.id],
            metric_names: ['test_metric'],
          )
        end.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)

        snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.
          for_entity(client1).
          for_metric(metric_definition).
          first

        expect(snapshot.current_value).to eq(110)
        expect(snapshot.current_observation_date).to eq(calculation_date)
        expect(snapshot.initial_value).to eq(100) # Unchanged
      end
    end

    context 'when value changes above threshold' do
      before do
        processed1.update!(days_homeless_last_three_years: 150) # +50, above threshold of 30
      end

      it 'creates new snapshot' do
        expect do
          described_class.run_daily_collection(
            entity_type: entity_type,
            calculation_date: calculation_date,
            entity_ids: [client1.id],
            metric_names: ['test_metric'],
          )
        end.to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(1)

        new_snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.
          for_entity(client1).
          for_metric(metric_definition).
          where(initial_observation_date: calculation_date).
          first

        expect(new_snapshot.initial_value).to eq(150)
        expect(new_snapshot.current_value).to eq(150)
      end
    end

    context 'when both count and percent thresholds are configured' do
      let!(:metric_with_both_thresholds) do
        create(
          :grda_warehouse_monitoring_metric_definition,
          name: 'test_metric_both',
          entity_type: entity_type,
          calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator',
          count_change_threshold: 30,
          percent_change_threshold: 20.0,
          active: true,
        )
      end

      before do
        # client2 can only have one warehouse_clients_processed row for 'service_history'
        # (uidx_warehouse_clients_processed_on_client_id_and_routine), so reuse processed2
        # as the baseline for this context rather than creating a second row.
        processed2.update!(days_homeless_last_three_years: 100)

        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client2,
          metric_definition: metric_with_both_thresholds,
          initial_observation_date: 1.day.ago,
          current_observation_date: 1.day.ago,
          initial_value: 100,
          current_value: 100,
        )
      end

      context 'when count threshold met but percent threshold not met' do
        before do
          # Delete the snapshot created by outer before block and create a new one with correct baseline
          # Need baseline large enough that +30 count is less than 20% change
          # Baseline = 200, +35 count = 17.5% (below 20%), count threshold met (35 > 30)
          # IMPORTANT: snapshot must be from yesterday or it won't be found as "current"
          GrdaWarehouse::Monitoring::MetricSnapshot.
            for_entity(client2).
            for_metric(metric_with_both_thresholds).
            delete_all

          processed2.update!(days_homeless_last_three_years: 200)
          create(
            :grda_warehouse_monitoring_metric_snapshot,
            entity: client2,
            metric_definition: metric_with_both_thresholds,
            initial_observation_date: 1.day.ago,
            current_observation_date: 1.day.ago,
            initial_value: 200,
            current_value: 200,
          )
          processed2.update!(days_homeless_last_three_years: 235)
        end

        it 'updates existing snapshot without creating new one' do
          expect do
            described_class.run_daily_collection(
              entity_type: entity_type,
              calculation_date: calculation_date,
              entity_ids: [client2.id],
              metric_names: ['test_metric_both'],
            )
          end.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)

          snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.
            for_entity(client2).
            for_metric(metric_with_both_thresholds).
            order(created_at: :desc).
            first

          expect(snapshot.current_value).to eq(235)
          expect(snapshot.initial_value).to eq(200)
        end
      end

      context 'when percent threshold met but count threshold not met' do
        before do
          # +25% (above 20%), but only +25 count (below 30)
          processed2.update!(days_homeless_last_three_years: 125)
        end

        it 'updates existing snapshot without creating new one' do
          expect do
            described_class.run_daily_collection(
              entity_type: entity_type,
              calculation_date: calculation_date,
              entity_ids: [client2.id],
              metric_names: ['test_metric_both'],
            )
          end.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)

          snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.
            for_entity(client2).
            for_metric(metric_with_both_thresholds).
            first

          expect(snapshot.current_value).to eq(125)
          expect(snapshot.initial_value).to eq(100)
        end
      end

      context 'when both thresholds are met' do
        before do
          # +40 count (above 30) AND +40% (above 20%)
          processed2.update!(days_homeless_last_three_years: 140)
        end

        it 'creates new snapshot' do
          expect do
            described_class.run_daily_collection(
              entity_type: entity_type,
              calculation_date: calculation_date,
              entity_ids: [client2.id],
              metric_names: ['test_metric_both'],
            )
          end.to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(1)

          new_snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.
            for_entity(client2).
            for_metric(metric_with_both_thresholds).
            where(initial_observation_date: calculation_date).
            first

          expect(new_snapshot.initial_value).to eq(140)
          expect(new_snapshot.current_value).to eq(140)
        end
      end
    end
  end

  describe 'per-run (rate) change detection' do
    # days_homeless is a rolling-window metric: its value drifts ~1/day. A crossing
    # should only fire when a single run moves the value past the threshold, NOT when
    # gradual day-over-day drift accumulates past it relative to the original baseline.
    def run_collection
      described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: [client1.id],
        metric_names: ['test_metric'],
      )
    end

    context 'when the value drifts gradually past the cumulative threshold' do
      # Reproduces the production bug (Previous 247, New 246, Change -1): a baseline set
      # weeks ago whose current_value has drifted ~1/day. The cumulative move from
      # initial_value (212 -> 247 = 35) crosses the threshold, but the day-over-day change
      # is only +1 and must NOT trigger a crossing.
      before do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: 35.days.ago,
          current_observation_date: 1.day.ago,
          initial_value: 212,
          current_value: 246,
        )
        processed1.update!(days_homeless_last_three_years: 247)
      end

      it 'does not create a new crossing snapshot' do
        expect { run_collection }.
          not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
      end

      it 'updates the existing snapshot in place, preserving the baseline' do
        run_collection

        snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.
          for_entity(client1).
          for_metric(metric_definition).
          first

        expect(snapshot.current_value).to eq(247)
        expect(snapshot.initial_value).to eq(212)
        expect(snapshot.current_observation_date).to eq(calculation_date)
      end
    end

    context 'when a single run jumps past the threshold' do
      before do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: 35.days.ago,
          current_observation_date: 1.day.ago,
          initial_value: 500,
          current_value: 200,
        )
        processed1.update!(days_homeless_last_three_years: 235) # +35 vs the previous run (200)
      end

      it 'creates a new crossing snapshot measured against the previous run value' do
        expect { run_collection }.
          to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(1)

        new_snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.
          for_entity(client1).
          for_metric(metric_definition).
          where(initial_observation_date: calculation_date).
          first

        expect(new_snapshot.initial_value).to eq(235)
      end
    end

    context 'when a multi-day gap accumulates past the threshold but per-day stays small' do
      # Runs were missed for 10 days; the value moved +45 total (4.5/day). Normalizing by
      # elapsed days keeps this below the 30/day threshold, so no crossing fires.
      before do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: 40.days.ago,
          current_observation_date: 10.days.ago,
          initial_value: 200,
          current_value: 200,
        )
        processed1.update!(days_homeless_last_three_years: 245)
      end

      it 'does not create a crossing snapshot' do
        expect { run_collection }.
          not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
      end
    end
  end

  describe 'change detection across threshold configurations' do
    # Count and percent thresholds are user-configurable in the admin UI, so the shared
    # detection logic must behave for arbitrary configurations, not just the seeded defaults.
    # MinHouseholdSizeCalculator uses the default strategy (absolute change since the last
    # value, not gap-normalized).
    min_calc = 'GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator'

    def run_for(metric_name)
      described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: [client1.id],
        metric_names: [metric_name],
      )
    end

    def stub_min_value(value)
      allow(GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator).
        to receive(:calculate_batch).and_return({ client1.id => value })
    end

    before do
      allow(GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator).
        to receive(:data_stable?).and_return(true)
    end

    context 'default strategy with a count threshold above 1' do
      let!(:metric) do
        create(
          :grda_warehouse_monitoring_metric_definition,
          name: 'hh_count',
          entity_type: entity_type,
          calculator_class: min_calc,
          count_change_threshold: 3,
          active: true,
        )
      end

      before do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric,
          initial_observation_date: 20.days.ago,
          current_observation_date: 1.day.ago,
          initial_value: 4,
          current_value: 10, # drifted from the initial baseline over time
        )
      end

      it 'does not cross on a small per-run change even when far from the initial baseline' do
        # |12 - 10| = 2 (< 3) since the last run. |12 - 4| = 8 from the initial baseline would
        # have crossed under the old cumulative-from-initial comparison.
        stub_min_value(12)

        expect { run_for('hh_count') }.
          not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
      end

      it 'crosses on a single-run jump past the threshold' do
        stub_min_value(14) # |14 - 10| = 4 (>= 3)

        expect { run_for('hh_count') }.
          to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(1)
      end
    end

    context 'default strategy with a percent threshold' do
      let!(:metric) do
        create(
          :grda_warehouse_monitoring_metric_definition,
          name: 'hh_percent',
          entity_type: entity_type,
          calculator_class: min_calc,
          count_change_threshold: nil,
          percent_change_threshold: 20.0,
          active: true,
        )
      end

      before do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric,
          initial_observation_date: 1.day.ago,
          current_observation_date: 1.day.ago,
          initial_value: 100,
          current_value: 100,
        )
      end

      it 'crosses when the change since the last value exceeds the percent threshold' do
        stub_min_value(130) # +30%

        expect { run_for('hh_percent') }.
          to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(1)
      end

      it 'does not cross when the percent change is below the threshold' do
        stub_min_value(110) # +10%

        expect { run_for('hh_percent') }.
          not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
      end
    end

    context 'default strategy with both count and percent thresholds (AND logic)' do
      let!(:metric) do
        create(
          :grda_warehouse_monitoring_metric_definition,
          name: 'hh_both',
          entity_type: entity_type,
          calculator_class: min_calc,
          count_change_threshold: 3,
          percent_change_threshold: 20.0,
          active: true,
        )
      end

      before do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric,
          initial_observation_date: 1.day.ago,
          current_observation_date: 1.day.ago,
          initial_value: 100,
          current_value: 100,
        )
      end

      it 'crosses only when both thresholds are met' do
        stub_min_value(130) # +30 count and +30%

        expect { run_for('hh_both') }.
          to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(1)
      end

      it 'does not cross when only the count threshold is met' do
        stub_min_value(105) # +5 count (>= 3) but only +5% (< 20)

        expect { run_for('hh_both') }.
          not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
      end
    end

    context 'rate strategy with a percent threshold across a multi-day gap' do
      # days_homeless normalizes both count and percent by elapsed days, so a large total
      # change spread across a gap is evaluated as a per-day rate.
      let!(:metric) do
        create(
          :grda_warehouse_monitoring_metric_definition,
          name: 'homeless_percent',
          entity_type: entity_type,
          calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator',
          count_change_threshold: nil,
          percent_change_threshold: 10.0,
          active: true,
        )
      end

      before do
        allow(GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator).
          to receive(:data_stable?).and_return(true)
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric,
          initial_observation_date: 20.days.ago,
          current_observation_date: 10.days.ago,
          initial_value: 100,
          current_value: 100,
        )
      end

      it 'does not cross when the per-day percent stays below the threshold' do
        # +45 over 10 days = 4.5/day = 4.5% per day (< 10%), though the raw total is 45%.
        processed1.update!(days_homeless_last_three_years: 145)

        expect { run_for('homeless_percent') }.
          not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
      end
    end
  end

  describe 'transaction isolation' do
    it 'wraps all stable metrics in a single repeatable read transaction' do
      allow(GrdaWarehouseBase).to receive(:transaction).and_call_original
      # The test suite wraps everything in a transaction, so REPEATABLE READ
      # isolation cannot actually be set in a nested call — stub it to just yield.
      expect(GrdaWarehouseBase).to receive(:transaction).
        with(isolation: :repeatable_read).
        once.
        and_yield

      described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: [client1.id],
        metric_names: ['test_metric'],
      )
    end
  end

  describe 'stability partitioning' do
    before do
      allow(GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator).
        to receive(:data_stable?).and_return(false)
    end

    it 'returns the skipped metric name' do
      skipped = described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: [client1.id],
        metric_names: ['test_metric'],
      )
      expect(skipped).to eq(['test_metric'])
    end

    it 'does not create snapshots for skipped metrics' do
      expect do
        described_class.run_daily_collection(
          entity_type: entity_type,
          calculation_date: calculation_date,
          entity_ids: [client1.id],
          metric_names: ['test_metric'],
        )
      end.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
    end

    it 'does not open a transaction when all metrics are skipped' do
      # maintain! and other internal calls may still use transaction; we only care
      # that no REPEATABLE READ transaction is opened when all metrics are unstable
      allow(GrdaWarehouseBase).to receive(:transaction).and_call_original
      expect(GrdaWarehouseBase).not_to receive(:transaction).
        with(isolation: :repeatable_read)
      described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: [client1.id],
        metric_names: ['test_metric'],
      )
    end

    context 'when a second metric uses a stable calculator' do
      let!(:second_metric_definition) do
        create(
          :grda_warehouse_monitoring_metric_definition,
          name: 'second_metric',
          entity_type: entity_type,
          calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator',
          count_change_threshold: 1,
          active: true,
        )
      end

      before do
        allow(GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator).
          to receive(:data_stable?).and_return(true)
        allow(GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator).
          to receive(:calculate_batch).and_return({ client1.id => 2 })
      end

      it 'collects the stable metric and skips the unstable one' do
        skipped = described_class.run_daily_collection(
          entity_type: entity_type,
          calculation_date: calculation_date,
          entity_ids: [client1.id],
        )
        expect(skipped).to eq(['test_metric'])
        expect(GrdaWarehouse::Monitoring::MetricSnapshot.count).to eq(1)
      end
    end
  end

  describe 'error handling for a single metric' do
    let!(:second_metric_definition) do
      create(
        :grda_warehouse_monitoring_metric_definition,
        name: 'second_metric',
        entity_type: entity_type,
        calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator',
        count_change_threshold: 1,
        active: true,
      )
    end

    before do
      allow(GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator).
        to receive(:data_stable?).and_return(true)
      allow(GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator).
        to receive(:calculate_batch).and_raise(StandardError, 'boom')
      allow(GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator).
        to receive(:data_stable?).and_return(true)
      allow(GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator).
        to receive(:calculate_batch).and_return({ client1.id => 2 })
    end

    it 'still processes the other metric and records the failure on the run' do
      described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: [client1.id, client2.id],
      )

      run = GrdaWarehouse::Monitoring::MetricCalculationRun.last
      expect(run.calculation_errors_count).to eq(2) # size of the batch that raised
      expect(run.status).to eq('completed') # errors do not currently mark the run failed

      expect(
        GrdaWarehouse::Monitoring::MetricSnapshot.for_entity(client1).for_metric(second_metric_definition),
      ).to exist
      expect(
        GrdaWarehouse::Monitoring::MetricSnapshot.for_entity(client1).for_metric(metric_definition),
      ).not_to exist
    end
  end

  describe 'CsvRowCountMetricCalculator integration' do
    let(:csv_entity_type) { 'GrdaWarehouse::DataSource' }
    let(:data_source) { create(:grda_warehouse_data_source) }

    let!(:csv_metric_definition) do
      create(
        :grda_warehouse_monitoring_metric_definition,
        name: 'csv_enrollment_count',
        entity_type: csv_entity_type,
        calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::CsvRowCountMetricCalculator',
        subtype: 'Enrollment.csv',
        count_change_threshold: 1,
        active: true,
      )
    end

    def run_csv_collection(entity_ids: [data_source.id])
      described_class.run_daily_collection(
        entity_type: csv_entity_type,
        calculation_date: calculation_date,
        entity_ids: entity_ids,
        metric_names: ['csv_enrollment_count'],
      )
    end

    context 'when an import log exists with pre_processed data' do
      before do
        create(
          :hmis_csv_importer_log,
          data_source: data_source,
          status: 'complete',
          completed_at: calculation_date.end_of_day - 1.minute,
          summary: { 'Enrollment.csv' => { 'pre_processed' => 500 } },
        )
      end

      it 'creates a snapshot for the data source' do
        expect { run_csv_collection }.
          to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(1)

        snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.
          where(entity_type: csv_entity_type, entity_id: data_source.id).
          for_metric(csv_metric_definition).
          first

        expect(snapshot).to be_present
        expect(snapshot.initial_value).to eq(500)
        expect(snapshot.current_value).to eq(500)
        expect(snapshot.initial_observation_date).to eq(calculation_date)
      end
    end

    context 'when the value changes beyond the threshold' do
      before do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity_type: csv_entity_type,
          entity_id: data_source.id,
          metric_definition: csv_metric_definition,
          initial_observation_date: 1.day.ago,
          current_observation_date: 1.day.ago,
          initial_value: 500,
          current_value: 500,
        )
        create(
          :hmis_csv_importer_log,
          data_source: data_source,
          status: 'complete',
          completed_at: calculation_date.end_of_day - 1.minute,
          summary: { 'Enrollment.csv' => { 'pre_processed' => 510 } },
        )
      end

      it 'creates a new snapshot, enabling crossing detection' do
        expect { run_csv_collection }.
          to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(1)

        new_snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.
          where(entity_type: csv_entity_type, entity_id: data_source.id).
          for_metric(csv_metric_definition).
          where(initial_observation_date: calculation_date).
          first

        expect(new_snapshot).to be_present
        expect(new_snapshot.initial_value).to eq(510)
      end
    end

    context 'when no import log exists for the data source' do
      it 'does not create a snapshot' do
        expect { run_csv_collection }.
          not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
      end
    end

    context 'when the metric: argument is not forwarded (regression guard)' do
      before do
        create(
          :hmis_csv_importer_log,
          data_source: data_source,
          status: 'complete',
          completed_at: calculation_date.end_of_day - 1.minute,
          summary: { 'Enrollment.csv' => { 'pre_processed' => 200 } },
        )
      end

      it 'calculator receives the metric keyword and returns data' do
        expect(
          GrdaWarehouse::Monitoring::MetricCalculators::CsvRowCountMetricCalculator,
        ).to receive(:calculate_batch).
          with(anything, anything, metric: csv_metric_definition).
          and_call_original

        run_csv_collection
      end
    end
  end

  describe 'stale baseline handling' do
    # Regression guard: load_current_snapshots_for_batch must use ..@calculation_date - 1.day
    # (upper-bound range). The wrong direction (@calculation_date - 1.day..) would make
    # months-old snapshots invisible, causing them to be treated as "first time" and creating
    # spurious new snapshots that trigger false crossing notifications.

    let!(:stale_snapshot) do
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        entity: client1,
        metric_definition: metric_definition,
        initial_observation_date: 3.months.ago,
        current_observation_date: 3.months.ago,
        initial_value: 100,
        current_value: 100,
      )
    end

    def run_stale_collection
      described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: [client1.id],
        metric_names: ['test_metric'],
      )
    end

    it 'finds a months-old snapshot as the current baseline' do
      # processed1 has 100 days_homeless (unchanged). If the stale snapshot were invisible
      # the collector would treat client1 as "first time" and create a new snapshot (+1).
      # With the fix, it finds the baseline and updates in place — count unchanged.
      expect { run_stale_collection }.
        not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
    end

    it 'updates the stale snapshot observation date, preventing spurious crossings' do
      run_stale_collection
      stale_snapshot.reload
      expect(stale_snapshot.current_observation_date).to eq(calculation_date)
      expect(stale_snapshot.current_value).to eq(100)
    end
  end

  describe 'second run for the same calculation date' do
    def collect(metric_names: ['test_metric'], entity_ids: nil, date: calculation_date)
      described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: date,
        entity_ids: entity_ids,
        metric_names: metric_names,
      )
    end

    def snapshots_for(client, definition = metric_definition)
      GrdaWarehouse::Monitoring::MetricSnapshot.where(entity: client, metric_definition: definition)
    end

    context 'when the client has a single snapshot' do
      let!(:snapshot) do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: calculation_date - 10.days,
          current_observation_date: calculation_date - 1.day,
          initial_value: 100,
          current_value: 100,
        )
      end

      before { collect }

      it 'creates no snapshot and keeps the value from the first run' do
        expect(snapshot.reload.current_observation_date).to eq(calculation_date)
        processed1.update!(days_homeless_last_three_years: 200)

        expect { collect }.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
        expect(snapshots_for(client1).pluck(:current_value)).to eq([100])
      end

      it 'leaves the calculation run record from the first run unchanged' do
        run = GrdaWarehouse::Monitoring::MetricCalculationRun.find_by!(entity_type: entity_type, calculation_date: calculation_date)

        expect { collect }.not_to(change { run.reload.attributes.slice('completed_at', 'snapshots_created_count', 'snapshots_updated_count') })
      end

      it 'completes a run record the first run left unfinished' do
        run = GrdaWarehouse::Monitoring::MetricCalculationRun.find_by!(entity_type: entity_type, calculation_date: calculation_date)
        run.update!(status: 'running', completed_at: nil)

        collect

        expect(run.reload).to have_attributes(status: 'completed', completed_at: be_within(1.minute).of(Time.current))
      end

      it 'reports no metrics for retry' do
        expect(collect).to eq([])
      end
    end

    context 'when the client has a superseded snapshot' do
      let!(:superseded_snapshot) do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: calculation_date - 20.days,
          current_observation_date: calculation_date - 11.days,
          initial_value: 40,
          current_value: 60,
        )
      end

      let!(:current_snapshot) do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: calculation_date - 10.days,
          current_observation_date: calculation_date - 1.day,
          initial_value: 100,
          current_value: 100,
        )
      end

      it 'leaves the superseded snapshot unchanged' do
        collect
        collect

        expect(superseded_snapshot.reload).to have_attributes(
          current_value: 60,
          current_observation_date: calculation_date - 11.days,
        )
      end
    end

    context 'when the scheduled job path omits metric_names' do
      it 'creates no snapshots and keeps the values from the first run' do
        collect(metric_names: nil)
        processed1.update!(days_homeless_last_three_years: 200)

        expect { collect(metric_names: nil) }.not_to(change { snapshots_for(client1).count })
        expect(snapshots_for(client1).pluck(:current_value)).to eq([100])
      end
    end

    context 'when the first run skipped an unstable metric' do
      let!(:second_metric_definition) do
        create(
          :grda_warehouse_monitoring_metric_definition,
          name: 'second_metric',
          entity_type: entity_type,
          calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator',
          count_change_threshold: 1,
          active: true,
        )
      end
      let(:both_metrics) { ['test_metric', 'second_metric'] }

      before do
        allow(GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator).
          to receive(:data_stable?).and_return(true)
        allow(GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator).
          to receive(:calculate_batch).and_return({ client1.id => 2 })
        allow(GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator).
          to receive(:data_stable?).and_return(false)
        collect(metric_names: both_metrics, entity_ids: [client1.id])
        allow(GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator).
          to receive(:data_stable?).and_return(true)
        allow(GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator).
          to receive(:calculate_batch) { |entities, *| entities.map(&:id).include?(client1.id) ? { client1.id => 5 } : {} }
      end

      it 'collects only the skipped metric' do
        expect(collect(metric_names: both_metrics)).to eq([])

        expect(GrdaWarehouse::Monitoring::MetricSnapshot.where(metric_definition: metric_definition).pluck(:current_value)).to contain_exactly(100, 50)
        expect(snapshots_for(client1, second_metric_definition).pluck(:initial_value, :current_value)).to eq([[2, 2]])
      end

      context 'when the skipped metric is still unstable on the retry' do
        before do
          allow(GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator).
            to receive(:data_stable?).and_return(false)
        end

        it 'reports the unstable metric for retry' do
          expect(collect(metric_names: both_metrics, entity_ids: [client1.id])).to eq(['test_metric'])
        end

        it 'leaves the run record from the first run unchanged' do
          run = GrdaWarehouse::Monitoring::MetricCalculationRun.find_by!(entity_type: entity_type, calculation_date: calculation_date)

          expect { collect(metric_names: both_metrics, entity_ids: [client1.id]) }.not_to(
            change { run.reload.attributes.slice('completed_at', 'snapshots_created_count', 'snapshots_updated_count', 'metrics_calculated_count') },
          )
        end
      end
    end

    context 'when a scoped run follows the full run for the date' do
      it 'skips the client already collected' do
        collect
        processed1.update!(days_homeless_last_three_years: 200)

        expect { collect(entity_ids: [client1.id]) }.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
        expect(snapshots_for(client1).pluck(:current_value)).to eq([100])
      end
    end

    context 'when a scoped run precedes the full run for the date' do
      it 'collects the clients the scoped run did not cover and skips the one it did' do
        collect(entity_ids: [client1.id])
        processed1.update!(days_homeless_last_three_years: 200)
        collect

        expect(snapshots_for(client1).pluck(:current_value)).to eq([100])
        expect(snapshots_for(client2).pluck(:current_value)).to eq([50])
      end
    end

    context 'when only some clients already have a snapshot for the date' do
      before do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: calculation_date - 10.days,
          current_observation_date: calculation_date,
          initial_value: 100,
          current_value: 100,
        )
        processed1.update!(days_homeless_last_three_years: 200)
      end

      it 'collects only the client without one' do
        expect { collect }.to change { snapshots_for(client2).count }.from(0).to(1)

        expect(snapshots_for(client1).pluck(:current_value)).to eq([100])
        expect(snapshots_for(client2).pluck(:current_value)).to eq([50])
      end

      it 'replaces the run record counts with those of the partial run' do
        collect

        expect(GrdaWarehouse::Monitoring::MetricCalculationRun.find_by!(entity_type: entity_type, calculation_date: calculation_date)).
          to have_attributes(entities_evaluated_count: 2, metrics_calculated_count: 1, snapshots_created_count: 1)
      end
    end

    context 'when a scoped run follows the full run and the next date is then collected' do
      let(:next_date) { calculation_date + 1.day }

      def rows_for(client)
        snapshots_for(client).order(:id).pluck(:initial_value, :current_value, :initial_observation_date, :current_observation_date)
      end

      let!(:superseded_snapshot) do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: calculation_date - 20.days,
          current_observation_date: calculation_date - 11.days,
          initial_value: 40,
          current_value: 60,
        )
      end

      let!(:current_snapshot) do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: calculation_date - 10.days,
          current_observation_date: calculation_date - 1.day,
          initial_value: 100,
          current_value: 100,
        )
      end

      let(:superseded_row) { [40, 60, calculation_date - 20.days, calculation_date - 11.days] }

      before { collect }

      context 'when the scoped value is far from the latest snapshot' do
        before do
          processed1.update!(days_homeless_last_three_years: 500)
          collect(entity_ids: [client1.id])
        end

        it 'leaves the superseded and current snapshots unchanged' do
          expect(rows_for(client1)).to eq(
            [superseded_row, [100, 100, calculation_date - 10.days, calculation_date]],
          )
        end

        it 'records the crossing on the next date against the latest snapshot value' do
          collect(date: next_date)

          expect(rows_for(client1)).to eq(
            [
              superseded_row,
              [100, 100, calculation_date - 10.days, calculation_date],
              [500, 500, next_date, next_date],
            ],
          )
        end
      end

      context 'when the scoped value is within the threshold of the superseded snapshot' do
        before do
          processed1.update!(days_homeless_last_three_years: 70)
          collect(entity_ids: [client1.id])
        end

        it 'leaves the superseded and current snapshots unchanged' do
          expect(rows_for(client1)).to eq(
            [superseded_row, [100, 100, calculation_date - 10.days, calculation_date]],
          )
        end

        it 'extends the current snapshot on the next date when the value is back at its level' do
          processed1.update!(days_homeless_last_three_years: 100)
          collect(date: next_date)

          expect(rows_for(client1)).to eq(
            [superseded_row, [100, 100, calculation_date - 10.days, next_date]],
          )
        end

        it 'records a crossing on the next date when the value moves past the threshold' do
          processed1.update!(days_homeless_last_three_years: 200)
          collect(date: next_date)

          expect(rows_for(client1)).to eq(
            [
              superseded_row,
              [100, 100, calculation_date - 10.days, calculation_date],
              [200, 200, next_date, next_date],
            ],
          )
        end
      end
    end

    context 'when every client already has a snapshot to extend' do
      before do
        [[client1, 100], [client2, 50]].each do |client, value|
          create(
            :grda_warehouse_monitoring_metric_snapshot,
            entity: client,
            metric_definition: metric_definition,
            initial_observation_date: calculation_date - 10.days,
            current_observation_date: calculation_date - 1.day,
            initial_value: value,
            current_value: value,
          )
        end
        collect
      end

      it 'skips the repeat full run even though no snapshot was created' do
        processed1.update!(days_homeless_last_three_years: 200)

        expect { collect }.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)
        expect(snapshots_for(client1).pluck(:current_value)).to eq([100])
      end
    end

    context 'when a full run is for a date before the latest collected date' do
      let!(:snapshot) do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: calculation_date - 10.days,
          current_observation_date: calculation_date,
          initial_value: 100,
          current_value: 100,
        )
      end

      before do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client2,
          metric_definition: metric_definition,
          initial_observation_date: calculation_date - 10.days,
          current_observation_date: calculation_date,
          initial_value: 50,
          current_value: 50,
        )
      end

      it 'skips the clients and leaves their snapshots unchanged' do
        processed1.update!(days_homeless_last_three_years: 200)

        expect do
          described_class.run_daily_collection(
            entity_type: entity_type,
            calculation_date: calculation_date - 1.day,
            metric_names: ['test_metric'],
          )
        end.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)

        expect(snapshot.reload).to have_attributes(current_observation_date: calculation_date, current_value: 100)
      end
    end

    context 'when a past-date full run covers a client whose snapshot ends before that date' do
      let(:past_date) { calculation_date - 1.day }

      let!(:client1_snapshot) do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client1,
          metric_definition: metric_definition,
          initial_observation_date: calculation_date - 10.days,
          current_observation_date: calculation_date,
          initial_value: 100,
          current_value: 100,
        )
      end

      let!(:client2_snapshot) do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client2,
          metric_definition: metric_definition,
          initial_observation_date: calculation_date - 10.days,
          current_observation_date: calculation_date - 5.days,
          initial_value: 50,
          current_value: 50,
        )
      end

      it 'extends that client and leaves the client with a later snapshot unchanged' do
        processed1.update!(days_homeless_last_three_years: 200)

        expect { collect(date: past_date) }.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)

        expect(client2_snapshot.reload).to have_attributes(
          initial_observation_date: calculation_date - 10.days,
          current_observation_date: past_date,
          current_value: 50,
        )
        expect(client1_snapshot.reload).to have_attributes(
          initial_observation_date: calculation_date - 10.days,
          current_observation_date: calculation_date,
          current_value: 100,
        )
      end
    end
  end

  describe 'run with no matching metric' do
    def collect(metric_names:)
      described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: nil,
        metric_names: metric_names,
      )
    end

    context 'when no active metric matches the requested names' do
      it 'still records the calculation run for the date' do
        expect { collect(metric_names: ['no_such_metric']) }.
          to change { GrdaWarehouse::Monitoring::MetricCalculationRun.where(entity_type: entity_type, calculation_date: calculation_date).count }.from(0).to(1)
      end
    end
  end

  describe 'snapshot updated in place' do
    let!(:snapshot) do
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        entity: client1,
        metric_definition: metric_definition,
        initial_observation_date: Date.new(2026, 1, 10),
        current_observation_date: Date.new(2026, 1, 14),
        initial_value: 100,
        current_value: 100,
        updated_at: Time.utc(2026, 1, 14, 7, 0, 0),
      )
    end

    it 'records the update time in UTC' do
      Time.use_zone('America/New_York') do
        travel_to Time.zone.local(2026, 1, 15, 2, 20, 0) do
          described_class.run_daily_collection(
            entity_type: entity_type,
            calculation_date: Date.new(2026, 1, 15),
            entity_ids: [client1.id],
            metric_names: ['test_metric'],
          )

          snapshot.reload
          expect(snapshot.current_observation_date).to eq(Date.new(2026, 1, 15))
          expect(snapshot.updated_at).to eq(Time.utc(2026, 1, 15, 7, 20, 0))
        end
      end
    end
  end

  describe 'cleanup old snapshots' do
    let!(:old_snapshot) do
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        entity: client1,
        metric_definition: metric_definition,
        initial_observation_date: 4.years.ago,
        current_observation_date: 4.years.ago,
        initial_value: 50,
        current_value: 50,
      )
    end

    let!(:recent_snapshot) do
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        entity: client1,
        metric_definition: metric_definition,
        initial_observation_date: 1.year.ago,
        current_observation_date: 1.year.ago,
        initial_value: 75,
        current_value: 75,
      )
    end

    it 'deletes snapshots older than 3 years' do
      # The recent_snapshot (1 year old, initial_value: 75) is now found as the current
      # baseline regardless of age (no date filter). The calculated value (100) changes
      # by 25, which is below the count_change_threshold of 30, so no new snapshot is
      # created — only the old 4-year snapshot is deleted. Net count change = -1.
      expect do
        described_class.run_daily_collection(
          entity_type: entity_type,
          calculation_date: calculation_date,
          entity_ids: [client1.id],
          metric_names: ['test_metric'],
        )
      end.to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(-1)

      expect(GrdaWarehouse::Monitoring::MetricSnapshot.where(id: old_snapshot.id).exists?).to be false
      expect(GrdaWarehouse::Monitoring::MetricSnapshot.where(id: recent_snapshot.id).exists?).to be true
    end
  end
end

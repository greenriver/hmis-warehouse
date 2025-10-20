###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

  describe '.run_daily_collection' do
    it 'creates metric calculation run record' do
      expect do
        described_class.run_daily_collection(
          entity_type: entity_type,
          calculation_date: calculation_date,
          entity_ids: [client1.id, client2.id],
        )
      end.to change(GrdaWarehouse::Monitoring::MetricCalculationRun, :count).by(1)
    end

    it 'creates snapshots for entities with data' do
      expect do
        described_class.run_daily_collection(
          entity_type: entity_type,
          calculation_date: calculation_date,
          entity_ids: [client1.id, client2.id],
        )
      end.to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(2)
    end

    it 'records statistics in calculation run' do
      described_class.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: [client1.id, client2.id],
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
        )
      end

      it 'reuses existing calculation run record' do
        expect do
          described_class.run_daily_collection(
            entity_type: entity_type,
            calculation_date: calculation_date,
            entity_ids: [client1.id],
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

      let!(:processed3) do
        create(
          :grda_warehouse_warehouse_clients_processed,
          client_id: client2.id,
          routine: 'service_history',
          days_homeless_last_three_years: 100,
        )
      end

      before do
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
          # +35 count (above 30), but only +35% (below 20% would be +20)
          processed3.update!(days_homeless_last_three_years: 135)
        end

        it 'updates existing snapshot without creating new one' do
          expect do
            described_class.run_daily_collection(
              entity_type: entity_type,
              calculation_date: calculation_date,
              entity_ids: [client2.id],
            )
          end.not_to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count)

          snapshot = GrdaWarehouse::Monitoring::MetricSnapshot.
            for_entity(client2).
            for_metric(metric_with_both_thresholds).
            first

          expect(snapshot.current_value).to eq(135)
          expect(snapshot.initial_value).to eq(100)
        end
      end

      context 'when percent threshold met but count threshold not met' do
        before do
          # +25% (above 20%), but only +25 count (below 30)
          processed3.update!(days_homeless_last_three_years: 125)
        end

        it 'updates existing snapshot without creating new one' do
          expect do
            described_class.run_daily_collection(
              entity_type: entity_type,
              calculation_date: calculation_date,
              entity_ids: [client2.id],
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
          processed3.update!(days_homeless_last_three_years: 140)
        end

        it 'creates new snapshot' do
          expect do
            described_class.run_daily_collection(
              entity_type: entity_type,
              calculation_date: calculation_date,
              entity_ids: [client2.id],
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
      expect do
        described_class.run_daily_collection(
          entity_type: entity_type,
          calculation_date: calculation_date,
          entity_ids: [client1.id],
        )
      end.to change(GrdaWarehouse::Monitoring::MetricSnapshot, :count).by(0) # -1 old + 1 new = 0

      expect(GrdaWarehouse::Monitoring::MetricSnapshot.exists?(old_snapshot.id)).to be false
      expect(GrdaWarehouse::Monitoring::MetricSnapshot.exists?(recent_snapshot.id)).to be true
    end
  end
end

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::MetricCalculationRun, type: :model do
  let(:entity_type) { 'GrdaWarehouse::Hud::Client' }
  let(:calculation_date) { Date.current }

  describe 'validations' do
    it 'requires entity_type' do
      run = build(:grda_warehouse_monitoring_metric_calculation_run, entity_type: nil)
      expect(run).not_to be_valid
    end

    it 'requires calculation_date' do
      run = build(:grda_warehouse_monitoring_metric_calculation_run, calculation_date: nil)
      expect(run).not_to be_valid
    end

    it 'requires started_at' do
      run = build(:grda_warehouse_monitoring_metric_calculation_run, started_at: nil)
      expect(run).not_to be_valid
    end

    it 'only allows valid statuses' do
      run = build(:grda_warehouse_monitoring_metric_calculation_run, status: 'bogus')
      expect(run).not_to be_valid
    end

    it 'accepts running, completed, and failed as valid statuses' do
      ['running', 'completed', 'failed'].each do |status|
        run = build(:grda_warehouse_monitoring_metric_calculation_run, status: status)
        expect(run).to be_valid, "expected status '#{status}' to be valid"
      end
    end
  end

  describe 'uniqueness constraint' do
    it 'prevents two runs for the same entity_type and calculation_date' do
      create(
        :grda_warehouse_monitoring_metric_calculation_run,
        entity_type: entity_type,
        calculation_date: calculation_date,
      )

      duplicate = build(
        :grda_warehouse_monitoring_metric_calculation_run,
        entity_type: entity_type,
        calculation_date: calculation_date,
      )

      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows the same entity_type on different calculation_dates' do
      create(
        :grda_warehouse_monitoring_metric_calculation_run,
        entity_type: entity_type,
        calculation_date: calculation_date,
      )

      different_date = build(
        :grda_warehouse_monitoring_metric_calculation_run,
        entity_type: entity_type,
        calculation_date: calculation_date - 1.day,
      )

      expect { different_date.save! }.not_to raise_error
    end
  end

  describe 'collector lifecycle integration' do
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
    let!(:client) { create(:grda_warehouse_hud_client) }
    let!(:processed) do
      create(
        :grda_warehouse_warehouse_clients_processed,
        client_id: client.id,
        routine: 'service_history',
        days_homeless_last_three_years: 90,
      )
    end

    before do
      allow(GrdaWarehouseBase).to receive(:transaction).and_call_original
      allow(GrdaWarehouseBase).to receive(:transaction).
        with(isolation: :repeatable_read).
        and_yield
    end

    def run_collector
      GrdaWarehouse::Monitoring::Tasks::MetricSnapshotCollector.run_daily_collection(
        entity_type: entity_type,
        calculation_date: calculation_date,
        entity_ids: [client.id],
        metric_names: ['test_metric'],
      )
    end

    it 'transitions from running to completed' do
      run_collector
      run = described_class.last
      expect(run.status).to eq('completed')
      expect(run.completed_at).to be_present
    end

    it 'persists entity and snapshot counts' do
      run_collector
      run = described_class.last
      expect(run.entities_evaluated_count).to eq(1)
      expect(run.snapshots_created_count).to eq(1)
      expect(run.snapshots_updated_count).to eq(0)
      expect(run.calculation_errors_count).to eq(0)
    end

    it 'is idempotent: re-running the same entity_type + date reuses the existing record' do
      run_collector
      expect { run_collector }.
        not_to change(described_class, :count)
    end
  end

  describe 'scopes' do
    before do
      create(
        :grda_warehouse_monitoring_metric_calculation_run,
        entity_type: entity_type,
        calculation_date: 1.day.ago,
        status: 'completed',
      )
      create(
        :grda_warehouse_monitoring_metric_calculation_run,
        entity_type: entity_type,
        calculation_date: 2.days.ago,
        status: 'running',
      )
      create(
        :grda_warehouse_monitoring_metric_calculation_run,
        entity_type: entity_type,
        calculation_date: 3.days.ago,
        status: 'failed',
      )
      create(
        :grda_warehouse_monitoring_metric_calculation_run,
        entity_type: 'GrdaWarehouse::DataSource',
        calculation_date: 4.days.ago,
        status: 'completed',
      )
    end

    it '.for_entity_type filters by entity_type' do
      results = described_class.for_entity_type(entity_type)
      expect(results.map(&:entity_type)).to all(eq(entity_type))
      expect(results.count).to eq(3)
    end

    it '.completed returns only completed runs' do
      expect(described_class.completed.map(&:status)).to all(eq('completed'))
      expect(described_class.completed.count).to eq(2)
    end

    it '.failed returns only failed runs' do
      expect(described_class.failed.map(&:status)).to all(eq('failed'))
      expect(described_class.failed.count).to eq(1)
    end
  end
end

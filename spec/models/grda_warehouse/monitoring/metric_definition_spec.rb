###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::MetricDefinition, type: :model do
  describe 'validations' do
    it 'requires name' do
      metric = build(:grda_warehouse_monitoring_metric_definition, name: nil)
      expect(metric).not_to be_valid
      expect(metric.errors[:name]).to include("can't be blank")
    end

    it 'requires entity_type' do
      metric = build(:grda_warehouse_monitoring_metric_definition, entity_type: nil)
      expect(metric).not_to be_valid
      expect(metric.errors[:entity_type]).to include("can't be blank")
    end

    it 'requires calculator_class' do
      metric = build(:grda_warehouse_monitoring_metric_definition, calculator_class: nil)
      expect(metric).not_to be_valid
      expect(metric.errors[:calculator_class]).to include("can't be blank")
    end

    it 'validates category inclusion' do
      metric = build(
        :grda_warehouse_monitoring_metric_definition,
        category: 'invalid_category',
      )
      expect(metric).not_to be_valid
    end

    it 'enforces uniqueness of name scoped to entity_type' do
      create(
        :grda_warehouse_monitoring_metric_definition,
        name: 'test_metric',
        entity_type: 'GrdaWarehouse::Hud::Client',
      )

      duplicate = build(
        :grda_warehouse_monitoring_metric_definition,
        name: 'test_metric',
        entity_type: 'GrdaWarehouse::Hud::Client',
      )

      expect(duplicate).not_to be_valid
    end
  end

  describe '.maintain!' do
    it 'creates metric definitions from available calculators' do
      expect do
        described_class.maintain!
      end.to change(described_class, :count).by(3)
    end

    it 'is idempotent' do
      described_class.maintain!

      expect do
        described_class.maintain!
      end.not_to change(described_class, :count)
    end

    it 'creates definition with correct attributes' do
      described_class.maintain!

      metric = described_class.find_by(name: 'days_homeless_last_three_years')
      expect(metric).to be_present
      expect(metric.entity_type).to eq('GrdaWarehouse::Hud::Client')
      expect(metric.calculator_class).to eq('GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator')
      expect(metric.active).to be true
    end
  end

  describe '#calculator_for' do
    let(:metric) do
      create(
        :grda_warehouse_monitoring_metric_definition,
        calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator',
      )
    end
    let(:client) { create(:grda_warehouse_hud_client) }
    let(:calculation_date) { Date.current }

    it 'instantiates calculator with entity and date' do
      calculator = metric.calculator_for(client, calculation_date)

      expect(calculator).to be_a(GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator)
      expect(calculator.entity).to eq(client)
      expect(calculator.calculation_date).to eq(calculation_date)
    end
  end

  describe '#calculate_value' do
    let(:metric) do
      create(
        :grda_warehouse_monitoring_metric_definition,
        calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator',
      )
    end
    let(:client) { create(:grda_warehouse_hud_client) }
    let(:calculation_date) { Date.current }

    before do
      create(
        :grda_warehouse_warehouse_clients_processed,
        client_id: client.id,
        routine: 'service_history',
        days_homeless_last_three_years: 123,
      )
    end

    it 'calculates value using calculator' do
      expect(metric.calculate_value(client, calculation_date)).to eq(123)
    end
  end

  describe '.threshold_crossings_for_alerts' do
    let(:calculation_date) { Date.current }
    let(:metric_with_alert) do
      create(
        :grda_warehouse_monitoring_metric_definition,
        name: 'days_homeless_last_three_years',
        display_name: 'Days Homeless (Last 3 Years)',
        calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator',
        active: true,
      )
    end
    let(:metric_without_alert) do
      create(
        :grda_warehouse_monitoring_metric_definition,
        name: 'test_metric_no_alert',
        display_name: 'Test Metric No Alert',
        calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator',
        active: true,
      )
    end
    let(:client1) { create(:grda_warehouse_hud_client) }
    let(:client2) { create(:grda_warehouse_hud_client) }

    it 'returns a hash structure with alert codes as keys' do
      result = described_class.threshold_crossings_for_alerts(calculation_date)
      expect(result).to be_a(Hash)
    end

    it 'only includes metrics with alert codes' do
      # Metric without alert code should be skipped
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_without_alert,
        entity: client1,
        initial_observation_date: calculation_date,
        current_observation_date: calculation_date,
        initial_value: 100,
        current_value: 100,
      )

      result = described_class.threshold_crossings_for_alerts(calculation_date)
      expect(result).to be_empty
    end

    it 'filters snapshots by initial_observation_date matching calculation_date' do
      # Prior snapshot - establishes baseline
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_with_alert,
        entity: client1,
        initial_observation_date: calculation_date - 5.days,
        current_observation_date: calculation_date - 1.day,
        initial_value: 100,
        current_value: 100,
      )

      # Crossing on calculation_date
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_with_alert,
        entity: client1,
        initial_observation_date: calculation_date,
        current_observation_date: calculation_date,
        initial_value: 150,
        current_value: 150,
      )

      # Crossing on different date - should be excluded
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_with_alert,
        entity: client2,
        initial_observation_date: calculation_date + 1.day,
        current_observation_date: calculation_date + 1.day,
        initial_value: 200,
        current_value: 200,
      )

      result = described_class.threshold_crossings_for_alerts(calculation_date)

      expect(result['metric_days_homeless_threshold']).to be_present
      crossings = result['metric_days_homeless_threshold']['Days Homeless (Last 3 Years)'][:data]
      expect(crossings.length).to eq(1)
      expect(crossings.first[:entity_id]).to eq(client1.id)
    end

    it 'excludes first-time observations with no prior snapshots' do
      # First snapshot for this entity - should be excluded as there is no baseline
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_with_alert,
        entity: client1,
        initial_observation_date: calculation_date,
        current_observation_date: calculation_date,
        initial_value: 150,
        current_value: 150,
      )

      result = described_class.threshold_crossings_for_alerts(calculation_date)
      expect(result).to be_empty
    end

    it 'includes previous value from prior snapshot' do
      # Prior snapshot
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_with_alert,
        entity: client1,
        initial_observation_date: calculation_date - 5.days,
        current_observation_date: calculation_date - 1.day,
        initial_value: 100,
        current_value: 120,
      )

      # Current snapshot crossing threshold
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_with_alert,
        entity: client1,
        initial_observation_date: calculation_date,
        current_observation_date: calculation_date,
        initial_value: 160,
        current_value: 160,
      )

      result = described_class.threshold_crossings_for_alerts(calculation_date)
      crossing = result['metric_days_homeless_threshold']['Days Homeless (Last 3 Years)'][:data].first

      expect(crossing[:current_value]).to eq(160)
      expect(crossing[:previous_value]).to eq(120)
    end

    it 'groups crossings by alert code' do
      # Create two metrics sharing the same alert code
      household_min = create(
        :grda_warehouse_monitoring_metric_definition,
        name: 'min_household_size',
        display_name: 'Minimum Household Size',
        calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator',
        active: true,
      )

      household_max = create(
        :grda_warehouse_monitoring_metric_definition,
        name: 'max_household_size',
        display_name: 'Maximum Household Size',
        calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::MaxHouseholdSizeCalculator',
        active: true,
      )

      # Prior snapshots
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: household_min,
        entity: client1,
        initial_observation_date: calculation_date - 5.days,
        current_observation_date: calculation_date - 1.day,
        initial_value: 2,
        current_value: 2,
      )

      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: household_max,
        entity: client1,
        initial_observation_date: calculation_date - 5.days,
        current_observation_date: calculation_date - 1.day,
        initial_value: 4,
        current_value: 4,
      )

      # Current snapshots crossing threshold
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: household_min,
        entity: client1,
        initial_observation_date: calculation_date,
        current_observation_date: calculation_date,
        initial_value: 1,
        current_value: 1,
      )

      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: household_max,
        entity: client1,
        initial_observation_date: calculation_date,
        current_observation_date: calculation_date,
        initial_value: 6,
        current_value: 6,
      )

      result = described_class.threshold_crossings_for_alerts(calculation_date)

      # Both metrics should be under the same alert code
      expect(result['metric_household_size_threshold']).to be_present
      expect(result['metric_household_size_threshold'].keys).to contain_exactly(
        'Minimum Household Size',
        'Maximum Household Size',
      )
    end

    it 'limits results to 50 per metric and marks as truncated' do
      # Create prior snapshot
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_with_alert,
        entity: client1,
        initial_observation_date: calculation_date - 5.days,
        current_observation_date: calculation_date - 1.day,
        initial_value: 100,
        current_value: 100,
      )

      # Create 55 clients with threshold crossings
      clients = create_list(:grda_warehouse_hud_client, 55)
      clients.each do |client|
        # Prior snapshot
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          metric_definition: metric_with_alert,
          entity: client,
          initial_observation_date: calculation_date - 5.days,
          current_observation_date: calculation_date - 1.day,
          initial_value: 100,
          current_value: 100,
        )

        # Crossing snapshot
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          metric_definition: metric_with_alert,
          entity: client,
          initial_observation_date: calculation_date,
          current_observation_date: calculation_date,
          initial_value: 150,
          current_value: 150,
        )
      end

      result = described_class.threshold_crossings_for_alerts(calculation_date)
      metric_data = result['metric_days_homeless_threshold']['Days Homeless (Last 3 Years)']

      expect(metric_data[:total_count]).to eq(55)
      expect(metric_data[:data].length).to eq(50)
      expect(metric_data[:truncated]).to be true
    end

    it 'does not truncate when results are under the limit' do
      # Create prior snapshots for 3 clients
      3.times do
        client = create(:grda_warehouse_hud_client)
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          metric_definition: metric_with_alert,
          entity: client,
          initial_observation_date: calculation_date - 5.days,
          current_observation_date: calculation_date - 1.day,
          initial_value: 100,
          current_value: 100,
        )

        create(
          :grda_warehouse_monitoring_metric_snapshot,
          metric_definition: metric_with_alert,
          entity: client,
          initial_observation_date: calculation_date,
          current_observation_date: calculation_date,
          initial_value: 150,
          current_value: 150,
        )
      end

      result = described_class.threshold_crossings_for_alerts(calculation_date)
      metric_data = result['metric_days_homeless_threshold']['Days Homeless (Last 3 Years)']

      expect(metric_data[:total_count]).to eq(3)
      expect(metric_data[:data].length).to eq(3)
      expect(metric_data[:truncated]).to be false
    end

    it 'only includes active metrics' do
      inactive_metric = create(
        :grda_warehouse_monitoring_metric_definition,
        name: 'inactive_metric',
        display_name: 'Inactive Metric',
        calculator_class: 'GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator',
        active: false,
      )

      # Prior snapshot
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: inactive_metric,
        entity: client1,
        initial_observation_date: calculation_date - 5.days,
        current_observation_date: calculation_date - 1.day,
        initial_value: 100,
        current_value: 100,
      )

      # Crossing snapshot
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: inactive_metric,
        entity: client1,
        initial_observation_date: calculation_date,
        current_observation_date: calculation_date,
        initial_value: 150,
        current_value: 150,
      )

      result = described_class.threshold_crossings_for_alerts(calculation_date)
      expect(result).to be_empty
    end

    it 'handles multiple crossings for the same entity/metric correctly' do
      # First crossing period
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_with_alert,
        entity: client1,
        initial_observation_date: calculation_date - 10.days,
        current_observation_date: calculation_date - 6.days,
        initial_value: 100,
        current_value: 100,
      )

      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_with_alert,
        entity: client1,
        initial_observation_date: calculation_date - 5.days,
        current_observation_date: calculation_date - 1.day,
        initial_value: 150,
        current_value: 150,
      )

      # Another crossing on calculation_date
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        metric_definition: metric_with_alert,
        entity: client1,
        initial_observation_date: calculation_date,
        current_observation_date: calculation_date,
        initial_value: 200,
        current_value: 200,
      )

      result = described_class.threshold_crossings_for_alerts(calculation_date)
      crossings = result['metric_days_homeless_threshold']['Days Homeless (Last 3 Years)'][:data]

      expect(crossings.length).to eq(1)
      expect(crossings.first[:current_value]).to eq(200)
      expect(crossings.first[:previous_value]).to eq(150)
    end
  end
end

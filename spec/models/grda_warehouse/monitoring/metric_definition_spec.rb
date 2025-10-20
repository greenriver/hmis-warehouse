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
end

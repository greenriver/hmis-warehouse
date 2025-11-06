###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::MetricSnapshot, type: :model do
  let(:client) { create(:grda_warehouse_hud_client) }
  let(:metric_definition) { create(:grda_warehouse_monitoring_metric_definition) }

  describe 'validations' do
    it 'requires initial_observation_date' do
      snapshot = build(
        :grda_warehouse_monitoring_metric_snapshot,
        initial_observation_date: nil,
      )
      expect(snapshot).not_to be_valid
    end

    it 'requires current_observation_date' do
      snapshot = build(
        :grda_warehouse_monitoring_metric_snapshot,
        current_observation_date: nil,
      )
      expect(snapshot).not_to be_valid
    end

    it 'requires initial_value' do
      snapshot = build(
        :grda_warehouse_monitoring_metric_snapshot,
        initial_value: nil,
      )
      expect(snapshot).not_to be_valid
    end

    it 'requires current_value' do
      snapshot = build(
        :grda_warehouse_monitoring_metric_snapshot,
        current_value: nil,
      )
      expect(snapshot).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:snapshot1) do
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        entity: client,
        metric_definition: metric_definition,
        initial_observation_date: 10.days.ago,
        current_observation_date: 5.days.ago,
        initial_value: 100,
        current_value: 110,
      )
    end

    let!(:snapshot2) do
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        entity: client,
        metric_definition: metric_definition,
        initial_observation_date: 4.days.ago,
        current_observation_date: Date.current,
        initial_value: 120,
        current_value: 125,
      )
    end

    describe '.for_entity' do
      it 'returns snapshots for specific entity' do
        expect(described_class.for_entity(client)).to contain_exactly(snapshot1, snapshot2)
      end
    end

    describe '.for_metric' do
      it 'returns snapshots for specific metric' do
        expect(described_class.for_metric(metric_definition)).to contain_exactly(snapshot1, snapshot2)
      end
    end

    describe '.active_as_of' do
      it 'returns snapshots active on given date' do
        # snapshot1 ends 5 days ago, snapshot2 is current
        result = described_class.active_as_of(Date.current)
        expect(result).to contain_exactly(snapshot2)
      end

      it 'returns snapshot that spans the date' do
        result = described_class.active_as_of(7.days.ago)
        expect(result).to contain_exactly(snapshot1)
      end
    end

    describe '.current' do
      let!(:stale_snapshot) do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client,
          metric_definition: metric_definition,
          initial_observation_date: 60.days.ago,
          current_observation_date: 40.days.ago,
          initial_value: 50,
          current_value: 60,
        )
      end

      it 'returns snapshots updated within last 30 days' do
        expect(described_class.current).to contain_exactly(snapshot1, snapshot2)
      end
    end

    describe '.stale' do
      let!(:stale_snapshot) do
        create(
          :grda_warehouse_monitoring_metric_snapshot,
          entity: client,
          metric_definition: metric_definition,
          initial_observation_date: 60.days.ago,
          current_observation_date: 40.days.ago,
          initial_value: 50,
          current_value: 60,
        )
      end

      it 'returns snapshots not updated in 30+ days' do
        expect(described_class.stale).to contain_exactly(stale_snapshot)
      end
    end
  end

  describe '#duration_days' do
    let(:snapshot) do
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        initial_observation_date: 10.days.ago,
        current_observation_date: 5.days.ago,
      )
    end

    it 'returns number of days in range' do
      expect(snapshot.duration_days).to eq(5)
    end
  end

  describe '#total_change' do
    let(:snapshot) do
      create(
        :grda_warehouse_monitoring_metric_snapshot,
        initial_value: 100,
        current_value: 150,
      )
    end

    it 'returns difference between current and initial value' do
      expect(snapshot.total_change).to eq(50)
    end

    it 'handles negative change' do
      snapshot.update(current_value: 75)
      expect(snapshot.total_change).to eq(-25)
    end
  end
end

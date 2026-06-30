###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Monitoring::MetricCalculators::BaseCalculator do
  describe '.data_stable?' do
    it 'returns true by default' do
      expect(described_class.data_stable?).to be true
    end
  end

  describe '.change_metrics' do
    let(:snapshot) do
      Struct.new(:initial_value, :current_value, :current_observation_date, keyword_init: true).new(
        initial_value: 100,
        current_value: 130,
        current_observation_date: Date.current - 5,
      )
    end

    it 'measures absolute change from the snapshot initial baseline' do
      result = described_class.change_metrics(
        previous_snapshot: snapshot,
        calculated_value: 150,
        calculation_date: Date.current,
      )

      # 150 - 100 (initial_value); ignores current_value drift and elapsed days
      expect(result[:count_change]).to eq(50)
      expect(result[:reference_value]).to eq(100)
    end
  end
end

RSpec.describe GrdaWarehouse::Monitoring::MetricCalculators::HomelessDaysLastThreeYearsCalculator do
  describe '.data_stable?' do
    it 'returns true when the UpdateWarehouseClientsCachesJob lock is available' do
      allow(GrdaWarehouseBase).to receive(:with_advisory_lock).and_yield
      expect(described_class.data_stable?).to be true
    end

    it 'returns false when the UpdateWarehouseClientsCachesJob lock cannot be acquired' do
      allow(GrdaWarehouseBase).to receive(:with_advisory_lock)
      expect(described_class.data_stable?).to be false
    end
  end
end

RSpec.describe GrdaWarehouse::Monitoring::MetricCalculators::MaxHouseholdSizeCalculator do
  describe '.data_stable?' do
    it 'returns true when no HmisAutoMigrateJob is running' do
      allow(Delayed::Job).to receive(:running?).with('HmisAutoMigrateJob').and_return(false)
      expect(described_class.data_stable?).to be true
    end

    it 'returns false when an HmisAutoMigrateJob is running' do
      allow(Delayed::Job).to receive(:running?).with('HmisAutoMigrateJob').and_return(true)
      expect(described_class.data_stable?).to be false
    end
  end
end

RSpec.describe GrdaWarehouse::Monitoring::MetricCalculators::MinHouseholdSizeCalculator do
  describe '.data_stable?' do
    it 'returns true when no HmisAutoMigrateJob is running' do
      allow(Delayed::Job).to receive(:running?).with('HmisAutoMigrateJob').and_return(false)
      expect(described_class.data_stable?).to be true
    end

    it 'returns false when an HmisAutoMigrateJob is running' do
      allow(Delayed::Job).to receive(:running?).with('HmisAutoMigrateJob').and_return(true)
      expect(described_class.data_stable?).to be false
    end
  end
end

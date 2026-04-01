###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

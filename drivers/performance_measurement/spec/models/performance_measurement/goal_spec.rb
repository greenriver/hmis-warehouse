###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMeasurement::Goal, type: :model do
  let!(:default_goal) { create(:performance_measurement_goal, coc_code: :default, approaching_threshold_percent: 5) }

  describe '#calculated_approaching_threshold_percent' do
    it 'returns own value when set' do
      goal = create(:performance_measurement_goal, coc_code: 'COC-123', approaching_threshold_percent: 8)
      expect(goal.calculated_approaching_threshold_percent).to eq(8)
    end

    it 'falls back to default goal when nil' do
      goal = create(:performance_measurement_goal, coc_code: 'COC-456', approaching_threshold_percent: nil)
      expect(goal.calculated_approaching_threshold_percent).to eq(default_goal.approaching_threshold_percent)
    end
  end

  describe '#approaching_threshold_fraction' do
    it 'returns a fraction between 0.0 and 1.0' do
      goal = create(:performance_measurement_goal, approaching_threshold_percent: 4)
      expect(goal.approaching_threshold_fraction).to eq(0.04)
    end

    it 'returns 0.0 when both own and default percents are nil' do
      default_goal.update!(approaching_threshold_percent: nil)
      goal = create(:performance_measurement_goal, approaching_threshold_percent: nil)
      expect(goal.approaching_threshold_fraction).to eq(0.0)
    end
  end
end

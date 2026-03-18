###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMeasurement::Goal, type: :model do
  let!(:default_goal) { create(:performance_measurement_goal, coc_code: :default, approaching_threshold_percent: 5) }

  describe '#duplicate!' do
    let!(:goal) { create(:performance_measurement_goal, coc_code: 'COC-001', active: true) }

    it 'creates a new active goal' do
      new_goal = goal.duplicate!
      expect(new_goal).to be_persisted
      expect(new_goal.active).to be true
    end

    it 'deactivates the original goal' do
      goal.duplicate!
      expect(goal.reload.active).to be false
    end

    it 'duplicates associated pit counts onto the new goal' do
      create(:performance_measurement_pit_count, goal: goal)
      create(:performance_measurement_pit_count, goal: goal)
      new_goal = goal.duplicate!
      expect(new_goal.pit_counts.count).to eq(2)
      expect(goal.pit_counts.count).to eq(2)
    end

    it 'duplicates associated static spms onto the new goal' do
      create(:performance_measurement_static_spm, goal: goal)
      create(:performance_measurement_static_spm, goal: goal)
      new_goal = goal.duplicate!
      expect(new_goal.static_spms.count).to eq(2)
      expect(goal.static_spms.count).to eq(2)
    end

    it 'does not share pit count records between the original and new goal' do
      create(:performance_measurement_pit_count, goal: goal)
      new_goal = goal.duplicate!
      expect(new_goal.pit_counts.first.id).not_to eq(goal.pit_counts.first.id)
    end

    it 'does not share static spm records between the original and new goal' do
      create(:performance_measurement_static_spm, goal: goal)
      new_goal = goal.duplicate!
      expect(new_goal.static_spms.first.id).not_to eq(goal.static_spms.first.id)
    end
  end

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

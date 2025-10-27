###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMeasurement::ProviderComparison, type: :model do
  let(:user) { create(:user) }
  let(:report) { instance_double(PerformanceMeasurement::Report, detail_goal_direction: goal_direction, goal_config: goal_config) }
  let(:goal_config) { instance_double(PerformanceMeasurement::Goal, approaching_threshold_fraction: threshold_fraction) }
  let(:threshold_fraction) { 0.05 }
  let(:goal_direction) { '> ' }
  let(:primary_value) { 86.0 }

  let(:result) do
    instance_double(
      PerformanceMeasurement::Result,
      passed: passed,
      goal: goal_value,
      primary_value: primary_value,
      primary_unit: '%',
    )
  end

  let(:goal_value) { 90.0 }
  let(:passed) { false }

  subject(:pc) { described_class.new(report, user) }

  describe '#decorator and #decorator_bg_color' do
    context 'for a ">" goal (higher is better)' do
      let(:goal_direction) { '> ' }

      it 'returns warning within threshold, danger outside, success when passed' do
        aggregate_failures do
          # within 5% below 90 -> 85.5 or greater is warning
          expect(pc.send(:decorator, result, :es_average_bed_utilization)).to include('warning')
          expect(pc.send(:decorator_bg_color, result, :es_average_bed_utilization)).to eq(described_class::WARNING_HEX)

          # outside threshold below 90
          allow(result).to receive(:primary_value).and_return(80.0)
          expect(pc.send(:decorator, result, :es_average_bed_utilization)).to include('danger')
          expect(pc.send(:decorator_bg_color, result, :es_average_bed_utilization)).to eq(described_class::DANGER_HEX)

          # passing at or above goal
          allow(result).to receive(:passed).and_return(true)
          expect(pc.send(:decorator, result, :es_average_bed_utilization)).to include('success')
          expect(pc.send(:decorator_bg_color, result, :es_average_bed_utilization)).to eq(described_class::SUCCESS_HEX)
        end
      end
    end

    context 'for a "<" goal (lower is better)' do
      let(:goal_direction) { '< ' }

      it 'returns warning within threshold, danger outside, success when passed' do
        aggregate_failures do
          # within 5% above goal
          allow(result).to receive(:passed).and_return(false)
          allow(result).to receive(:primary_value).and_return(94.0)
          expect(pc.send(:decorator, result, :time_stay)).to include('warning')
          expect(pc.send(:decorator_bg_color, result, :time_stay)).to eq(described_class::WARNING_HEX)

          # outside threshold above goal
          allow(result).to receive(:primary_value).and_return(100.0)
          expect(pc.send(:decorator, result, :time_stay)).to include('danger')
          expect(pc.send(:decorator_bg_color, result, :time_stay)).to eq(described_class::DANGER_HEX)

          # passing at or below goal
          allow(result).to receive(:passed).and_return(true)
          expect(pc.send(:decorator, result, :time_stay)).to include('success')
          expect(pc.send(:decorator_bg_color, result, :time_stay)).to eq(described_class::SUCCESS_HEX)
        end
      end
    end

    it 'does not warn when threshold is zero or nil' do
      allow(goal_config).to receive(:approaching_threshold_fraction).and_return(0.0)
      allow(result).to receive(:passed).and_return(false)
      allow(result).to receive(:primary_value).and_return(89.0)
      expect(pc.send(:decorator, result, :es_average_bed_utilization)).to include('danger')
    end
  end
end

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMeasurement::ProviderComparison, type: :model do
  let(:user) { create(:user) }
  let(:report) do
    instance_double(
      PerformanceMeasurement::Report,
      detail_goal_direction: goal_direction,
      goal_config: goal_config,
      using_static_spm_for_comparison?: using_static_spm,
    )
  end
  let(:using_static_spm) { false }
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
      comparison_primary_value: 6.0,
      secondary_unit: '%',
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

  describe '#display_value' do
    context 'for increased income metrics' do
      context 'when using static SPM for comparison' do
        let(:using_static_spm) { true }

        it 'omits the prior year value' do
          expect(pc.send(:display_value, result, :increased_income_all_clients)).to eq('86.0%')
        end
      end

      context 'when not using static SPM for comparison' do
        let(:using_static_spm) { false }

        it 'appends the prior year value' do
          expect(pc.send(:display_value, result, :increased_income_all_clients)).to eq('86.0% (Prior Year: 6.0%)')
        end
      end
    end

    context 'for non-increased metrics' do
      it 'does not append prior year value' do
        expect(pc.send(:display_value, result, :es_average_bed_utilization)).to eq('86.0%')
      end
    end
  end

  describe '#detail_tooltip' do
    context 'when using static SPM for comparison with increased income metric' do
      let(:using_static_spm) { true }

      it 'returns the static SPM tooltip message' do
        expect(pc.send(:detail_tooltip, :increased_income_all_clients)).to eq('Using a static SPM, no prior year values are available.')
      end
    end

    context 'when not using static SPM for comparison' do
      let(:using_static_spm) { false }

      it 'returns nil for increased income metric' do
        expect(pc.send(:detail_tooltip, :increased_income_all_clients)).to be_nil
      end
    end

    context 'for non-increased metrics' do
      let(:using_static_spm) { true }

      it 'returns nil' do
        expect(pc.send(:detail_tooltip, :es_average_bed_utilization)).to be_nil
      end
    end
  end
end

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

  describe '#table' do
    let(:my_project_id) { 1 }
    let(:other_project_id) { 2 }

    let(:my_hud_project) do
      dbl = instance_double(GrdaWarehouse::Hud::Project, project_type: 1)
      allow(dbl).to receive(:name).and_return('My Project (ES - NBN)')
      dbl
    end

    let(:other_hud_project) do
      dbl = instance_double(GrdaWarehouse::Hud::Project, project_type: 1)
      allow(dbl).to receive(:name).and_return('Other Project (ES - NBN)')
      dbl
    end

    let(:my_project_result) do
      instance_double(
        PerformanceMeasurement::Result,
        hud_project: my_hud_project,
        primary_value: 80.0,
        primary_unit: '%',
        passed: true,
        goal: 75.0,
      )
    end

    let(:other_project_result) do
      instance_double(
        PerformanceMeasurement::Result,
        hud_project: other_hud_project,
        primary_value: 60.0,
        primary_unit: '%',
        passed: true,
        goal: 75.0,
      )
    end

    let(:report) do
      r = instance_double(
        PerformanceMeasurement::Report,
        goal_config: goal_config,
        using_static_spm_for_comparison?: false,
      )
      allow(r).to receive(:detail_goal_direction).and_return('>')
      allow(r).to receive(:detail_title_for).and_return('Title')
      allow(r).to receive(:detail_category_for).and_return('Category')
      allow(r).to receive(:result_for).and_return(nil)
      allow(r).to receive(:my_projects).and_return({ my_project_id => my_project_result })
      allow(r).to receive(:project_details).and_return(
        { my_project_id => my_project_result, other_project_id => other_project_result },
      )
      r
    end

    context 'when active_project_list is :my_projects' do
      subject(:pc) { described_class.new(report, user, active_project_list: :my_projects) }

      it 'only includes my_projects in the table, including for retention_or_positive_destinations' do
        table = pc.table('Emergency Shelters')
        expect(table[:projects].keys).to contain_exactly(my_project_id)
      end
    end

    context 'when active_project_list is :all_projects' do
      subject(:pc) { described_class.new(report, user, active_project_list: :all_projects) }

      it 'includes all projects in the table' do
        table = pc.table('Emergency Shelters')
        expect(table[:projects].keys).to contain_exactly(my_project_id, other_project_id)
      end
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

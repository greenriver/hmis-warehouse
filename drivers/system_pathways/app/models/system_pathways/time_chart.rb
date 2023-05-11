###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memery'

module SystemPathways
  class TimeChart
    include ArelHelper
    include Memery
    include SystemPathways::ChartBase
    include SystemPathways::TimeChart::Ethnicity
    include SystemPathways::TimeChart::Race
    include SystemPathways::TimeChart::Veteran
    include SystemPathways::TimeChart::Chronic
    include SystemPathways::TimeChart::InvolvesCe
    include SystemPathways::TimeChart::DisablingCondition

    def known_categories
      [
        ['Ethnicity', 'ethnicity'],
        ['Race', 'race'],
        ['Veteran Status', 'veteran_status'],
        ['Disabling Condition', 'disabling_condition'],
        ['Household Chronic at Entry', 'chronic_at_entry'],
        ['Participated in CE', 'involves_ce'],
      ]
    end

    def time_groups
      project_type_node_names + ph_projects.values + ['Time to Return']
    end

    def chart_data(chart)
      data = case chart.to_s
      when 'ethnicity'
        ethnicity_chart_data
      when 'race'
        race_chart_data
      when 'veteran_status'
        veteran_chart_data
      when 'disabling_condition'
        disabling_condition_chart_data
      when 'chronic_at_entry'
        chronic_at_entry_chart_data
      when 'involves_ce'
        involves_ce_chart_data
      else
        {}
      end

      data
    end

    private def detail_node_keys
      ethnicity_counts[:project_type_counts].keys + ethnicity_counts[:ph_counts].keys + ['Returned to Homelessness']
    end
  end
end
